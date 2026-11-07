#!/usr/bin/env python3
"""Repackage the known-working Firefox Gecko engine into Apple Music + Timbre.

The Firefox UI is *not* copied. Only Gecko runtime frameworks, the content
process helper, and its bundled Timbre extension are reused. No Gecko compile.
"""
import argparse
import json
import plistlib
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path


def run(*args):
    subprocess.run(list(map(str, args)), check=True)


def plist_update(path, **values):
    data = plistlib.loads(path.read_bytes())
    data.update(values)
    path.write_bytes(plistlib.dumps(data))


def macho(path):
    if not path.is_file() or path.is_symlink():
        return False
    with path.open('rb') as stream:
        return stream.read(4) in (bytes.fromhex('cffaedfe'), bytes.fromhex('cafebabe'))


def package(ipa, app, output):
    with tempfile.TemporaryDirectory(prefix='timbre-radio-') as tmp:
        temp = Path(tmp)
        with zipfile.ZipFile(ipa) as z:
            needed = [n for n in z.namelist() if n.startswith('Payload/Firefox.app/Frameworks/')
                      or n.startswith('Payload/Firefox.app/PlugIns/Reynard Helper.appex/')]
            if not needed:
                raise ValueError('Firefox IPA has no Gecko frameworks or helper')
            for entry in needed:
                if entry.endswith('/'):
                    continue
                target = temp / entry
                target.parent.mkdir(parents=True, exist_ok=True)
                with z.open(entry) as source, target.open('wb') as destination:
                    shutil.copyfileobj(source, destination)

        payload = temp / 'TimbrePayload' / 'Payload'
        dest = payload / 'AppleMusicGecko.app'
        shutil.copytree(app, dest)
        app_info = plistlib.loads((dest / 'Info.plist').read_bytes())
        app_version = str(app_info['CFBundleShortVersionString'])
        app_build = str(app_info['CFBundleVersion'])
        gecko = temp / 'Payload/Firefox.app'
        shutil.copytree(gecko / 'Frameworks', dest / 'Frameworks', dirs_exist_ok=True)
        helper = dest / 'PlugIns/Reynard Helper.appex'
        helper.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(gecko / 'PlugIns/Reynard Helper.appex', helper)
        plist_update(helper / 'Info.plist',
                     CFBundleIdentifier='com.soum91.applemusictimbre.gecko.Helper',
                     CFBundleShortVersionString=app_version, CFBundleVersion=app_build)
        if not (dest / 'drm-diagnostic.html').is_file():
            raise FileNotFoundError('Native build did not embed drm-diagnostic.html')

        # Inspect the binaries actually shipped. Widevine configuration JSON
        # files alone are not a Content Decryption Module.
        module_names = {'libwidevinecdm.so', 'widevinecdm.dll', 'libwidevinecdm.dylib',
                        'widevinecdm.dylib', 'libfairplaycdm.dylib'}
        modules = {p.name.lower() for p in dest.rglob('*') if p.is_file()
                   and p.name.lower() in module_names}
        (dest / 'drm-capabilities.json').write_text(json.dumps({
            'containsWidevineCDM': bool(modules & (module_names - {'libfairplaycdm.dylib'})),
            'containsFairPlayCDM': 'libfairplaycdm.dylib' in modules,
            'detectedModules': sorted(modules),
            'scope': 'Packaged module inventory, not browser EME support'
        }, indent=2) + '\n')
        safari = dest / 'PlugIns/TimbreSafariExtension.appex'
        safari_manifest = next((path for path in (
            safari / 'manifest.json', safari / 'Resources/manifest.json') if path.is_file()), None)
        if safari_manifest is None:
            raise FileNotFoundError('Safari WebExtension manifest missing from embedded .appex')

        # Verify runtime essentials before signing. This is the same Gecko
        # engine that already runs Timbre in the Firefox native build.
        required = [
            dest / 'Frameworks/GeckoView.framework/GeckoView',
            dest / 'Frameworks/XUL.dylib',
            dest / 'Frameworks/GeckoView.framework/Frameworks/extensions/timbre/manifest.json',
            dest / 'PlugIns/Reynard Helper.appex/Info.plist',
            safari / 'Info.plist',
        ]
        for path in required:
            if not path.is_file():
                raise FileNotFoundError(path)

        addon = json.loads(required[2].read_text())
        if addon.get('browser_specific_settings', {}).get('gecko', {}).get('id') != 'timbre@soum91':
            raise ValueError('Wrong Timbre add-on package')
        safari_addon = json.loads(safari_manifest.read_text())
        if safari_addon.get('background', {}).get('service_worker') != 'background.js':
            raise ValueError('Safari WebExtension background worker is absent')

        for binary in sorted(dest.rglob('*')):
            if macho(binary):
                run('codesign', '--force', '--sign', '-', '--timestamp=none', binary)
        for framework in sorted((dest / 'Frameworks').glob('*.framework')):
            run('codesign', '--force', '--sign', '-', '--timestamp=none', framework)
        run('codesign', '--force', '--sign', '-', '--timestamp=none', safari)
        run('codesign', '--force', '--sign', '-', '--timestamp=none', helper)
        run('codesign', '--force', '--sign', '-', '--timestamp=none', dest)
        for path in [dest / 'AppleMusicGecko', required[0], required[1]]:
            run('codesign', '--verify', '--strict', path)
        run('codesign', '--verify', '--strict', safari)

        output.parent.mkdir(parents=True, exist_ok=True)
        run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', payload, output)

    with zipfile.ZipFile(output) as z:
        if z.testzip() is not None:
            raise ValueError('IPA archive is damaged')
        if 'Payload/AppleMusicGecko.app/Info.plist' not in z.namelist():
            raise ValueError('Missing app Info.plist')
        if 'Payload/AppleMusicGecko.app/PlugIns/TimbreSafariExtension.appex/Info.plist' not in z.namelist():
            raise ValueError('Missing embedded Timbre Safari extension')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--firefox-ipa', type=Path, required=True)
    parser.add_argument('--app', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    opts = parser.parse_args()
    package(opts.firefox_ipa, opts.app, opts.output)
