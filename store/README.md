# Google Play release kit

Everything the Play Console asks for, ready to copy. Nothing here is built into the app.

```
store/
  listing/en-US, it-IT   title, short and full description, release notes
  graphics/icon-512.png  app icon (512 × 512)
  graphics/<locale>/feature-graphic-1024x500.png
  graphics/phone/<locale>/*.png   phone screenshots (1156 × 2312)
```

Default language of the listing: English (United States), with Italian (Italy) as a translation.

## Build the bundle

```bash
flutter build appbundle --release
```

The file is `build/app/outputs/bundle/release/app-release.aab`. It is signed with the **upload key** read from `android/key.properties` (git-ignored; see `android/app/build.gradle.kts`). Without that file the build falls back to the debug key, which Google Play rejects.

**Keep the keystore and its passwords safe and backed up outside the repository** (they were created in `C:\Users\ribal\LowEnd-keys`). Enrol in *Play App Signing* when you create the app: Google keeps the real app-signing key, and the upload key can be replaced through Play support if it is ever lost.

Raise `version:` in `pubspec.yaml` (the number after `+` must grow with every upload) before each new bundle.

## Store listing

| Field | Value |
| --- | --- |
| App name | Low End: Bass Tuner & Drone (it: Low End: accordatore e drone) |
| Category | Music & Audio |
| Free or paid | Free |
| Contains ads | No |
| Contact email | ribaluigi@gmail.com |
| Website | https://github.com/luigir86/Low-End |
| Privacy policy | https://github.com/luigir86/Low-End/blob/main/PRIVACY.md |

## App content (declarations)

- **Data safety**: the app collects **no data** and shares none. The microphone is processed on the phone and never stored or sent; the app has no network access (no `INTERNET` permission). Answer "No" to "Does your app collect or share any of the required user data types?". Data is not encrypted in transit because nothing is in transit.
- **Permissions to explain**: `RECORD_AUDIO` (tuner), `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (metronome and drone keep playing with the screen off, with a notification), `POST_NOTIFICATIONS` (that notification), `WAKE_LOCK` (keeps playback running; keeps the screen on if the player asks).
- **Foreground service declaration**: type *Media playback*. Short video to attach: start the metronome, lock the screen, show the notification.
- **Content rating** (IARC questionnaire): no violence, no sexual content, no gambling, no user-generated content, no sharing of location. Expected result: PEGI 3 / Everyone.
- **Target audience**: 13 and over is the simplest choice (no ads, no data, but it is not aimed at children). Choosing "under 13" would add the Families policy requirements.
- **Ads**: none. **News app**: no. **Government app**: no. **Financial features**: none. **Health features**: none.
- **Open source**: MIT, source at https://github.com/luigir86/Low-End (it is in the description). Third-party licences: [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

## Before going to production

New personal developer accounts must run a **closed test with at least 12 testers opted in for 14 days in a row** before they can apply for production access. Upload the bundle to the closed-testing track first, invite the testers by email or a Google Group, and apply for production when the 14 days are done.

## Checks made

- Licences of all dependencies: permissive (MIT, BSD, Apache-2.0, zlib, public domain); see THIRD_PARTY_NOTICES.md.
- Known vulnerabilities (OSV database): none in the 108 Dart packages or the 88 external Android libraries.
- Manifest: no `INTERNET`, backup off, only the launcher activity, the `lowend://` action link, the media service and its button receiver are exported.
- The `lowend://action/...` links can start the sound or bring up the tuner from any web page or app. They do only what the buttons do, the microphone needs the permission the player gave and a visible tuner screen, and nothing leaves the phone, so this is documented rather than blocked (docs/llm.md).
