# UDPCore Google Play Release Handoff

Use this document as the prompt for a fresh release session.

## Instructions for the assistant

Help me finish releasing UDPCore to Google Play. Treat the status below as a handoff, not as unquestionable truth.

1. Inspect the repository and current Git diff before changing anything. Preserve unrelated work.
2. Verify all reported local changes and run the relevant checks and release builds.
3. Recheck current Google Play requirements against official documentation, especially target API level and personal-account closed-testing rules.
4. Handle all safe local work autonomously. Clearly separate actions you can perform from actions that require my Google account, passwords, device, or approval.
5. Never delete the existing Play Console app or expose/commit signing secrets.
6. Keep the release checklist updated and tell me exactly what remains blocked on me.

## Release target

| Field | Value |
|---|---|
| App | UDPCore |
| Package | `com.mehdibahlaoui.udpcore` |
| Version | `1.1.0+5` |
| Repository app directory | `UDPCore/` |
| Existing Play Console app | Reuse it; do not create or delete an app |
| Original handoff date | 24 August 2026 |

If Play Console reports that version code `5` was already used, increment the build number in `UDPCore/pubspec.yaml` and rebuild.

## Critical constraints

### Preserve the Play Console app

Do not delete the existing app. It has likely had lifetime installs, so deleting it may permanently prevent reuse of `com.mehdibahlaoui.udpcore`. Existing listings, releases, tracks, testers, screenshots, and declarations can be updated in place.

### Preserve the upload key

The expected upload keystore is:

```text
/home/mehdi/Documents/upload-keystore.jks
```

Release uploads must use the upload key already registered with Play App Signing. A different key will be rejected. If the password cannot be recovered, request an upload-key reset through Play Console support.

