# Apple Music + Timbre (Gecko app)

Standalone iPhone app that starts the previously compiled Reynard Gecko runtime
and loads Apple Music with native navigation. The user has confirmed full paid
subscription playback with audible Timbre EQ in the Firefox Gecko experiment;
that successful path is the foundation for this dedicated app.

- Native Home, New, Radio, Search and Library shortcuts, browser navigation,
  and Timbre EQ popup. Music content itself still renders in Gecko; these
  shortcuts are not a claim of a fully native music catalog UI yet.
- Built-in Timbre WebExtension, using the same verified Gecko engine and the
  packaged extension from the Firefox Gecko 159.0.65 IPA.
- WebKit comparison switch to distinguish Gecko-specific media failures. Timbre
  does not apply in WebKit mode.
- Persistent Gecko profile for Apple Account sign-in cookies.
- Installed version and build shown in About from Info.plist.

Live Apple Music Radio requires a signed-in Apple Account but no subscription.
The user reports that live Radio does not play in Firefox Gecko even though
paid subscription songs do play with audible Timbre EQ. Radio's protected live
delivery therefore needs separate diagnosis. No DRM bypass is attempted.

Do not remove the original `AppleMusicTimbre/` project: it is a separate native
MusicKit/WebKit prototype. The dedicated Gecko app uses a separate test bundle
ID while its playback and native navigation are verified. The IPA is packaged
as `Apple-Music-Timbre-Gecko-0.2.0-unsigned.ipa`.
