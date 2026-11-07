# Changelog

## Apple Music + Timbre (Gecko) 0.2.0 (experimental, 2026-11-07)

- Corrected the standalone app identity and on-screen title to Apple Music + Timbre. The first build was misnamed Timbre Radio and focused too narrowly on Radio.
- Changed the Gecko startup route to Apple Music Home and added native Home, New, Radio, Search and Library navigation while keeping Timbre accessible.
- Reused the existing indigo Timbre app icon generator and gave the dedicated Gecko app its own test bundle identifier.
- Updated the packaging script, version number and release workflow for the renamed IPA.

Known limitations: the native controls still wrap Apple's website, and the dedicated app has not been tested on-device. The user has independently confirmed audible Timbre EQ on full paid subscription tracks in the original Firefox Gecko build; live Radio still fails there. The standalone app's protected-media behavior cannot be assumed from compilation alone.

## Timbre Radio 0.1.0 (experimental, 2026-11-07)

- Added `AppleMusicGecko/`, a standalone iOS target with native radio controls and a real GeckoView surface rather than the complete Firefox UI.
- Bootstrapped Gecko directly with persistent profile storage for website sign-in.
- Added startup registration of the existing bundled Timbre extension and its in-app popup.
- Added a WebKit radio comparison mode, with an explicit notice that Timbre is not attached there.
- Added a release workflow that reuses Firefox Gecko 159.0 build 65 and refuses an expensive engine recompile if cache artifacts are missing.
- Added the actual installed version/build label to About and registered the new target with the installed-version contract.

Known limitations: free Apple Music Radio and protected-stream DSP remain unverified on a device. Successful compilation does not prove either capability. The first IPA must be signed before installation.

This log records verified, release-specific changes. The [Factual release changelog](.github/workflows/release-changelog.yml) GitHub Action adds entries based on the actual commits between published releases. Entries are not fabricated for older versions that have not been audited.

