# UDPCore — Play Console store listing copy

Paste each block into the matching field. Character limits are Google's.

---

## App name  (max 30)

```
UDPCore: ESP Remote Control
```
*(27 chars. Plain `UDPCore` also works, but the longer form is searchable.)*

---

## Short description  (max 80)

```
Control ESP32, ESP8266 and Arduino over Wi-Fi UDP or Bluetooth. Near-zero lag.
```
*(77 chars.)*

---

## Full description  (max 4000)

```
UDPCore is a fast, no-nonsense remote control for the hardware you build.

Point it at an ESP32, ESP8266, Arduino or any device that listens on your local
network, and drive it in real time — over Wi-Fi using UDP, or over a Bluetooth
Classic serial link.

WHY UDP
Most remote-control apps talk TCP, which spends time on handshakes and
retransmissions you do not want in a control loop. UDP skips all of it and fires
the packet immediately. For steering a robot or nudging a servo, that trade —
lower latency in exchange for best-effort delivery — is exactly the right one.

TWO CONTROL SURFACES
• Arrow D-pad — forward, back, left, right, with a stop command sent on release.
  Ideal for driving robots and RC builds.
• Nine sliders with hold buttons — each with its own name, minimum, maximum and
  default. Ideal for servo arms, hexapods, pan-tilt rigs and anything that needs
  a continuous value rather than a direction.

Switch the control surface and the transport independently. Sliders over Wi-Fi,
arrows over Bluetooth, or any other combination your build needs.

FULLY CONFIGURABLE
• Set the target IP address and port.
• Set the send interval, from a fast control loop to an occasional nudge.
• Assign your own command string to every button.
• Send commands as plain text, or as raw bytes for compact binary protocols.
• Choose continuous streaming or send-on-change.
• Read data coming back from the device in the on-screen receive panel.

BUILT FOR THE WORKBENCH
• Locked to landscape, so the controls stay where your thumbs are.
• Haptic feedback on every press.
• Live connection status, so you know instantly when a link drops.
• Settings persist between sessions.

NO ACCOUNT, NO ADS, NO TRACKING
UDPCore has no sign-up, shows no advertising, and collects no personal data.
Your settings stay on your device, and your commands go straight to your
hardware — never through a server of ours, because there isn't one.

WHAT YOU NEED
A device on your Wi-Fi network listening for UDP packets, or a paired Bluetooth
Classic serial device such as an HC-05, HC-06 or an ESP32 running SerialBT.
Example receiver firmware is on the project's GitHub page.

UDPCore is dedicated to the Roboticore Club of ENSAM Rabat, Morocco.
```

---

## Category & tags

- **App category:** Tools
- **Tags:** suggested — *Utilities*, *Developer tools*
- **Contact email:** mehdibahlaoui3@gmail.com
- **Website (optional):** https://github.com/Mehdi-Bahlaoui/UDPCore
- **Privacy policy URL:** https://mehdi-bahlaoui.github.io/UDPCore/privacy-policy.html

---

## Release notes  (for the closed-testing release, max 500)

```
- The transport (Wi-Fi/Bluetooth) and the control surface (arrows/sliders) now
  have separate switches, so any combination works.
- Sliders now send over Wi-Fi as well as Bluetooth.
- Fixed the connection status label being unreadable against the background.
- Updated the About screen.
```
