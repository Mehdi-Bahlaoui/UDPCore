import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/settings_model.dart';
import '../services/bluetooth_service.dart';

class ControllerPage extends StatefulWidget {
  final SettingsModel settings;
  final BluetoothService bluetoothService;
  final VoidCallback onSettingsTap;
  final VoidCallback onAboutTap;
  final Function(SettingsModel) onModeChanged;

  const ControllerPage({
    super.key,
    required this.settings,
    required this.bluetoothService,
    required this.onSettingsTap,
    required this.onAboutTap,
    required this.onModeChanged,
  });

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  // --- UDP ---
  RawDatagramSocket? _socket;
  bool _socketReady = false;
  String _udpStatus = "Initializing...";

  // --- Bluetooth ---
  StreamSubscription<BluetoothConnectionStatus>? _btStatusSub;
  StreamSubscription<String>? _btDataSub;
  late BluetoothConnectionStatus _btStatus;
  String _receivedData = '';
  String _btBuffer = '';

  // --- Shared ---
  bool _isInitializing = true;
  Timer? _sendTimer;
  Timer? _continuousTimer;
  Timer? _sliderHoldTimer;
  String _currentCommand = "";
  String _pressedButton = "";

  // --- BT Sliders ---
  late List<double> _sliderValues;
  final List<bool> _btButtonStates = List.filled(9, false);

  bool get _ready =>
      widget.settings.communicationMode == CommunicationMode.udp
          ? _socketReady
          : widget.bluetoothService.isConnected;

