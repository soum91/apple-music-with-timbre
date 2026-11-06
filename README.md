# Apple Music + Timbre

Standalone SwiftUI/MusicKit app targeting iPhone 17 on iOS 27 without jailbreak, with Timbre indigo branding.

The first prototype includes Apple Music account authorization, library songs, catalog search and playback, plus native audio-file import with a real 10-band EQ and preamp.

**Subscription playback uses MusicKit. Custom EQ currently applies only to imported unprotected audio files. Subscription EQ is not established.**

See [standalone app setup and device checklist](AppleMusicTimbre/README.md), including the required MusicKit service registration for the actual signed bundle ID. The standalone Actions workflow packages an unsigned IPA; on-device playback is unverified.

The root-level Theos probe is an earlier diagnostic experiment for iOS 16.1.1. It is not part of the standalone IPA and is not required on iPhone 17.
