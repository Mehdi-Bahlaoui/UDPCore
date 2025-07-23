import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/settings_model.dart';

class ControllerPage extends StatefulWidget {
  final SettingsModel settings;
  final VoidCallback onSettingsTap;
  final VoidCallback onAboutTap;

  ControllerPage({
    required this.settings,
    required this.onSettingsTap,
    required this.onAboutTap,
  });

  @override
  _ControllerPageState createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  RawDatagramSocket? _socket;
  bool _socketReady = false;
  Timer? _sendTimer;
  String _currentCommand = "";

  @override
  void initState() {
    super.initState();
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
      _socket = socket;
      _socketReady = true;
    });
  }

  void _startSending(String command) {
    if (!_socketReady || _socket == null) return;
    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(Duration(milliseconds: widget.settings.speed), (_) {
      _socket!.send(command.codeUnits, InternetAddress(widget.settings.targetIp), widget.settings.targetPort);
      setState(() {
        _currentCommand = command;
      });
    });
  }

  void _stopSending() {
    if (_socketReady && _socket != null) {
      _socket!.send(
        widget.settings.stopCommand.codeUnits,
        InternetAddress(widget.settings.targetIp),
        widget.settings.targetPort,
      );
      setState(() {
        _currentCommand = widget.settings.stopCommand;
      });
    }
    _sendTimer?.cancel();
    _sendTimer = null;
  }

  Widget _controlButton(
      IconData icon,
      String command, {
        double size = 80,
        Color? color,
      }) {
    return Listener(
      onPointerDown: (_) {
        HapticFeedback.lightImpact();
        _startSending(command);
      },
      onPointerUp: (_) {
        HapticFeedback.selectionClick();
        _stopSending();
      },
      onPointerCancel: (_) {
        HapticFeedback.selectionClick();
        _stopSending();
      },
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ??
              (_currentCommand == command
                  ? Colors.blueAccent.withOpacity(0.9)
                  : Colors.blue.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = min(screenSize.width * 0.15, screenSize.height * 0.2);

    return Stack(
      clipBehavior: Clip.none,

      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/Artboard_1.png"),
              opacity: 0.3,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Main control area
        Positioned(
          top: screenSize.height * 0.2,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status labels
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _currentCommand.isEmpty
                      ? "Ready | ${widget.settings.targetIp}:${widget.settings.targetPort}"
                      : "Sending: $_currentCommand",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Directional pad
              Column(
                children: [
                  _controlButton(
                    Icons.arrow_upward,
                    widget.settings.forwardCommand,
                    size: buttonSize,
                    color: Colors.black38,
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _controlButton(
                        Icons.arrow_back,
                        widget.settings.leftCommand,
                        size: buttonSize,
                        color: Colors.black38,
                      ),
                      SizedBox(width: buttonSize * 1.2),
                      _controlButton(
                        Icons.arrow_forward,
                        widget.settings.rightCommand,
                        size: buttonSize,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  _controlButton(
                    Icons.arrow_downward,
                    widget.settings.backwardCommand,
                    size: buttonSize,
                    color: Colors.black38,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Settings button (top-left)
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            width: buttonSize * 0.7,
            height: buttonSize * 0.7,
            child: IconButton(
              icon: Icon(
                Icons.settings,
                size: buttonSize * 0.5,
                color: Colors.black38,
              ),
              onPressed: widget.onSettingsTap,
              tooltip: 'Go to Settings',
            ),
          ),
        ),

        // About Us button (top-right)
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: buttonSize * 0.7,
            height: buttonSize * 0.7,
            child: IconButton(
              icon: Icon(
                Icons.info,
                size: buttonSize * 0.5,
                color: Colors.black38,
              ),
              onPressed: widget.onAboutTap,
              tooltip: 'About Us',
            ),
          ),
        ),
      ],
    );
  }
}