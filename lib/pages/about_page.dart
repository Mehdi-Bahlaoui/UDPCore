import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutThisApp extends StatelessWidget {
  final VoidCallback onBackTap;

  const AboutThisApp({super.key, required this.onBackTap});

  static final _privacyPolicyUri = Uri.parse(
    'https://mehdi-bahlaoui.github.io/UDPCore/privacy-policy.html',
  );

  static const _body =
      "UDPCore started life as a UDP-only remote for ESP devices. UDP is a "
      "connectionless protocol: it skips the handshake and the other round-trips "
      "that add latency, at the cost of guaranteed delivery. For driving a robot "
      "in real time, that is a trade worth making.\n\n"
      "It has since grown past UDP. UDPCore now also speaks Bluetooth Classic, "
      "and it ships two control surfaces:\n\n"
      "  •  an arrow D-pad, for simple drive commands\n"
      "  •  nine configurable sliders with hold buttons, for servos and finer control\n\n"
      "The transport switch sits at the top left and the control-surface switch at "
      "the top right, and they are independent — sliders over Wi-Fi, arrows over "
      "Bluetooth, whatever your build needs.\n\n"
      "Future updates include:\n\n"
      "  1)  A richer reception panel for data coming back from the ESP "
      "(sensor readings, for example).\n"
      "  2)  More control surfaces, and saved presets per device.";

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await launchUrl(
      _privacyPolicyUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the privacy policy.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About This App"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: onBackTap,
          tooltip: 'Back to Controller',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(_body, style: TextStyle(fontSize: 16, height: 1.4)),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => _openPrivacyPolicy(context),
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text('Privacy Policy'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Dedicated to the Roboticore Club of ENSAM Rabat, Morocco.",
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
