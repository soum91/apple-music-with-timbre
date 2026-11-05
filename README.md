# Apple Music with Timbre

An isolated, jailbreak-only feasibility experiment for applying Timbre to Apple Music on the user's own device.

## Current phase

**Phase 0: playback-path observation.** The probe records only whether it is running inside Apple Music and the active audio-session category, mode, sample rate, buffer duration, and output port types. It does not capture audio samples, track titles, account data, FairPlay keys, or network traffic.

This first probe is not an equalizer and does not claim that Apple Music's decoded PCM is exposed to an app-local callback. It establishes the session baseline before deciding whether a non-invasive DSP hook is technically possible.

## Boundaries

- Apple Music remains responsible for sign-in, licensing, FairPlay key handling, decoding, and playback.
- No key extraction, content decryption, audio recording/export, entitlement changes, authentication changes, or DRM bypass.
- No change to the working Amazon Music with Timbre project.
- Diagnostics are limited to audio-session state and output route; do not add song or user identifiers.

If the supported playback path does not expose decoded PCM for processing without interfering with FairPlay or playback, stop at diagnostics and report that constraint.

## Target

Initial device target: jailbroken iPhone 13 Pro Max on iOS 16.1.1 (Dopamine rootless). The package filter restricts injection to com.apple.Music.

## Build

A GitHub Actions workflow builds a rootless Debian package on pushes to main and manual runs. Download the artifact from the workflow run, install it on the test device, launch Apple Music, and play one track.

Collect only matching probe messages over SSH from the device:

    log show --last 5m --style compact --predicate 'process == "Music" AND eventMessage CONTAINS "AppleMusicTimbreProbe"'

Share those lines here. They contain the session format and output port type, not track or account information. Do not share a full device log.

The probe reports the app's AVAudioSession configuration. That is not proof of PCM callback access. A later stage must separately establish a supported callback without reading, exporting, or decrypting protected media before any EQ work begins.

## Files

- Tweak.xm: session and route observation only.
- Makefile and AppleMusicTimbreProbe.plist: rootless Theos build and Apple Music-only process filter.
- control: package metadata.
- .github/workflows/build.yml: package build artifact.
