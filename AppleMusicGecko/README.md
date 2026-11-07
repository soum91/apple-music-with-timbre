# Apple Music + Timbre (Gecko app)

Standalone iPhone app that starts the previously compiled Reynard Gecko runtime
and loads Apple Music with native navigation. The Firefox Gecko experiment
confirmed that Timbre EQ changes audible Apple Music preview playback, but paid
subscription tracks still end after approximately 90 seconds in Gecko even
though the same subscription plays full tracks in Safari.

- Native Home, New, Radio, Search and Library shortcuts, browser navigation,
  and Timbre EQ popup. Music content itself still renders in Gecko; these
  shortcuts are not a claim of a fully native music catalog UI yet.
- Built-in Timbre WebExtension, using the same verified Gecko engine and the
  packaged extension from the Firefox Gecko 159.0.65 IPA.
- Engine selector: Gecko + Timbre, Apple Music's native `ApplicationMusicPlayer`,
  or a WebKit comparison. The native mode can ask for Apple Music permission,
  query a subscription, search for songs and stations and report playback
  errors. Neither WebKit nor native MusicKit gives Timbre decoded protected PCM.
- An actual Safari WebExtension included in the same app IPA. Safari users can
  enable Timbre EQ from Safari > Extensions after signing/installing the app.
  It reuses the pinned Timbre EQ add-on scripts, popup, and DSP engine but has
  its own Safari extension storage and site permission grants.
- Persistent Gecko profile for Apple Account sign-in cookies.
- Embedded Gecko HTML diagnostics for EME, DRM key-system negotiation and codec
  support, plus a native inventory of shipped CDM binaries. The embedded test
  uses a local-file origin, which can itself restrict EME and is not definitive
  for Apple Music's HTTPS origin. The Shaka test remains an optional comparison.
- Installed version and build shown in About from Info.plist.

Live Apple Music Radio requires a signed-in Apple Account but no subscription.
The user reports that live Radio does not play in Firefox Gecko. Playback and
DRM support for full subscription songs and live Radio need separate diagnosis.
No DRM bypass is attempted.

Do not remove the original `AppleMusicTimbre/` project: it is a separate native
MusicKit/WebKit prototype. The dedicated Gecko app uses a separate test bundle
ID while its playback and native navigation are verified. The IPA is packaged
as `Apple-Music-Timbre-Gecko-0.2.3-unsigned.ipa`.

## Safari EQ test

The host app installs TimbreSafariExtension.appex as a nested app extension.
The signed host IPA and nested extension must both retain valid signatures.
In Safari, open the Extensions menu, enable **Timbre EQ for Safari** and grant
access to music.apple.com. Its popup contains the familiar parametric EQ and
effects. Existing Gecko settings are not silently shared with Safari.

The Safari engine can play Apple Music's full subscription streams, but that
does not imply the JavaScript Web Audio API may read FairPlay-protected samples.
If the extension reports DRM, silent processing, or no intercepted audio, do
not claim it can alter protected Apple Music sound. Normal unprotected browser
audio remains a separate supported experiment.
