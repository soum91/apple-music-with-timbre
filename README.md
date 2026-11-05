# Apple Music with Timbre

An isolated, jailbreak-only feasibility experiment for applying Timbre to Apple Music on the user's own device.

## Current phase

**Phase 0: playback-path observation.** The probe records only whether it is running inside Apple Music and the active audio-session category, mode, sample rate, buffer duration, and output port types. It does not capture audio samples, track titles, account data, FairPlay keys, or network traffic.

This first probe is not an equalizer and does not claim that Apple Music's decoded PCM is exposed to an app-local callback. It gives us a safe baseline before deciding whether a non-invasive DSP hook is technically possible.

## Boundaries

- Apple Music remains responsible for sign-in, licensing, FairPlay key handling, decoding, and playback.
- No key extraction, content decryption, audio recording/export, entitlement changes, authentication changes, or DRM bypass.
- No change to the working Amazon Music with Timbre project.
- Diagnostics are limited to audio-session state and output route; do not add song or user identifiers.

If the supported path does not expose decoded PCM for processing without interfering with FairPlay or playback, stop at diagnostics and report that constraint.

## Target

Initial device target: jailbroken iPhone 13 Pro Max on iOS 16.1.1 (Dopamine rootless). The package filter restricts injection to com.apple.Music.

## Build

Build with Theos on macOS/Linux:

    make package

Install the resulting rootless package on the test device, launch Apple Music, play a track, and inspect device logs for the AppleMusicTimbreProbe prefix. Compare with Timbre disabled/enabled only after an actual supported PCM callback has been established.

## Files

- Tweak.xm: session and route observation only.
- Makefile: rootless Theos package definition.
- control: package metadata.
- filter.plist: Apple Music process filter.
