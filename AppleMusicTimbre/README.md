# Apple Music + Timbre, standalone app

Native SwiftUI/MusicKit client for iPhone 17 on iOS 27, without jailbreak. Deployment target iOS 18 also permits building with an available stable Xcode SDK. Branding uses the existing Timbre indigo #6366F1 and waveform motif.

## Version 0.3.0: free radio web test

The first tab loads Apple's official `music.apple.com/ca/radio` in WKWebView, preserving the site's own interface, account flow and playback controls. This route does not call the native MusicKit catalog API. It may require a separate website sign-in; Safari cookies are not assumed to be shared with this app.

Start a free live station, then tap **Test Timbre access**. The probe looks for a currently playing media element in the page, tries standard Web Audio routing, and enables the 10-band web EQ only if nonzero audio samples reach an analyser. A protected, cross-origin or isolated player can remain silent to Web Audio even while it audibly plays. If the probe interrupts playback, tap Reload. The Safari button opens the current page for comparison. Neither a successful compile nor Safari playback proves WKWebView playback or audible EQ on the iPhone 17. No stream extraction or DRM bypass is used.

The native Home/Browse/Radio/Search screens remain as an experimental MusicKit path. The native service requires MusicKit registration for its signed bundle ID; a free Personal Team certificate alone has not provided working catalog access on this device. The imported-file EQ still works through AVAudioEngine independently of web playback.

## Previous native client

Five primary tabs: Home, Browse, Radio, Library, Search. Home requests account recommendations and surfaces catalog charts and stations; Browse presents album, playlist and song charts. Radio loads station search results, prioritizing live stations. Album and playlist pages fetch track relationships and offer play/shuffle. Search includes songs, stations, albums and playlists. Tap the mini player for artwork, queue, previous/next, shuffle and repeat. Timbre import and EQ controls live in Library.

Content is fetched from MusicKit, with visible loading, retry and individual request errors. This does not reproduce Apple's proprietary editorial Home layout. Radio discovery does not guarantee non-subscriber playback: Apple determines availability for the signed client, account and storefront. On-device radio playback and iOS 27 presentation remain unverified. Subscription EQ is still unavailable.

## Included

- Apple Music authorization, subscription status, catalog song and station search, and up to 100 library songs.
- Radio stations are handled separately from subscription-only catalog songs, so users without a subscription can test available radio playback.
- Subscription playback using ApplicationMusicPlayer, with play/pause and visible playback errors.
- Native Files import for unprotected audio, played using AVAudioEngine through a 10-band AVAudioUnitEQ and preamp. Band gains persist between launches.
- Explicit source indicator: MusicKit subscription playback does not pass through the local-file EQ graph.
- Local audio pauses on interruption and headphone disconnection; switching sources pauses the other player.

This is a prototype, not a verified subscription EQ solution. MusicKit provides authorized playback, not a documented PCM processing connection for subscription tracks. Do not claim that moving an EQ slider changes Apple Music subscription playback. No keys, decrypted streams, recordings, or authentication data are collected.

## Signing and first device run

1. Register `com.soum91.applemusictimbre` as an explicit App ID in the signing team's Apple Developer account, and enable its MusicKit app service. Apple documents MusicKit as a runtime service associated with the bundle ID; adding private system entitlements is not needed.
2. Sign the IPA with that team and bundle ID. If a sideloader changes the bundle ID, register and enable MusicKit for the actual signed ID. A certificate by itself does not establish the MusicKit app service.
3. On the iPhone 17, open Listen and tap Connect Apple Music. Grant access, verify the account/subscription indicator, search for a track and play it. An Apple Music subscription and device account are required.
4. Import an ordinary WAV, AIFF, MP3 or unprotected AAC file using Timbre > Import audio. Play it, open the EQ and compare bypass versus a large cut at an audible frequency. Confirm switching back to a catalog song updates the source indicator.

Keep the official Music app installed for this prototype. Physical-device authorization, service registration, protected playback, background behavior and actual audible EQ require on-device verification. No such result is claimed by a successful compiler build.

## Build

On macOS with Xcode and XcodeGen:

```sh
cd AppleMusicTimbre
swift scripts/icon.swift "$PWD"
xcodegen generate
xcodebuild -project AppleMusicTimbre.xcodeproj -scheme AppleMusicTimbre -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

The standalone workflow builds and packages an unsigned IPA. It does not embed a developer private key or any MusicKit token. A FlareStore entry must point to an actually uploaded IPA with its real byte size; private GitHub raw URLs need authentication and are not public sideloader endpoints.

References:
- https://developer.apple.com/musickit/
- https://developer.apple.com/documentation/musickit/integrating-musickit-into-your-app
- https://developer.apple.com/streaming/Whats-new-HLS.pdf
