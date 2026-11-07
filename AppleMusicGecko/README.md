# Timbre Radio (Gecko experiment)

Standalone native-UI iPhone shell that starts the previously compiled Reynard
Gecko runtime and loads Apple's official free Radio page. Its first build is a
**playback experiment**, not proof that the protected Radio stream works.

- Native toolbar: Radio, back/forward, reload and Timbre popup.
- Built-in Timbre WebExtension, using the same verified Gecko engine and the
  packaged extension from the Firefox Gecko 159.0.65 IPA.
- WebKit comparison switch to distinguish Gecko-specific media failures.
- Persistent Gecko profile for Apple Account sign-in cookies.
- Installed version and build shown in About from Info.plist.

Live Apple Music Radio requires a signed-in Apple Account but no subscription.
The live station catalog is DRM-protected. An audio path that does not deliver
decodable samples to Web Audio cannot be equalized by a WebExtension, even if a
native player can reproduce the stream. No DRM bypass is attempted.

Do not remove the original `AppleMusicTimbre/` project: it is a separate native
MusicKit/WebKit fallback. The standalone Gecko app is independently packaged
as `Timbre-Radio-0.1.0-unsigned.ipa`.
