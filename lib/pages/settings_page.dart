import 'package:flutter/material.dart';
import '../models/settings_model.dart';

class SettingsPage extends StatefulWidget {
  final SettingsModel settings;
  final Function(SettingsModel) onConnect;
  final VoidCallback onBackTap;

  SettingsPage({
    required this.settings,
    required this.onConnect,
    required this.onBackTap,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _speedController;
  late TextEditingController _forwardController;
  late TextEditingController _leftController;
  late TextEditingController _backwardController;
  late TextEditingController _rightController;
  late TextEditingController _stopController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.settings.targetIp);
    _portController = TextEditingController(text: widget.settings.targetPort.toString());
    _speedController = TextEditingController(text: widget.settings.speed.toString());
    _forwardController = TextEditingController(text: widget.settings.forwardCommand);
    _leftController = TextEditingController(text: widget.settings.leftCommand);
    _backwardController = TextEditingController(text: widget.settings.backwardCommand);
    _rightController = TextEditingController(text: widget.settings.rightCommand);
    _stopController = TextEditingController(text: widget.settings.stopCommand);
  }

  @override
  void dispose() {
    final settings = SettingsModel(
      targetIp: _ipController.text.trim(),
      targetPort: int.tryParse(_portController.text.trim()) ?? widget.settings.targetPort,
      speed: int.tryParse(_speedController.text.trim()) ?? widget.settings.speed,
      forwardCommand: _forwardController.text.trim().isNotEmpty
          ? _forwardController.text.trim()
          : widget.settings.forwardCommand,
      leftCommand: _leftController.text.trim().isNotEmpty
          ? _leftController.text.trim()
          : widget.settings.leftCommand,
      backwardCommand: _backwardController.text.trim().isNotEmpty
          ? _backwardController.text.trim()
          : widget.settings.backwardCommand,
      rightCommand: _rightController.text.trim().isNotEmpty
          ? _rightController.text.trim()
          : widget.settings.rightCommand,
      stopCommand: _stopController.text.trim().isNotEmpty
          ? _stopController.text.trim()
          : widget.settings.stopCommand,
    );

    widget.onConnect(settings);

    _ipController.dispose();
    _portController.dispose();
    _speedController.dispose();
    _forwardController.dispose();
    _leftController.dispose();
    _backwardController.dispose();
    _rightController.dispose();
    _stopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("UDP Controller App"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBackTap,
          tooltip: 'Back to Controller',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Target IP Address"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Target Port"),
              ),
              SizedBox(height: 10),


              TextField(
                controller: _speedController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Hold Send Interval (ms)"),
              ),
              SizedBox(height: 10),

              // Horizontal rule for visual separation
              // Divider(
              //   thickness: 2,
              //   color: Colors.grey[400],
              //   height: 30,
              // ),
              SizedBox(height: 50),

              // Command settings in table format
              Table(
                columnWidths: {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8.0, bottom: 10.0),
                        child: TextField(
                          controller: _forwardController,
                          decoration: InputDecoration(labelText: "Forward Command"),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 10.0),
                        child: TextField(
                          controller: _leftController,
                          decoration: InputDecoration(labelText: "Left Command"),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8.0, bottom: 10.0),
                        child: TextField(
                          controller: _backwardController,
                          decoration: InputDecoration(labelText: "Backward Command"),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 10.0),
                        child: TextField(
                          controller: _rightController,
                          decoration: InputDecoration(labelText: "Right Command"),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8.0, bottom: 10.0),
                        child: TextField(
                          controller: _stopController,
                          decoration: InputDecoration(labelText: "Stop Command"),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 10.0),
                        child: Container(), // Empty cell
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}