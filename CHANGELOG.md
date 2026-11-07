# Changelog

## Apple Music + Timbre (Gecko) 0.2.5 build 7 (native callback feasibility probe, 2026-11-07)

- Added an observation-only native `AUGraphSetNodeInputCallback`/`AudioUnitSetProperty` callback probe, adapted from the architecture proven in the separate Amazon Music + Timbre project. The code instruments imports in our own application images, excludes the Gecko runtime and Apple's system frameworks, and counts registrations, render calls, non-silent frames, and nonempty buffer pointers. It does not inspect, modify, decrypt, save, or transmit samples.
- Added **Inspect native audio path now** to the Native MusicKit page and the copyable Debug Report. The report distinguishes app-local audio callback observations from actual MusicKit PCM access and includes stream format and observer coverage.
- Armed the probe when selecting Native MusicKit and updated on-screen notices to make the experimental status explicit. Updated the app and Safari extension to **0.2.5 (build 7)**. Vendored the BSD-licensed fishhook support files already used in the Amazon experiment; the Gecko engine cache is unchanged.

Known limitations: Apple Music's `ApplicationMusicPlayer` may render outside app-local callback imports. A zero count is not a proof that no system PCM exists; a nonzero count alone cannot attribute samples to Apple Music or demonstrate EQ. **No native MusicKit DSP or FairPlay bypass is provided**, and neither radio nor full-track playback has been newly verified on a physical device. This experiment may not identify the playback path at all. The unsigned IPA and nested Safari extension still require appropriate signing and MusicKit entitlements.

## Apple Music + Timbre (Gecko) 0.2.4 build 6 (diagnostics, 2026-11-07)

- Added a dedicated in-app Debug report screen, accessible from the top toolbar and About, with **Run diagnostics**, **Copy full debug report**, and the native iOS Share sheet. The report includes the installed package version/build, iOS version, Gecko runtime, native authorization/subscription states, output route, and recent MusicKit outcomes. No Apple ID, authentication token, cookie or HTTP header is exported.
- Added real non-playback MusicKit tests for account authorization, subscription eligibility, the song-catalog API, and the station-catalog API. Request failures now preserve the public NSError domain, code, and underlying error code instead of an unhelpful `Unknown error` message. Failed station requests can be retried.
- Added visible Copy/Share controls, a selectable plain-text report, and 10-second EME key-system timeouts to the existing embedded Gecko DRM diagnostic HTML page.
- Bumped host and embedded Safari WebExtension to **0.2.4 (build 6)**. Cached Gecko binaries and the pinned Timbre DSP engine are unchanged.

Known limitations: Device verification of station discovery, playback and the Gecko test page is still required. A local Gecko file origin can block EME; absent bundled Widevine/FairPlay modules do not by themselves diagnose native MusicKit. The diagnostic does **not** restore protected-track DSP, fix Apple Music's license decisions, or grant signing entitlements. Native MusicKit success and subscription status do not guarantee catalog or radio requests will succeed.

## Apple Music + Timbre (Gecko) 0.2.3 build 5 (experimental, 2026-11-07)

- Added a native `MusicKit` playback engine option alongside the existing Gecko + Timbre and WebKit comparison modes. Users can authorize Apple Music, search songs and radio stations, request playback, and see specific MusicKit errors without touching the Gecko engine.
- Added an embedded `drm-diagnostic.html` browser test that checks Gecko's EME API, Widevine and FairPlay key-system requests, Media Source Extensions and AAC support, with explicit warnings about local-file origin limitations.
- Updated `package_gecko.py` to inventory actual bundled CDM binaries and include a machine-readable DRM report. Settings now shows that inventory instead of sending users to an unexplained external demo.
- Added the required Apple Music access-purpose string, bumped the app and bundled Safari extension to 0.2.3 (5), and arranged for the release workflow to update both FlareStore JSON aliases after publishing a valid IPA.

Known limitations: This is a native playback and diagnostics **test**, not a verified DRM or EQ fix. MusicKit entitlement/signing constraints may prevent account access on a sideloaded IPA. Native MusicKit never exposes protected PCM to Timbre, and Gecko and Safari full-stream EQ is not claimed. The Gecko runtime is reused without recompiling.

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

