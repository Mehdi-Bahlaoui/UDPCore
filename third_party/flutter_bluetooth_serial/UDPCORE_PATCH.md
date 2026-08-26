# UDPCore Android permission patch

This directory vendors `flutter_bluetooth_serial` 0.4.0 under its original
GPL-3.0 license because the upstream package is unmaintained and hard-codes
legacy location checks on every Android version.

UDPCore's fork changes only Android compatibility and permission handling:

- Android 12 and newer request `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` (Nearby
  Devices), with `neverForLocation` on scanning.
- Android 11 and older request fine location only for device discovery.
- Bonded-device listing and RFCOMM connections request only the permissions
  they actually need.
- Permission requests are serialized so simultaneous startup/scan operations
  cannot overwrite each other's callbacks.
- The Android library uses the current namespace, SDK, and Java toolchain.

Do not replace this path dependency with the hosted 0.4.0 package without
porting these changes, or Bluetooth discovery will regress on Android 12+.
