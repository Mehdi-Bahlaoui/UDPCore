import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/settings_model.dart';
import '../services/bluetooth_service.dart';

class ControllerPage extends StatefulWidget {
  final SettingsModel settings;
  final VoidCallback onSettingsTap;
  final VoidCallback onAboutTap;
  final Function(SettingsModel) onModeChanged;

  ControllerPage({
    required this.settings,
    required this.onSettingsTap,
    required this.onAboutTap,
    required this.onModeChanged,
  });

  @override
  _ControllerPageState createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  // --- UDP ---
  RawDatagramSocket? _socket;
  bool _socketReady = false;
  String _udpStatus = "Initializing...";

  // --- Bluetooth ---
  late BluetoothService _bluetoothService;
  StreamSubscription<BluetoothConnectionStatus>? _btStatusSub;
  BluetoothConnectionStatus _btStatus = BluetoothConnectionStatus.disconnected;

  // --- Shared ---
  bool _isInitializing = true;
  Timer? _sendTimer;
  String _currentCommand = "";
  String _pressedButton = "";

  bool get _ready =>
      widget.settings.communicationMode == CommunicationMode.udp
          ? _socketReady
          : _bluetoothService.isConnected;

  @override
  void initState() {
    super.initState();
    _bluetoothService = BluetoothService();
    _btStatusSub = _bluetoothService.statusStream.listen((s) {
      if (mounted) setState(() => _btStatus = s);
    });

    if (widget.settings.communicationMode == CommunicationMode.udp) {
      _initializeSocket();
    } else {
      setState(() => _isInitializing = false);
      if (widget.settings.btDeviceAddress != null) {
        _bluetoothService.connect(widget.settings.btDeviceAddress!);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ControllerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldMode = oldWidget.settings.communicationMode;
    final newMode = widget.settings.communicationMode;

    if (oldMode != newMode) {
      _sendTimer?.cancel();
      _pressedButton = "";

      if (newMode == CommunicationMode.udp) {
        _bluetoothService.disconnect();
        if (!_socketReady) _initializeSocket();
      } else {
        setState(() => _isInitializing = false);
        if (widget.settings.btDeviceAddress != null) {
          _bluetoothService.connect(widget.settings.btDeviceAddress!);
        }
      }
    } else if (newMode == CommunicationMode.bluetooth) {
      // New device selected in BT settings
      if (oldWidget.settings.btDeviceAddress != widget.settings.btDeviceAddress &&
          widget.settings.btDeviceAddress != null) {
        _bluetoothService.connect(widget.settings.btDeviceAddress!);
      }
    }
  }

  Future<void> _initializeSocket() async {
    if (mounted) {
      setState(() {
        _udpStatus = "Connecting...";
        _isInitializing = true;
      });
    }
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      if (mounted) {
        setState(() {
          _socket = socket;
          _socketReady = true;
          _isInitializing = false;
          _udpStatus = "Connected";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _socketReady = false;
          _isInitializing = false;
          _udpStatus = "Connection failed: $e";
        });
      }
      Timer(const Duration(seconds: 3), () {
        if (mounted) _initializeSocket();
      });
    }
  }

  void _startSending(String command) {
    if (!_ready) return;

    _sendTimer?.cancel();

    if (widget.settings.communicationMode == CommunicationMode.udp) {
      _sendTimer =
          Timer.periodic(Duration(milliseconds: widget.settings.speed), (_) {
        try {
          _socket!.send(
            command.codeUnits,
            InternetAddress(widget.settings.targetIp),
            widget.settings.targetPort,
          );
          if (mounted) setState(() => _currentCommand = command);
        } catch (e) {
          if (mounted) setState(() => _udpStatus = "Send error: $e");
        }
      });
    } else {
      _sendTimer =
          Timer.periodic(Duration(milliseconds: widget.settings.speed), (_) {
        _bluetoothService.sendCommand(command);
        if (mounted) setState(() => _currentCommand = command);
      });
    }
  }

  void _stopSending() {
    _sendTimer?.cancel();
    _sendTimer = null;

    final stopCmd = widget.settings.stopCommand;

    if (widget.settings.communicationMode == CommunicationMode.udp) {
      if (_socketReady && _socket != null) {
        try {
          _socket!.send(
            stopCmd.codeUnits,
            InternetAddress(widget.settings.targetIp),
            widget.settings.targetPort,
          );
        } catch (_) {}
      }
    } else {
      _bluetoothService.sendCommand(stopCmd);
    }

    if (mounted) {
      setState(() {
        _currentCommand = stopCmd;
        _pressedButton = "";
      });
    }
  }

  String get _statusLabel {
    if (_currentCommand.isNotEmpty) return "Sending: $_currentCommand";
    if (widget.settings.communicationMode == CommunicationMode.udp) {
      return "$_udpStatus | ${widget.settings.targetIp}:${widget.settings.targetPort}";
    }
    final name = widget.settings.btDeviceName ?? 'No device';
    return "BT: ${_btStatus.name} | $name";
  }

  Color get _statusColor {
    if (widget.settings.communicationMode == CommunicationMode.udp) {
      return _socketReady ? Colors.white : Colors.red.shade300;
    }
    return _btStatus == BluetoothConnectionStatus.connected
        ? Colors.white
        : Colors.red.shade300;
  }

  Widget _controlButton(
    IconData icon,
    String command, {
    double size = 80,
    Color? color,
  }) {
    final isPressed = _pressedButton == command;

    return Listener(
      onPointerDown: (_) {
        if (!_ready) return;
        HapticFeedback.heavyImpact();
        if (mounted) setState(() => _pressedButton = command);
        _startSending(command);
      },
      onPointerUp: (_) {
        if (!_ready) return;
        HapticFeedback.mediumImpact();
        if (mounted) setState(() => _pressedButton = "");
        _stopSending();
      },
      onPointerCancel: (_) {
        if (!_ready) return;
        HapticFeedback.mediumImpact();
        if (mounted) setState(() => _pressedButton = "");
        _stopSending();
      },
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isPressed
              ? Colors.white.withValues(alpha: 0.9)
              : (color ?? Colors.blue.withValues(alpha: _ready ? 0.8 : 0.4)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5,
            color: isPressed ? Colors.grey : (_ready ? Colors.white : Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _socket?.close();
    _btStatusSub?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize =
        min(screenSize.width * 0.14, screenSize.height * 0.18);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/Artboard_1.png"),
              opacity: 0.3,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Initializing overlay (UDP only)
        if (_isInitializing)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    _udpStatus,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

        // Mode toggle (top-center)
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: _ModeToggle(
              isBluetooth: widget.settings.communicationMode ==
                  CommunicationMode.bluetooth,
              onToggle: (isBT) {
                widget.onModeChanged(widget.settings.copyWith(
                  communicationMode: isBT
                      ? CommunicationMode.bluetooth
                      : CommunicationMode.udp,
                ));
              },
            ),
          ),
        ),

        // Main control area
        Positioned(
          top: screenSize.height * 0.2,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Status label
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // D-pad
              Column(
                children: [
                  _controlButton(
                    Icons.arrow_upward,
                    widget.settings.forwardCommand,
                    size: buttonSize,
                    color: Colors.black38,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _controlButton(
                        Icons.arrow_back,
                        widget.settings.leftCommand,
                        size: buttonSize,
                        color: Colors.black38,
                      ),
                      SizedBox(width: buttonSize * 1.0),
                      _controlButton(
                        Icons.arrow_forward,
                        widget.settings.rightCommand,
                        size: buttonSize,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
          child: SizedBox(
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

        // About button (top-right)
        Positioned(
          top: 20,
          right: 20,
          child: SizedBox(
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

// --- Mode toggle widget ---

class _ModeToggle extends StatelessWidget {
  final bool isBluetooth;
  final ValueChanged<bool> onToggle;

  const _ModeToggle({required this.isBluetooth, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi,
            size: 18,
            color: isBluetooth ? Colors.white38 : Colors.white,
          ),
          Switch(
            value: isBluetooth,
            onChanged: onToggle,
            activeThumbColor: Colors.lightBlueAccent,
            inactiveThumbColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Icon(
            Icons.bluetooth,
            size: 18,
            color: isBluetooth ? Colors.lightBlueAccent : Colors.white38,
          ),
        ],
      ),
    );
  }
}
