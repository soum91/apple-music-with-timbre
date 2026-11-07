# Apple Music + Timbre

## Dedicated Gecko app (0.2.0 preview)

The new `AppleMusicGecko/` target is **Apple Music + Timbre** with native Home, New, Radio, Search and Library shortcuts around a real Gecko web player and integrated Timbre EQ. The full paid Apple Music stream and audible EQ were confirmed in the Firefox Gecko experiment; playback in the standalone app is not yet device-verified. Radio is still under diagnosis. The old `AppleMusicTimbre/` MusicKit/WebKit prototype is preserved separately.

Standalone SwiftUI/MusicKit app targeting iPhone 17 on iOS 27 without jailbreak, with Timbre indigo branding.

Version 0.2.0 includes Home recommendations, Browse charts, Radio station discovery, album and playlist track pages, search across songs/stations/albums/playlists, and an expanded queue player. Library also includes native audio-file import with a real 10-band EQ and preamp.

**Subscription playback uses MusicKit. Custom EQ currently applies only to imported unprotected audio files. Subscription EQ is not established.**

See [standalone app setup and device checklist](AppleMusicTimbre/README.md), including the required MusicKit service registration for the actual signed bundle ID. The standalone Actions workflow packages an unsigned IPA; on-device playback is unverified.

The root-level Theos probe is an earlier diagnostic experiment for iOS 16.1.1. It is not part of the standalone IPA and is not required on iPhone 17.

## First build

Version 0.1.0 (1) compiled successfully on an Intel macOS runner with Xcode 16.4 / iOS 18.5 SDK. It has not been run on the target iPhone 17 / iOS 27. Build: https://github.com/soum91/apple-music-with-timbre/actions/runs/42270010729

The IPA was replaced in place with version 0.2.0, and source.json was updated to version 0.2.0 / build 2. The IPA, icon and feed have anonymous reader access. The raw feed in this private GitHub repo requires authentication. Use the Drive direct download URL from source.json for FlareStore, not the Drive viewer or folder link. Build: https://github.com/soum91/apple-music-with-timbre/actions/runs/42273639678

- IPA: https://drive.google.com/file/d/1qSe6jgKIPPTY3YwfFOAVxtnn0xldPeuB/view
- Feed: https://drive.google.com/file/d/1XObhCrkmmS_mW_NHWu5I9JN2ATcEa6C1/view
- Icon: https://drive.google.com/file/d/1upX32ngoZTVfeNL99OCSoHVJ7f_NVq-Z/view

The feed uses Google Drive download endpoints for these exact IDs. These endpoints need unauthenticated validation after sharing is enabled; a successful upload is not a successful FlareStore installation.