`UDPCore/android/key.properties` is gitignored and should contain:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_ALIAS
storeFile=/home/mehdi/Documents/upload-keystore.jks
```

Discover the alias with:

```bash
keytool -list -v -keystore /home/mehdi/Documents/upload-keystore.jks
```

Back up the keystore and credentials securely. Never print the passwords or commit `key.properties`.

## Reported repository state to verify

The previous release pass reported these changes as complete:

- Release builds use the upload signing configuration instead of the debug key.
- The transport selector (Wi-Fi/Bluetooth) and control-surface selector (arrows/sliders) are independent and persisted separately.
- Sliders and hold buttons send through the selected transport, including UDP/Wi-Fi.
- Connected and error status labels are legible.
- The About screen describes Wi-Fi, Bluetooth, arrows, and sliders and includes the Roboticore Club of ENSAM Rabat dedication.
- Android tooling was upgraded to Gradle 8.14.3, Android Gradle Plugin 8.11.1, Kotlin 2.2.20, and JDK 21.
- Android `targetSdk` is 36.
- The Bluetooth plugin compatibility patches cover its namespace, compile SDK, and leaked location permissions.
- The merged manifest does not advertise unrestricted fine or coarse location access on modern Android versions.
- The release native libraries are stripped and compatible with 16 KB memory pages.
- The minimum supported Android version is now Android 7.0 because of the Flutter version in use.
- Privacy policy, store listing copy, icon, feature graphic, and fallback screenshots exist under `UDPCore/docs/` and `UDPCore/store/`.
- `flutter analyze` was clean at the time of the handoff.

Do not rely on these claims without checking them.

## Local release checklist

### 1. Configure and validate signing

- Fill in `UDPCore/android/key.properties` with the real credentials.
- Confirm the keystore alias.
- Confirm the release signing configuration reads `key.properties`.
- Confirm the file remains ignored by Git.

### 2. Audit and build

From `UDPCore/`, run the appropriate checks, including:

```bash
flutter analyze
flutter test
flutter build appbundle --release
flutter build apk --release
```

Expected bundle:

```text
UDPCore/build/app/outputs/bundle/release/app-release.aab
```

Expected APK:

```text
UDPCore/build/app/outputs/flutter-apk/app-release.apk
```

Require a successful release build. If Flutter cannot verify stripped native libraries because Android SDK Command-line Tools are missing, install those tools and rerun instead of accepting a failed build.

If Java configuration is wrong, use JDK 21:

```bash
flutter config --jdk-dir=/usr/lib/jvm/java-21-openjdk-amd64
```

### 3. Test the signed APK on a physical phone

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

If installation fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, the installed copy was signed with another key. Uninstall it, understanding that this erases the app's saved settings, then install the release APK:

```bash
adb uninstall com.mehdibahlaoui.udpcore
adb install build/app/outputs/flutter-apk/app-release.apk
```

Verify:

- Wi-Fi/Bluetooth and arrows/sliders switches work independently.
- Slider and hold-button commands send over Wi-Fi.
- Bluetooth sending still works.
- Connection and error labels are readable.
- Settings and About content are correct.

### 4. Capture current store screenshots

Capture four clean landscape screenshots, preferably framed to 16:9 at 1920×1080:

1. Slider surface connected, with varied values.
2. Arrow D-pad connected.
3. Bluetooth device list with a connected device.
4. Settings screen with custom commands.

Use `UDPCore/store/screenshots/` only as a fallback because those images may show an older UI.

### 5. Publish and verify the privacy policy

The public policy source is maintained at:

```text
/home/mehdi/Desktop/Endeavours/Projects/Website/udpcore_privacy_policy.html
```

Publish the Website repository and verify this URL in a private browser window before adding it to Play Console:

```text
https://mehdibahlaoui.com/udpcore_privacy_policy.html
```

## Play Console checklist

### 6. Update the existing app

- Open the existing UDPCore app in Play Console.
- Do not create a replacement app.
- Review the current closed-testing tracks and tester lists.
- Supersede old releases with the new release; do not delete the app.

### 7. Update the store listing

Use `UDPCore/store/listing.md` for the app name, short description, full description, and release notes.

Upload:

- App icon: `UDPCore/store/icon-512.png`
- Feature graphic: `UDPCore/store/feature-graphic-1024x500.png`
- Four current phone screenshots

Set category to **Tools** and add the verified privacy-policy URL wherever requested.

### 8. Complete App content declarations

Every required declaration must be complete and consistent with the app and privacy policy.

| Declaration | Answer |
|---|---|
| Privacy policy | Published URL above |
| App access | All functionality available; no login |
| Ads | No |
| Content rating | Utility; no violence, sex, gambling, drugs, or user-to-user communication |
| Target audience | 18+; no age band under 13 |
| News app | No |
| COVID-19 app | No |
| Data safety | No data collected or shared; settings stay on-device |
| Government app | No |
| Financial features | None |
| Health app | No |
| Advertising ID | Not used |

Suggested App access note:

> Requires an ESP32/Arduino on the same Wi-Fi network, or a paired Bluetooth serial device, to send commands. The UI is fully browsable without hardware.

Verify these answers against the actual dependency graph, merged Android manifest, network behavior, and current Play definitions before submitting them.

### 9. Start a new closed-test release

- Create or reuse an appropriate closed-testing track inside the existing app.
- Upload `app-release.aab`.
- Add the release notes from `UDPCore/store/listing.md`.
- Roll out the release to the closed track.
- Prefer a Google Group for tester management.
- Share only the opt-in link and package name with testers. Never share Play Console access.

The working assumption from the original handoff is that a new personal developer account needs at least 12 continuously opted-in testers for 14 days. Verify the exact current rule and whether it applies to this account before relying on it. Target about 15 testers to provide a buffer.

Use trusted testers or a reputable testing community/service. If paying, require a written refund condition tied to production-access approval, use a payment method with dispute protection, and never give the service Google account or Play Console credentials.

### 10. Monitor and apply for production

- Confirm when the closed-test eligibility clock actually starts.
- Monitor tester count and engagement throughout the required period.
- Keep the count above the verified minimum.
- After eligibility is met, apply for production access.
- Give specific, truthful answers about recruitment, engagement, target users, feedback, and changes made during testing.
- Use the split selectors and Wi-Fi slider-routing fix as feedback-driven changes only if that is factually accurate.
- Once production access is granted, promote the verified release to production and complete the rollout.

## Completion criteria

The release is complete only when:

- Local analysis/tests pass.
- The signed release AAB builds successfully with the registered upload key.
- The signed APK passes physical-device smoke testing.
- Current store assets and listing copy are uploaded.
- The privacy policy is publicly reachable.
- All Play Console declarations are complete and accurate.
- Closed-testing requirements are satisfied, if applicable.
- Production access is granted and the production rollout is completed.
