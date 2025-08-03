import 'package:flutter/material.dart';

class AboutThisApp extends StatelessWidget {
  final VoidCallback onBackTap;

  AboutThisApp({required this.onBackTap});

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
        child: Center(
          child: Text(
            "UDPCore is a fast and seamless ESP device control for robotics and IoT via the UDP Protocol.\n"
                "UDP is a connectionless protocol meaning it doesn't waste time on the handshake and other useless operations that could affect latency.\n"
                "UDP skips handshakes for minimal latency, though with reduced delivery reliability.\n"
                "The purpose of this app was and will continue to be providing the fastest interface for interaction with microcontrollers of the ESP family and others, without the worry of latency.\n\n"
                "Future Updates include:\n"
                "1) Adding a reception label, to be able to receive Data from the Esp (ie. Sensor readings).\n"
                "2) improved UI and addition of other controls like other buttons and sliders.\n\n"
                "Thank you so much for supporting this project <3",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }
}