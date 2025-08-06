import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
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
  bool _isInitializing = true;
  String _connectionStatus = "Initializing...";
  Timer? _sendTimer;
  String _currentCommand = "";
  String _pressedButton = ""; // Track which button is currently pressed

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  Future<void> _initializeSocket() async {
    try {
      setState(() {
        _connectionStatus = "Connecting...";
        _isInitializing = true;
      });

      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      if (mounted) {
        setState(() {
          _socket = socket;
          _socketReady = true;
          _isInitializing = false;
          _connectionStatus = "Connected";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _socketReady = false;
          _isInitializing = false;
          _connectionStatus = "Connection failed: $e";
        });
      }
      // Retry after 3 seconds
      Timer(Duration(seconds: 3), () {
        if (mounted) _initializeSocket();
      });
    }
  }

  void _startSending(String command) {
    if (!_socketReady || _socket == null) {
      print("Socket not ready for command: $command");
      return;
    }

    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(Duration(milliseconds: widget.settings.speed), (_) {
      try {
        final bytesSent = _socket!.send(
          command.codeUnits,
          InternetAddress(widget.settings.targetIp),
          widget.settings.targetPort
        );
        print("Sent $bytesSent bytes: $command");

        if (mounted) {
          setState(() {
            _currentCommand = command;
          });
        }
      } catch (e) {
        print("Error sending command: $e");
        if (mounted) {
          setState(() {
            _connectionStatus = "Send error: $e";
          });
        }
      }
    });
  }

  void _stopSending() {
    _sendTimer?.cancel();
    _sendTimer = null;

    if (_socketReady && _socket != null) {
      try {
        _socket!.send(
          widget.settings.stopCommand.codeUnits,
          InternetAddress(widget.settings.targetIp),
          widget.settings.targetPort,
        );
        print("Sent stop command: ${widget.settings.stopCommand}");

        if (mounted) {
          setState(() {
            _currentCommand = widget.settings.stopCommand;
            _pressedButton = ""; // Clear pressed state when stopping
          });
        }
      } catch (e) {
        print("Error sending stop command: $e");
      }
    }
  }

  Widget _controlButton(
      IconData icon,
      String command, {
        double size = 80,
        Color? color,
      }) {
    bool isPressed = _pressedButton == command;

    return Listener(
      onPointerDown: (_) {
        if (!_socketReady) return; // Don't allow interaction if socket not ready

        HapticFeedback.heavyImpact();
        print("Button pressed: $command");

        if (mounted) {
          setState(() {
            _pressedButton = command;
          });
        }
        _startSending(command);
      },
      onPointerUp: (_) {
        if (!_socketReady) return;

        HapticFeedback.mediumImpact();
        print("Button released: $command");

        if (mounted) {
          setState(() {
            _pressedButton = "";
          });
        }
        _stopSending();
      },
      onPointerCancel: (_) {
        if (!_socketReady) return;

        HapticFeedback.mediumImpact();
        print("Button cancelled: $command");

        if (mounted) {
          setState(() {
            _pressedButton = "";
          });
        }
        _stopSending();
      },
      child: Container(
        width: size,
        height: size,
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isPressed
              ? Colors.white.withValues(alpha: 0.9) // Much lighter when pressed
              : (color ?? Colors.blue.withValues(alpha: _socketReady ? 0.8 : 0.4)), // Dimmed if not ready
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5,
            color: isPressed ? Colors.grey : (_socketReady ? Colors.white : Colors.grey), // Grey when not ready
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
    final buttonSize = min(screenSize.width * 0.14, screenSize.height * 0.18); // Slightly smaller

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

        // Connection status overlay when initializing
        if (_isInitializing)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    _connectionStatus,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

        // Main control area
        Positioned(
          top: screenSize.height * 0.2,
          left: 12, // Reduced from 20
          right: 12, // Reduced from 20
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Status labels
              Flexible( // Added Flexible to prevent overflow
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Reduced horizontal padding
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _currentCommand.isEmpty
                        ? "${_connectionStatus} | ${widget.settings.targetIp}:${widget.settings.targetPort}"
                        : "Sending: $_currentCommand",
                    style: TextStyle(
                      color: _socketReady ? Colors.white : Colors.red.shade300,
                      fontSize: 18, // Slightly smaller font
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Added overflow handling
                  ),
                ),
              ),

              SizedBox(width: 8), // Added small spacing

              // Directional pad
              Column(
                children: [
                  _controlButton(
                    Icons.arrow_upward,
                    widget.settings.forwardCommand,
                    size: buttonSize,
                    color: Colors.black38,
                  ),
                  SizedBox(height: 4), // Reduced spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _controlButton(
                        Icons.arrow_back,
                        widget.settings.leftCommand,
                        size: buttonSize,
                        color: Colors.black38,
                      ),
                      SizedBox(width: buttonSize * 1.0), // Reduced spacing between buttons
                      _controlButton(
                        Icons.arrow_forward,
                        widget.settings.rightCommand,
                        size: buttonSize,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                  SizedBox(height: 4), // Reduced spacing
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

