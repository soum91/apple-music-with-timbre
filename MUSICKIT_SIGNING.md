# Native MusicKit signing requirements

This project distributes an **unsigned test IPA**. Apple Music account authorization and a detected subscription do not imply that MusicKit catalog requests can obtain developer tokens.

## Exact identifier

The Gecko + Safari host uses `com.soum91.applemusictimbre.gecko`. The Safari extension is `com.soum91.applemusictimbre.gecko.safari` and does not perform MusicKit catalog requests.

## Required Apple Developer configuration

1. In the Apple Developer account **used to sign the installed app**, go to Certificates, Identifiers & Profiles > Identifiers.
2. Register or edit an **explicit App ID** named `com.soum91.applemusictimbre.gecko`. Enable **MusicKit** under its App Services tab.
3. Create an appropriate provisioning profile for that App ID and team, then use it to sign and install the unsigned host IPA. Verify that a sideloader has not changed the bundle identifier to another value.
4. On device, open the app's Native MusicKit screen and run the real song/station catalog diagnostics. Record the exact error domain and typed token case without publishing credentials.

An unrelated purchased signing certificate or generic profile does not grant MusicKit to an unregistered App ID. This association is managed in Apple's portal, not by a toggle in the IPA, and the project cannot activate it on the user's behalf. The result may still fail for other causes; `MusicTokenRequestError.unknown` is not a definitive App Service diagnosis.

See Apple's [automatic token generation documentation](https://developer.apple.com/documentation/musickit/using-automatic-token-generation-for-apple-music-api) for the underlying requirement.

## Independent audio checks

Build 0.2.7 adds a native generated tone and an explicit playback-session setup for Gecko. Use the native tone first, then Gecko's Web Audio oscillator and generated WAV. Mark whether the native tone was actually audible. Successful `play()` calls do **not** prove sound reached the speakers; a MusicKit token failure occurs before protected content plays.
