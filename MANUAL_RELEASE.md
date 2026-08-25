# UDPCore — Manual Release Steps

Local work is complete. **Use the existing Play Console app. Do not delete it or create a replacement.**

## 1. Enable the privacy-policy page

In GitHub, open **UDPCore → Settings → Pages** and choose:

- Source: **Deploy from a branch**
- Branch: **master**
- Folder: **/docs**

Save, then confirm this URL loads in a private window:

<https://mehdi-bahlaoui.github.io/UDPCore/privacy-policy.html>

## 2. Finish the Play Console listing

Open the existing **UDPCore** app and update its Main store listing:

- Copy: `store/listing.md`
- Icon: `store/icon-512.png`
- Feature graphic: `store/feature-graphic-1024x500.png`
- Screenshots: `store/screenshots/`
- Category: **Tools**
- Privacy policy: the URL above

## 3. Complete App content

| Declaration | Answer |
|---|---|
| App access | All functionality available; no login |
| Ads | No |
| Content rating | Utility; answer no to restricted-content questions |
| Target audience | 18 and over |
| News / Government / Health / COVID-19 | No |
| Financial features | None |
| Data safety | No data collected or shared |
| Advertising ID | Not used |

App access note:

> Requires an ESP32/Arduino on the same Wi-Fi network, or a paired Bluetooth serial device, to send commands. The UI is fully browsable without hardware.

## 4. Start the closed test

In **Test and release → Testing → Closed testing**:

1. Create or reuse a closed-testing track.
2. Upload `build/app/outputs/bundle/release/app-release.aab`.
3. Paste the release notes from `store/listing.md`.
4. Use a Google Group for testers and roll out the release.

If Play says version code `5` was already used, stop and increment the `+5` in `pubspec.yaml` before rebuilding.

If your personal developer account was created after 13 November 2023, keep at least **12 testers opted in continuously for 14 days**. Aim for 15 so one dropout does not reset eligibility.

## 5. Apply for production

After the closed-test requirement is satisfied, use **Apply for production** from the Play Console dashboard. Give specific, truthful answers about tester recruitment, engagement, feedback, and the fixes made during testing. Once approved, promote this release to production.
