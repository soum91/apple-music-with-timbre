## Timbre Radio 0.1.0 (experimental, 2026-11-07)

- Added `AppleMusicGecko/`, a standalone iOS target with native radio controls and a real GeckoView surface rather than the complete Firefox UI.
- Bootstrapped Gecko directly with persistent profile storage for website sign-in.
- Added startup registration of the existing bundled Timbre extension and its in-app popup.
- Added a WebKit radio comparison mode, with an explicit notice that Timbre is not attached there.
- Added a release workflow that reuses Firefox Gecko 159.0 build 65 and refuses an expensive engine recompile if cache artifacts are missing.
- Added the actual installed version/build label to About and registered the new target with the installed-version contract.

Known limitations: free Apple Music Radio and protected-stream DSP remain unverified on a device. Successful compilation does not prove either capability. The first IPA must be signed before installation.

## Apple Music + Timbre (Gecko) 0.2.0 (experimental, 2026-11-07)

- Corrected the standalone app identity and on-screen title to Apple Music + Timbre. The first build was misnamed Timbre Radio and focused too narrowly on Radio.
- Changed the Gecko startup route to Apple Music Home and added native Home, New, Radio, Search and Library navigation while keeping Timbre accessible.
- Reused the existing indigo Timbre app icon generator and gave the dedicated Gecko app its own test bundle identifier.
- Updated the packaging script, version number and release workflow for the renamed IPA.

Known limitations: the native controls still wrap Apple's website, and the dedicated app has not been tested on-device. Later side-by-side testing established that the original Firefox Gecko build is served ~90-second Apple Music previews despite an active subscription, while Safari plays the same songs in full. Timbre's audible effect is confirmed on those previews only. Full protected playback and live Radio still fail in Gecko.

## Apple Music + Timbre (Gecko) 0.2.1 (diagnostic, 2026-11-07)

- Corrected the on-device Playback and Timbre status text after side-by-side Firefox Gecko and Safari testing. Paid Apple Music tracks are still served as previews in Gecko; prior claims of full protected playback were incorrect.
- Added a button in About > Protected-media check to open the Shaka Player browser support test within the actual Gecko session, making DRM capability inspection possible without rebuilding Gecko.
- Clarified that WebKit comparison may play the full subscription stream but does not attach Timbre DSP.
- Updated app and helper versions to 0.2.1 (build 3); the cached Gecko engine is unchanged.

Known limitations: neither the preview issue nor Radio playback is fixed by this diagnostic release. Missing DRM support is a working hypothesis until the on-device browser support result is captured.

## Apple Music + Timbre (Gecko) 0.2.2 (Safari extension experiment, 2026-11-07)

- Added an iOS Safari WebExtension target to the existing Apple Music + Timbre host IPA, using its own native Safari extension handler.
- Reused pinned soum91/timbre EQ sources in the build: page-world WebAudio DSP engine, isolated settings bridge, popup controls, presets, effects, and icons. The packaging script converts Firefox manifest metadata and background scripts to Safari-compatible manifest v3.
- Added Safari installation and permission instructions in the app's About screen.
- Updated the packaging and CI checks to require the Safari app extension, validate its contents, and sign the nested Safari extension along with the Gecko app.
- Incremented app and embedded helper/extension metadata to version 0.2.2, build 4. The compiled Gecko engine remains unchanged.

Known limitations: the new Safari extension is pending device validation. Safari's full Apple Music playback does not establish that protected FairPlay audio is available to the EQ. Gecko still receives previews and live Radio remains unresolved.