  @override
  void initState() {
    super.initState();
    _sliderValues = List.generate(
      9,
      (i) => widget.settings.sliderConfigs[i].defaultValue,
    );

    _btStatus = widget.bluetoothService.status;
    _btStatusSub = widget.bluetoothService.statusStream.listen((s) {
      if (mounted) setState(() => _btStatus = s);
    });
    _btDataSub = widget.bluetoothService.dataStream.listen((data) {
      _btBuffer += data;
      int newlineIdx;
      while ((newlineIdx = _btBuffer.indexOf('\n')) >= 0) {
        final line = _btBuffer.substring(0, newlineIdx).trim();
        _btBuffer = _btBuffer.substring(newlineIdx + 1);
        if (mounted && line.isNotEmpty) setState(() => _receivedData = line);
      }
    });

    if (widget.settings.communicationMode == CommunicationMode.udp) {
      _initializeSocket();
    } else {
      setState(() => _isInitializing = false);
      if (!widget.bluetoothService.isConnected &&
          widget.settings.btDeviceAddress != null) {
        widget.bluetoothService.connect(widget.settings.btDeviceAddress!);
      }
    }
    _updateContinuousTimer();
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
        widget.bluetoothService.disconnect();
        if (!_socketReady) _initializeSocket();
      } else {
        setState(() => _isInitializing = false);
        if (!widget.bluetoothService.isConnected &&
            widget.settings.btDeviceAddress != null) {
          widget.bluetoothService.connect(widget.settings.btDeviceAddress!);
        }
      }
    } else if (newMode == CommunicationMode.bluetooth) {
      // New device selected in BT settings
      if (oldWidget.settings.btDeviceAddress !=
              widget.settings.btDeviceAddress &&
          widget.settings.btDeviceAddress != null) {
        widget.bluetoothService.connect(widget.settings.btDeviceAddress!);
      }
      // Clamp slider values to new config bounds
      for (int i = 0; i < 9; i++) {
        final cfg = widget.settings.sliderConfigs[i];
        _sliderValues[i] = _sliderValues[i].clamp(cfg.min, cfg.max);
      }
    }
    _updateContinuousTimer();
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

  // Encodes a command as raw bytes when sendAsBytes is enabled and the
  // command is a parseable integer (0–255). Falls back to codeUnits otherwise.
  List<int> _encodeCommand(String command) {
    if (widget.settings.sendAsBytes) {
      final v = int.tryParse(command.trim());
      if (v != null && v >= 0 && v <= 255) return [v];
    }
    return command.codeUnits;
  }

  // Routes a raw payload over whichever transport is currently selected, so
  // the slider surface works over Wi-Fi as well as Bluetooth.
  void _sendOverTransport(List<int> bytes) {
    if (widget.settings.communicationMode == CommunicationMode.udp) {
      if (!_socketReady || _socket == null) return;
      try {
        _socket!.send(
          bytes,
          InternetAddress(widget.settings.targetIp),
          widget.settings.targetPort,
        );
      } catch (e) {
        if (mounted) setState(() => _udpStatus = "Send error: $e");
      }
    } else {
      widget.bluetoothService.sendRawBytes(bytes);
    }
  }

  // Builds a 12-byte packet: [0xFF, s0..s8, btn_low, btn_high]
  List<int> _buildSliderPacket() {
    final bytes = <int>[0xFF];
    for (int i = 0; i < 9; i++) {
      bytes.add(_sliderValues[i].round().clamp(0, 255));
    }
    int btnLow = 0;
    for (int i = 0; i < 8; i++) {
      if (_btButtonStates[i]) btnLow |= (1 << i);
    }
    bytes.add(btnLow);
    bytes.add(_btButtonStates[8] ? 1 : 0);
    return bytes;
  }

  void _sendBytesPacket() {
    if (!_ready) return;
    _sendOverTransport(_buildSliderPacket());
    final values = List.generate(9, (i) => _sliderValues[i].round()).join(', ');
    if (mounted) setState(() => _currentCommand = values);
  }

  void _startSendingBytesPacket() {
    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(Duration(milliseconds: widget.settings.speed), (
      _,
    ) {
      _sendBytesPacket();
    });
  }

  void _startSending(String command) {
    if (!_ready) return;

    _sendTimer?.cancel();

    if (widget.settings.communicationMode == CommunicationMode.udp) {
      _sendTimer = Timer.periodic(
        Duration(milliseconds: widget.settings.speed),
        (_) {
          try {
            _socket!.send(
              _encodeCommand(command),
              InternetAddress(widget.settings.targetIp),
              widget.settings.targetPort,
            );
            if (mounted) setState(() => _currentCommand = command);
          } catch (e) {
            if (mounted) setState(() => _udpStatus = "Send error: $e");
          }
        },
      );
    } else {
      _sendTimer = Timer.periodic(
        Duration(milliseconds: widget.settings.speed),
        (_) {
          widget.bluetoothService.sendRawBytes(_encodeCommand(command));
          if (mounted) setState(() => _currentCommand = command);
        },
      );
    }
  }

  void _stopSending() {
    _sendTimer?.cancel();
    _sendTimer = null;

    if (widget.settings.communicationMode == CommunicationMode.udp) {
      final stopCmd = widget.settings.stopCommand;
      if (_socketReady && _socket != null) {
        try {
          _socket!.send(
            _encodeCommand(stopCmd),
            InternetAddress(widget.settings.targetIp),
            widget.settings.targetPort,
          );
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _currentCommand = stopCmd;
          _pressedButton = "";
        });
      }
    } else {
      final stopCmd = widget.settings.btStopCommand;
      if (stopCmd.isNotEmpty) {
        widget.bluetoothService.sendRawBytes(_encodeCommand(stopCmd));
      }
      if (mounted) {
        setState(() {
          _currentCommand = stopCmd;
          _pressedButton = "";
        });
      }
    }
  }

  void _updateContinuousTimer() {
    _continuousTimer?.cancel();
    if (widget.settings.controlUi == ControlUi.sliders &&
        widget.settings.continuousSend) {
      _continuousTimer = Timer.periodic(
        Duration(milliseconds: widget.settings.speed),
        (_) {
          if (!_ready) return;
          if (widget.settings.sendAsBytes) {
            _sendBytesPacket();
          } else {
            final parts = List.generate(9, (i) {
              final name = widget.settings.sliderConfigs[i].name;
              return '$name:${_sliderValues[i].round()}';
            });
            final cmd = parts.join(',');
            _sendOverTransport(cmd.codeUnits);
            if (mounted) setState(() => _currentCommand = cmd);
          }
        },
      );
    }
  }

  void _sendSliderValue(int index, double value) {
    if (!_ready) return;
    if (widget.settings.sendAsBytes) {
      _sendBytesPacket();
    } else {
      final name = widget.settings.sliderConfigs[index].name;
      final cmd = '$name:${value.round()}';
      _sendOverTransport(cmd.codeUnits);
      if (mounted) setState(() => _currentCommand = cmd);
    }
  }

  String get _statusLabel {
    if (_currentCommand.isNotEmpty) return _currentCommand;
    if (widget.settings.communicationMode == CommunicationMode.udp) {
      return "$_udpStatus | ${widget.settings.targetIp}:${widget.settings.targetPort}";
    }
    final name = widget.settings.btDeviceName ?? 'No device';
    if (_btStatus == BluetoothConnectionStatus.error &&
        widget.bluetoothService.lastError != null) {
      return "BT: ${widget.bluetoothService.lastError} | $name";
    }
    return "BT: ${_btStatus.name} | $name";
  }

  Color get _statusColor {
    // The controller background is light, so a ready status reads black on
    // both transports; failures stay red but dark enough to be legible.
    return _ready ? Colors.black : Colors.red.shade700;
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
          color:
              isPressed
                  ? Colors.white.withValues(alpha: 0.9)
                  : (color ??
                      Colors.blue.withValues(alpha: _ready ? 0.8 : 0.4)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5,
            color:
                isPressed ? Colors.grey : (_ready ? Colors.white : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderColumn(
    int index, {
    Color activeColor = Colors.blueAccent,
  }) {
    final cfg = widget.settings.sliderConfigs[index];
    final isPressed = _pressedButton == 'btn_$index';
    final btnLabel = 'B$index';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Slider label with current value
        Text(
          '${cfg.name}: ${_sliderValues[index].round()}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        // Vertical slider
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                thumbShape: const _RectThumbShape(width: 10, height: 28),
              ),
              child: Slider(
                value: _sliderValues[index].clamp(cfg.min, cfg.max),
                min: cfg.min,
                max: cfg.max,
                activeColor: activeColor.withValues(alpha: _ready ? 0.9 : 0.5),
                inactiveColor: Colors.grey.withValues(alpha: 0.75),
                onChanged: (v) {
                  setState(() => _sliderValues[index] = v);
                  if (!widget.settings.holdSliderSend) {
                    _sendSliderValue(index, v);
                  }
                },
                onChangeStart:
                    widget.settings.holdSliderSend &&
                            !widget.settings.continuousSend
                        ? (_) {
                          _sliderHoldTimer?.cancel();
                          _sliderHoldTimer = Timer.periodic(
                            Duration(milliseconds: widget.settings.speed),
                            (_) =>
                                _sendSliderValue(index, _sliderValues[index]),
                          );
                        }
                        : null,
                onChangeEnd:
                    widget.settings.holdSliderSend &&
                            !widget.settings.continuousSend
                        ? (_) => _sliderHoldTimer?.cancel()
                        : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Hold button
        Listener(
          onPointerDown: (_) {
            if (!_ready) return;
            HapticFeedback.heavyImpact();
            if (widget.settings.sendAsBytes) {
              if (mounted) {
                setState(() {
                  _pressedButton = 'btn_$index';
                  _btButtonStates[index] = true;
                });
              }
              _startSendingBytesPacket();
            } else {
              if (mounted) setState(() => _pressedButton = 'btn_$index');
              _startSending(btnLabel);
            }
          },
          onPointerUp: (_) {
            if (!_ready) return;
            HapticFeedback.mediumImpact();
            if (widget.settings.sendAsBytes) {
              _sendTimer?.cancel();
              _sendTimer = null;
              if (mounted) {
                setState(() {
                  _pressedButton = '';
                  _btButtonStates[index] = false;
                });
              }
              _sendBytesPacket();
            } else {
              if (mounted) setState(() => _pressedButton = "");
              _stopSending();
            }
          },
          onPointerCancel: (_) {
            if (!_ready) return;
            if (widget.settings.sendAsBytes) {
              _sendTimer?.cancel();
              _sendTimer = null;
              if (mounted) {
                setState(() {
                  _pressedButton = '';
                  _btButtonStates[index] = false;
                });
              }
              _sendBytesPacket();
            } else {
              if (mounted) setState(() => _pressedButton = "");
              _stopSending();
            }
          },
          child: Container(
            width: 56,
            height: 48,
            decoration: BoxDecoration(
              color:
                  isPressed
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black38,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderUI() {
    final groupDecoration = BoxDecoration(
      color: Colors.black.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(24),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // S1–S3
          Expanded(
            flex: 3,
            child: Container(
              decoration: groupDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  3,
                  (i) => Expanded(child: _buildSliderColumn(i)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // S4–S6
          Expanded(
            flex: 3,
            child: Container(
              decoration: groupDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  3,
                  (i) => Expanded(child: _buildSliderColumn(3 + i)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // S7–S9 (red group)
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(
                3,
                (i) => Expanded(
                  child: _buildSliderColumn(
                    6 + i,
                    activeColor: Colors.redAccent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDpadUI(double buttonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
    );
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _continuousTimer?.cancel();
    _sliderHoldTimer?.cancel();
    _socket?.close();
    _btStatusSub?.cancel();
    _btDataSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonSize = min(screenSize.width * 0.14, screenSize.height * 0.18);
    final isBT =
        widget.settings.communicationMode == CommunicationMode.bluetooth;
    final showSliders = widget.settings.controlUi == ControlUi.sliders;
    // Keeps the centred status label clear of the toggle clusters on both
    // sides; the right cluster also carries the BT receive chip. Each inset is
    // capped so the two can never swallow the whole width, which would resolve
    // to a negative width and assert on a very narrow screen.
    const toggleWidth = 112.0;
    final rawInset = 24 + buttonSize * 0.7 + toggleWidth + 8;
    final maxInset = (screenSize.width - 60) / 2;
    final leftInset = min(rawInset, maxInset);
    final rightInset = min(rawInset + (isBT ? 128 : 0), maxInset);

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
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

        // Transport toggle (top-left, next to settings button)
        Positioned(
          top: 28,
          left: buttonSize * 0.7 + 24,
          child: _ModeToggle(
            isBluetooth: isBT,
            onToggle: (isBluetooth) {
              widget.onModeChanged(
                widget.settings.copyWith(
                  communicationMode:
                      isBluetooth
                          ? CommunicationMode.bluetooth
                          : CommunicationMode.udp,
                ),
              );
            },
          ),
        ),

        // Status label (top-center)
        Positioned(
          top: 34,
          left: leftInset,
          right: rightInset,
          child: Center(
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Main control area
        Positioned(
          top: screenSize.height * 0.25,
          left: 12,
          right: 12,
          bottom: 12,
          child: showSliders ? _buildSliderUI() : _buildDpadUI(buttonSize),
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

        // Top-right cluster: BT receive chip, control-surface toggle, about
        Positioned(
          top: 20,
          right: 20,
          height: buttonSize * 0.7,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isBT) ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001F5B).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _receivedData.isEmpty ? '—' : _receivedData,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _ControlUiToggle(
                showSliders: showSliders,
                onToggle: (sliders) {
                  widget.onModeChanged(
                    widget.settings.copyWith(
                      controlUi: sliders ? ControlUi.sliders : ControlUi.dpad,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              SizedBox(
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
            ],
          ),
        ),
      ],
    );
  }
}

// --- Rectangular slider thumb ---

class _RectThumbShape extends SliderComponentShape {
  final double width;
  final double height;
  const _RectThumbShape({this.width = 28, this.height = 14});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint =
        Paint()
          ..color = sliderTheme.thumbColor ?? Colors.white
          ..style = PaintingStyle.fill;
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      paint,
    );
  }
}

// --- Control-surface toggle widget (top-right) ---

class _ControlUiToggle extends StatelessWidget {
  final bool showSliders;
  final ValueChanged<bool> onToggle;

  const _ControlUiToggle({required this.showSliders, required this.onToggle});

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
            Icons.gamepad,
            size: 18,
            color: showSliders ? Colors.white38 : Colors.white,
          ),
          Switch(
            value: showSliders,
            onChanged: onToggle,
            activeThumbColor: Colors.lightBlueAccent,
            inactiveThumbColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Icon(
            Icons.tune,
            size: 18,
            color: showSliders ? Colors.lightBlueAccent : Colors.white38,
          ),
        ],
      ),
    );
  }
}

// --- Transport toggle widget (top-left) ---

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
