# Apple Music + Timbre, standalone app

First native SwiftUI/MusicKit prototype for iPhone 17 on iOS 27, without jailbreak. Deployment target iOS 18 also permits building with an available stable Xcode SDK. Branding uses the existing Timbre indigo #6366F1 and waveform motif.

## Included

- Apple Music authorization, subscription status, catalog song search and up to 100 library songs.
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
