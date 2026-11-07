#!/usr/bin/env python3
"""Bundle the pinned Timbre EQ WebExtension for Safari in Apple Music + Timbre.

No separate engine compilation is necessary. A workflow checkout provides the
existing Timbre add-on and shared WebAudio engine; this script adapts its
manifest and places resources in the iOS Safari extension's resource folder.
"""

import argparse
import json
import shutil
from pathlib import Path


FILES = ("boot.js", "bridge.js", "background.js", "engine.js")


def verify(destination: Path) -> None:
    manifest = json.loads((destination / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["manifest_version"] == 3
    assert manifest["background"]["service_worker"] == "background.js"
    assert "browser_specific_settings" not in manifest
    assert manifest["content_scripts"][0]["world"] == "MAIN"
    assert manifest["content_scripts"][1].get("world") != "MAIN"
    for filename in (*FILES, "popup/popup.html", "popup/popup.js", "popup/popup.css",
                     "popup/dsp.js", "icons/icon-48.png", "icons/icon-96.png", "icons/icon-128.png"):
        asset = destination / filename
        assert asset.is_file() and asset.stat().st_size > 0, f"Missing Safari asset: {filename}"


def stage(timbre_root: Path, destination: Path) -> None:
    addon = timbre_root / "addon"
    destination.mkdir(parents=True, exist_ok=True)
    for filename in ("boot.js", "bridge.js", "background.js"):
        shutil.copy2(addon / filename, destination / filename)
    shutil.copy2(timbre_root / "Timbre/Engine/engine.js", destination / "engine.js")
    shutil.copytree(addon / "popup", destination / "popup", dirs_exist_ok=True)
    shutil.copytree(addon / "icons", destination / "icons", dirs_exist_ok=True)

    manifest = json.loads((addon / "manifest.json").read_text(encoding="utf-8"))
    manifest.pop("browser_specific_settings", None)
    manifest["background"] = {"service_worker": "background.js"}
    # Timbre's media hooks must run in the PAGE world, while the extension API
    # bridge continues in an isolated world. Safari 27 supports world: MAIN.
    manifest["content_scripts"][0]["world"] = "MAIN"
    manifest["content_scripts"][1].pop("world", None)
    manifest["description"] = (
        "Timbre EQ and effects for Safari web playback. "
        "Protected media may not expose audio to Web Audio."
    )
    (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    verify(destination)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("destination", type=Path)
    parser.add_argument("--timbre-root", type=Path)
    parser.add_argument("--verify", action="store_true")
    options = parser.parse_args()
    if options.verify:
        verify(options.destination)
    else:
        if not options.timbre_root:
            parser.error("--timbre-root is required when staging")
        stage(options.timbre_root, options.destination)
    print("PASS: bundled Safari extension manifest, EQ engine and popup")
