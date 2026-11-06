# Apple Music with Timbre

A jailbreak-only feasibility experiment for applying Timbre to Apple Music on the user's device.

## Current phase

**Phase 0: playback-path observation.** The probe records Apple Music's audio-session category, mode, sample rate, buffer duration, and output port types when the app activates or changes audio-session state. It does not capture audio samples, track titles, account data, FairPlay keys, or network traffic.

The supplied Music.ipa identifies the target as com.apple.Music, version 3.1, build 4020.200.20. The rootless probe is filtered to that bundle ID and targets the installed Music app on iOS 16.1.1.

This probe is not an equalizer and does not claim that Apple Music's decoded PCM is exposed to an app-local callback. It establishes the audio-session baseline before deciding whether a supported DSP path is available.

## Boundaries

- Apple Music remains responsible for sign-in, licensing, FairPlay key handling, decoding, and playback.
- No key extraction, content decryption, audio recording/export, entitlement changes, authentication changes, or DRM bypass.
- Diagnostics are limited to audio-session state and output route; do not add song or user identifiers.

If the supported playback path does not expose decoded PCM for processing without interfering with FairPlay or playback, stop at diagnostics and report that constraint.

## Build and device check

A GitHub Actions workflow builds a rootless Debian package on pushes to main and manual runs. Download the artifact from the workflow run and install it on the test device. Open Apple Music, play a track, and collect only matching probe messages over SSH:

    log show --last 5m --style compact --predicate 'process == "Music" AND eventMessage CONTAINS "AppleMusicTimbreProbe"'

Share only those lines. They contain session format and output port type, not track or account information. Do not share a full device log.

Audio-session activation is not proof of PCM callback access. A later stage must separately establish a supported callback before EQ work begins.

## Files

- Tweak.xm: public audio-session activation, app-active, route, and interruption diagnostics only.
- Makefile and AppleMusicTimbreProbe.plist: rootless Theos build and Music-only process filter.
- control: package metadata.
- .github/workflows/build.yml: package build artifact.
