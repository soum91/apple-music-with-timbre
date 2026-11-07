# Changelog

## Timbre Radio 0.1.0 (experimental, 2026-11-07)

- Added `AppleMusicGecko/`, a standalone iOS target with native radio controls and a real GeckoView surface rather than the complete Firefox UI.
- Bootstrapped Gecko directly with persistent profile storage for website sign-in.
- Added startup registration of the existing bundled Timbre extension and its in-app popup.
- Added a WebKit radio comparison mode, with an explicit notice that Timbre is not attached there.
- Added a release workflow that reuses Firefox Gecko 159.0 build 65 and refuses an expensive engine recompile if cache artifacts are missing.
- Added the actual installed version/build label to About and registered the new target with the installed-version contract.

Known limitations: free Apple Music Radio and protected-stream DSP remain unverified on a device. Successful compilation does not prove either capability. The first IPA must be signed before installation.

This log records verified, release-specific changes. The [Factual release changelog](.github/workflows/release-changelog.yml) GitHub Action adds entries based on the actual commits between published releases. Entries are not fabricated for older versions that have not been audited.

