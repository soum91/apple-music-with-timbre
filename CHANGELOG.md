# Changelog

## [apple-music-timbre-gecko-v0.2.4-b6] - 2026-11-07

## Verified changes since apple-music-timbre-gecko-v0.2.3-b5

- diagnostics: avoid interrupting diagnostic tests with station failure alert ([`25b7ad28`](https://github.com/soum91/apple-music-with-timbre/commit/25b7ad28805d51a07d73d5f7b90e9db9f29f19d4); `AppleMusicGecko/Sources/NativeMusicPlayback.swift`)
- diagnostics: add copy/share/selectable Gecko EME report and timeouts ([`8916902b`](https://github.com/soum91/apple-music-with-timbre/commit/8916902b08e62109e1ce008f2a14247105a1ddd0); `AppleMusicGecko/Resources/drm-diagnostic.html`)
- ui: make diagnostics accessible and exportable directly from Apple Music + Timbre ([`475d3fd2`](https://github.com/soum91/apple-music-with-timbre/commit/475d3fd27230d217067e8200aa7363e806988c2b); `AppleMusicGecko/Sources/TimbreRadioAppView.swift`)
- diagnostics: capture MusicKit catalog failures with actionable domain and code ([`60cbca02`](https://github.com/soum91/apple-music-with-timbre/commit/60cbca02163c5de387496a9a1dcc201f8e97c77c); `AppleMusicGecko/Sources/NativeMusicPlayback.swift`)
- catalog: publish Apple Music + Timbre Gecko 0.2.3 build 5 ([`85ee52e8`](https://github.com/soum91/apple-music-with-timbre/commit/85ee52e839ef318a919520b47e9ed112f6186c4d); `repo.json`, `source.json`)

[Inspect exact code changes](https://github.com/soum91/apple-music-with-timbre/compare/apple-music-timbre-gecko-v0.2.3-b5...apple-music-timbre-gecko-v0.2.4-b6)

## [apple-music-timbre-gecko-v0.2.3-b5] - 2026-11-07

## Verified changes since apple-music-timbre-gecko-v0.2.2-b4

- fix(build): quote MusicKit permission purpose text for XcodeGen ([`3d344146`](https://github.com/soum91/apple-music-with-timbre/commit/3d344146675a805d2041574583ee5b2cb9af27c4); `AppleMusicGecko/project.yml`)
- feat: add native MusicKit playback and embedded Gecko DRM diagnostics ([`9a47da0a`](https://github.com/soum91/apple-music-with-timbre/commit/9a47da0abaea63075b0f81341d7d442df83dc013); `.github/workflows/timbre-radio.yml`, `AppleMusicGecko/README.md`, `AppleMusicGecko/Resources/drm-diagnostic.html`, and 5 more)
- Publish public FlareStore repo for Apple Music + Timbre releases ([`dd36a6b2`](https://github.com/soum91/apple-music-with-timbre/commit/dd36a6b2ba018950a2e18c33e68a7a3db05e68aa); `repo.json`, `source.json`)

[Inspect exact code changes](https://github.com/soum91/apple-music-with-timbre/compare/apple-music-timbre-gecko-v0.2.2-b4...apple-music-timbre-gecko-v0.2.3-b5)

## [apple-music-timbre-gecko-v0.2.2-b4] - 2026-11-07

## Verified changes since apple-music-timbre-gecko-v0.2.1-b3

- Embed Timbre Safari WebExtension in Apple Music + Timbre IPA ([`918791dc`](https://github.com/soum91/apple-music-with-timbre/commit/918791dcc2654ce82bdfa71fa0a9ba1b975de94a); `.github/workflows/timbre-radio.yml`, `AppleMusicGecko/README.md`, `AppleMusicGecko/SafariExtension/SafariWebExtensionHandler.swift`, and 5 more)

[Inspect exact code changes](https://github.com/soum91/apple-music-with-timbre/compare/apple-music-timbre-gecko-v0.2.1-b3...apple-music-timbre-gecko-v0.2.2-b4)

## [apple-music-timbre-gecko-v0.2.1-b3] - 2026-11-07

## Verified changes since apple-music-timbre-gecko-v0.2.0-b2

- Add protected-media diagnostics and correct Apple Music preview findings ([`8d6fb2da`](https://github.com/soum91/apple-music-with-timbre/commit/8d6fb2da83094d70ecac3e463c1c21a156c4208c); `.github/workflows/timbre-radio.yml`, `AppleMusicGecko/README.md`, `AppleMusicGecko/Sources/TimbreRadioAppView.swift`, and 3 more)

[Inspect exact code changes](https://github.com/soum91/apple-music-with-timbre/compare/apple-music-timbre-gecko-v0.2.0-b2...apple-music-timbre-gecko-v0.2.1-b3)

## [apple-music-timbre-gecko-v0.2.0-b2] - 2026-11-07

## Verified changes since timbre-radio-v0.1.0-b1

- Correct Gecko app identity to Apple Music + Timbre with full music navigation ([`37358835`](https://github.com/soum91/apple-music-with-timbre/commit/3735883513441d396daf248aa25815109ae955a8); `.github/workflows/timbre-radio.yml`, `AppleMusicGecko/README.md`, `AppleMusicGecko/Sources/TimbreRadioAppView.swift`, and 6 more)

[Inspect exact code changes](https://github.com/soum91/apple-music-with-timbre/compare/timbre-radio-v0.1.0-b1...apple-music-timbre-gecko-v0.2.0-b2)

## Apple Music + Timbre (Gecko) 0.2.8 build 10 (Gecko view activation experiment, 2026-11-07)

- After attaching `GeckoSession` to the SwiftUI-hosted `GeckoView`, reasserts tab activity and focus on the next main UI cycle. This follows the native Firefox Gecko tab lifecycle more closely and tests whether missing surface activation causes the reported silent Web Audio and WAV playback.
- Added a copyable Gecko rendering-surface status showing UIKit window attachment, first-responder result, session-open state and requested active/focused state. The working independent iOS native sound check is left intact.
- Updated host and nested Safari extension to **0.2.8 (build 10)**, reusing the cached Gecko engine and previously pinned Timbre extension source.

Known limitations: This is an unverified device-level audio activation experiment. The user has confirmed native audio output through iPhone speaker, while Gecko Web Audio and WAV remain silent in build 9. This change does not provide a CDM, decrypt protected streams, or fix the separate MusicKit developer-token requirement.

## Apple Music + Timbre (Gecko) 0.2.7 build 9 (isolated sound output diagnostics, 2026-11-07)

- Added an independent, generated two-second **AVAudioPlayer** tone in Debug Report. It bypasses Gecko, MusicKit, network access, and protected content. A physical-listening confirmation marks it as heard or silent; the outcome is included in the copyable report and is never inferred from `play()` alone.
- Before opening or resuming Gecko, the wrapper now sets and activates an iOS `.playback` audio session, which can prevent mute-switch-related silence and supplies a recorded category, route, and output volume in diagnostics. Device behavior still needs validation.
- Bumped the standalone app and nested Safari extension to **0.2.7 (build 9)**. Cached Gecko engine and pinned Timbre source are unchanged.

Known limitations: This is an audio-routing experiment and a test of unprotected sound, **not** a DRM workaround or proof of Apple Music EQ access. The signed bundle identifier still requires MusicKit App Service registration by the signing developer; the unsigned build cannot provision that registration. Neither native music catalog playback nor Gecko audio output has yet been reverified on a device.

## Apple Music + Timbre (Gecko) 0.2.6 build 8 (native token error and audible Gecko diagnostics, 2026-11-07)

- Prevented automatic native station catalog lookup failures from presenting a blocking MusicKit alert. The native view now keeps its controls available and shows a retryable inline error with the reported MusicKit token case. A catalog request failure is explicitly distinguished from an audio/DRM failure.
- Added the installed app bundle identifier and a sanitized typed MusicKit token-error case to the copyable diagnostic report to help diagnose App ID/MusicKit App Service mismatches after sideload signing.
- Added a packaged **Gecko audible audio output test** with two local generated, unprotected signals: an oscillator via Web Audio and a generated WAV via an HTML audio element. Each test records API results on a copyable local page and requires the user to confirm what they actually hear. The test does not request or decode Apple Music streams.
- Bumped the standalone host and nested Safari extension to **0.2.6 (build 8)**. Reused the existing Gecko binary and Timbre extension sources without rebuilding the Gecko engine.

Known limitations: A signing provider's MusicKit App Service configuration cannot be corrected by this UI change. Catalog requests remain blocked until Apple Music accepts the app's developer/user token. Gecko's apparent playing state can coexist with silence; successful local audio tests would narrow that failure but would not prove DRM is the sole cause. Actual on-device sound output and protected-track EQ remain unverified.

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

