import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/settings_model.dart';
import '../services/bluetooth_service.dart';

class BluetoothSettingsPage extends StatefulWidget {
  final SettingsModel settings;
  final BluetoothService bluetoothService;
  final Function(SettingsModel) onSave;
  final VoidCallback onBackTap;

  const BluetoothSettingsPage({
    super.key,
    required this.settings,
    required this.bluetoothService,
    required this.onSave,
    required this.onBackTap,
  });

  @override
  State<BluetoothSettingsPage> createState() => _BluetoothSettingsPageState();
}

class _BluetoothSettingsPageState extends State<BluetoothSettingsPage> {
  bool _disposed = false;
  StreamSubscription<BluetoothConnectionStatus>? _statusSub;
  late BluetoothConnectionStatus _btStatus;

  List<BluetoothDevice> _bondedDevices = [];
  final List<BluetoothDiscoveryResult> _discoveredDevices = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySub;
  bool _isScanning = false;
  bool _isLoadingBonded = false;
  String? _deviceError;

  String? _selectedAddress;
  String? _selectedName;

  late TextEditingController _speedController;
  late TextEditingController _btStopController;
  bool _continuousSend = false;
  bool _holdSliderSend = false;
  bool _sendAsBytes = false;
  late List<TextEditingController> _sliderNameControllers;
  late List<TextEditingController> _sliderMinControllers;
  late List<TextEditingController> _sliderMaxControllers;
  late List<TextEditingController> _sliderDefaultControllers;

  // Robot walk config controllers
  late TextEditingController _stepCtrl;
  late TextEditingController _liftCtrl;
  late TextEditingController _leanCtrl;
  late TextEditingController _moveTimeCtrl;
  late TextEditingController _moveStepsCtrl;
  late List<TextEditingController> _offsetControllers;

  // MehdiWalk config controllers
  late TextEditingController _mwLeanCtrl;
  late TextEditingController _mwLiftCtrl;
  late TextEditingController _mwFallCtrl;
  late TextEditingController _mwTimeCtrl;

  @override
  void initState() {
    super.initState();
    _btStatus = widget.bluetoothService.status;
    _statusSub = widget.bluetoothService.statusStream.listen((s) {
      if (!_disposed && mounted) setState(() => _btStatus = s);
    });

    _selectedAddress = widget.settings.btDeviceAddress;
    _selectedName = widget.settings.btDeviceName;

    _speedController = TextEditingController(
      text: widget.settings.speed.toString(),
    );
    _btStopController = TextEditingController(
      text: widget.settings.btStopCommand,
    );
    _continuousSend = widget.settings.continuousSend;
    _holdSliderSend = widget.settings.holdSliderSend;
    _sendAsBytes = widget.settings.sendAsBytes;

    _sliderNameControllers = List.generate(9, (i) {
      final name = widget.settings.sliderConfigs[i].name;
      return TextEditingController(text: name.isNotEmpty ? name : 'S${i + 1}');
    });
    _sliderMinControllers = List.generate(
      9,
      (i) => TextEditingController(
        text: widget.settings.sliderConfigs[i].min.toString(),
      ),
    );
    _sliderMaxControllers = List.generate(
      9,
      (i) => TextEditingController(
        text: widget.settings.sliderConfigs[i].max.toString(),
      ),
    );
    _sliderDefaultControllers = List.generate(
      9,
      (i) => TextEditingController(
        text: widget.settings.sliderConfigs[i].defaultValue.round().toString(),
      ),
    );

    final rc = widget.settings.robotConfig;
    _stepCtrl = TextEditingController(text: rc.step.toString());
    _liftCtrl = TextEditingController(text: rc.lift.toString());
    _leanCtrl = TextEditingController(text: rc.lean.toString());
    _moveTimeCtrl = TextEditingController(text: rc.moveTime.toString());
    _moveStepsCtrl = TextEditingController(text: rc.moveSteps.toString());
    _offsetControllers = List.generate(
      6,
      (i) => TextEditingController(text: rc.centerOffsets[i].toString()),
    );

    final mw = widget.settings.mehdiConfig;
    _mwLeanCtrl = TextEditingController(text: mw.lean.toString());
    _mwLiftCtrl = TextEditingController(text: mw.lift.toString());
    _mwFallCtrl = TextEditingController(text: mw.fall.toString());
    _mwTimeCtrl = TextEditingController(text: mw.timeInterval.toString());

    _loadBondedDevices();
  }

  @override
  void dispose() {
    _disposed = true;
    _discoverySub?.cancel();
    _statusSub?.cancel();

    // Persist config on leave
    final updatedSliderConfigs = List.generate(
      9,
      (i) => SliderConfig(
        name:
            _sliderNameControllers[i].text.trim().isNotEmpty
                ? _sliderNameControllers[i].text.trim()
                : 'S${i + 1}',
        min:
            double.tryParse(_sliderMinControllers[i].text.trim()) ??
            widget.settings.sliderConfigs[i].min,
        max:
            double.tryParse(_sliderMaxControllers[i].text.trim()) ??
            widget.settings.sliderConfigs[i].max,
        defaultValue:
            double.tryParse(_sliderDefaultControllers[i].text.trim()) ??
            widget.settings.sliderConfigs[i].defaultValue,
      ),
    );
    final updatedMehdiConfig = MehdiConfig(
      lean:
          int.tryParse(_mwLeanCtrl.text.trim()) ??
          widget.settings.mehdiConfig.lean,
      lift:
          int.tryParse(_mwLiftCtrl.text.trim()) ??
          widget.settings.mehdiConfig.lift,
      fall:
          int.tryParse(_mwFallCtrl.text.trim()) ??
          widget.settings.mehdiConfig.fall,
      timeInterval:
          int.tryParse(_mwTimeCtrl.text.trim()) ??
          widget.settings.mehdiConfig.timeInterval,
    );
    final updatedRobotConfig = RobotConfig(
      step:
          int.tryParse(_stepCtrl.text.trim()) ??
          widget.settings.robotConfig.step,
      lift:
          int.tryParse(_liftCtrl.text.trim()) ??
          widget.settings.robotConfig.lift,
      lean:
          int.tryParse(_leanCtrl.text.trim()) ??
          widget.settings.robotConfig.lean,
      moveTime:
          int.tryParse(_moveTimeCtrl.text.trim()) ??
          widget.settings.robotConfig.moveTime,
      moveSteps:
          int.tryParse(_moveStepsCtrl.text.trim()) ??
          widget.settings.robotConfig.moveSteps,
      centerOffsets: List.generate(
        6,
        (i) =>
            int.tryParse(_offsetControllers[i].text.trim()) ??
            widget.settings.robotConfig.centerOffsets[i],
      ),
    );
    final updated = widget.settings.copyWith(
      speed:
          int.tryParse(_speedController.text.trim()) ?? widget.settings.speed,
      btDeviceAddress: _selectedAddress,
      btDeviceName: _selectedName,
      sliderConfigs: updatedSliderConfigs,
      continuousSend: _continuousSend,
      holdSliderSend: _holdSliderSend,
      btStopCommand: _btStopController.text.trim(),
      sendAsBytes: _sendAsBytes,
      robotConfig: updatedRobotConfig,
      mehdiConfig: updatedMehdiConfig,
    );
    widget.onSave(updated);

    _speedController.dispose();
    _btStopController.dispose();
    for (int i = 0; i < 9; i++) {
      _sliderNameControllers[i].dispose();
      _sliderMinControllers[i].dispose();
      _sliderMaxControllers[i].dispose();
      _sliderDefaultControllers[i].dispose();
    }
    _stepCtrl.dispose();
    _liftCtrl.dispose();
    _leanCtrl.dispose();
    _moveTimeCtrl.dispose();
    _moveStepsCtrl.dispose();
    for (final c in _offsetControllers) {
      c.dispose();
    }
    _mwLeanCtrl.dispose();
    _mwLiftCtrl.dispose();
    _mwFallCtrl.dispose();
    _mwTimeCtrl.dispose();

    super.dispose();
  }

  Future<void> _loadBondedDevices() async {
    if (mounted) {
      setState(() {
        _isLoadingBonded = true;
        _deviceError = null;
      });
    }
    try {
      final devices = await widget.bluetoothService.getBondedDevices();
      if (mounted) setState(() => _bondedDevices = devices);
    } catch (error) {
      if (mounted) {
        setState(() => _deviceError = describeBluetoothError(error));
      }
    }
    if (mounted) setState(() => _isLoadingBonded = false);
  }

  void _showBluetoothError(Object error) {
    if (!mounted) return;
    final message = describeBluetoothError(error);
    setState(() => _deviceError = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
      _deviceError = null;
    });
    _discoverySub?.cancel();
    _discoverySub = widget.bluetoothService.startDiscovery().listen(
      (result) {
        if (mounted) {
          setState(() {
            _discoveredDevices.removeWhere(
              (r) => r.device.address == result.device.address,
            );
            _discoveredDevices.add(result);
          });
        }
      },
      onDone: () {
        if (mounted) setState(() => _isScanning = false);
      },
      onError: (Object error) {
        if (mounted) {
          setState(() => _isScanning = false);
          _showBluetoothError(error);
        }
      },
    );
  }

  Future<void> _stopScan() async {
    try {
      await widget.bluetoothService.cancelDiscovery();
      await _discoverySub?.cancel();
    } catch (error) {
      _showBluetoothError(error);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _pairDevice(BluetoothDevice device) async {
    try {
      final bonded = await widget.bluetoothService.bondDevice(device.address);
      if (bonded == true) {
        await _loadBondedDevices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paired with ${device.name ?? device.address}'),
            ),
          );
        }
      }
    } catch (error) {
      _showBluetoothError(error);
    }
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    await widget.bluetoothService.connect(device.address);
    if (widget.bluetoothService.isConnected) {
      setState(() {
        _selectedAddress = device.address;
        _selectedName = device.name ?? device.address;
      });
    } else if (widget.bluetoothService.lastError != null) {
      _showBluetoothError(widget.bluetoothService.lastError!);
    }
  }

  Future<void> _disconnectDevice() async {
    await widget.bluetoothService.disconnect();
  }

  Color get _statusColor {
    switch (_btStatus) {
      case BluetoothConnectionStatus.connected:
        return Colors.greenAccent;
      case BluetoothConnectionStatus.connecting:
        return Colors.orangeAccent;
      case BluetoothConnectionStatus.error:
        return Colors.redAccent;
      case BluetoothConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String get _statusText {
    switch (_btStatus) {
      case BluetoothConnectionStatus.connected:
        return 'Connected — $_selectedName';
      case BluetoothConnectionStatus.connecting:
        return 'Connecting...';
      case BluetoothConnectionStatus.error:
        return widget.bluetoothService.lastError ?? 'Connection error';
      case BluetoothConnectionStatus.disconnected:
        return _selectedAddress != null
            ? 'Selected: $_selectedName (not connected)'
            : 'No device selected';
    }
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _statusColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusText,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_btStatus == BluetoothConnectionStatus.connected)
            TextButton(
              onPressed: _disconnectDevice,
              child: const Text('Disconnect'),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(BluetoothDevice device, {bool isBonded = false}) {
    final isSelected = _selectedAddress == device.address;
    final isConnected =
        _btStatus == BluetoothConnectionStatus.connected && isSelected;

    return ListTile(
      dense: true,
      leading: Icon(
        Icons.bluetooth,
        color:
            isConnected
                ? Colors.lightBlueAccent
                : (isSelected ? Colors.blueAccent : Colors.grey),
        size: 20,
      ),
      title: Text(
        device.name ?? 'Unknown',
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(device.address, style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isBonded)
            TextButton(
              onPressed: () => _pairDevice(device),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: const Text('Pair', style: TextStyle(fontSize: 12)),
            ),
          TextButton(
            onPressed:
                isConnected ? _disconnectDevice : () => _connectDevice(device),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(
              isConnected ? 'Disconnect' : 'Connect',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBar(),
        const SizedBox(height: 12),
        if (_deviceError != null) ...[
          Text(
            _deviceError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],

        // Bonded devices
        Row(
          children: [
            const Text(
              'Bonded Devices',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadBondedDevices,
              tooltip: 'Refresh',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_isLoadingBonded)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (_bondedDevices.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No bonded devices',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        else
          ...(_bondedDevices
              .map((d) => _buildDeviceTile(d, isBonded: true))
              .toList()),

        const Divider(height: 16),

        // Discovery
        Row(
          children: [
            const Text(
              'Nearby Devices',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Spacer(),
            _isScanning
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: _stopScan,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Stop', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                )
                : TextButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.search, size: 14),
                  label: const Text('Scan', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
          ],
        ),
        const SizedBox(height: 4),
        if (_discoveredDevices.isEmpty && !_isScanning)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Tap Scan to discover devices',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        else
          ...(_discoveredDevices.map((r) {
            final alreadyBonded = _bondedDevices.any(
              (b) => b.address == r.device.address,
            );
            return _buildDeviceTile(r.device, isBonded: alreadyBonded);
          }).toList()),
      ],
    );
  }

  void _sendMehdiConfig() {
    // 0x20=MW_LEAN 0x21=MW_LIFT 0x22=MW_FALL → sent as degrees directly
    // 0x23=MW_TIME → sent as ms directly
    final params = {
      0x20: int.tryParse(_mwLeanCtrl.text.trim()) ?? 15,
      0x21: int.tryParse(_mwLiftCtrl.text.trim()) ?? 25,
      0x22: int.tryParse(_mwFallCtrl.text.trim()) ?? 12,
      0x23: int.tryParse(_mwTimeCtrl.text.trim()) ?? 400,
    };
    params.forEach((id, value) {
      widget.bluetoothService.sendConfigPacket(id, value);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('MehdiWalk config sent'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildMehdiConfigPanel() {
    final connected = _btStatus == BluetoothConnectionStatus.connected;

    Widget labeledField(String label, TextEditingController ctrl, String hint) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(isDense: true, hintText: hint),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        const Text(
          'MehdiWalk Config',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'Button 4 triggers one cycle. Lean / Lift / Fall in degrees.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            labeledField('Lean (°)', _mwLeanCtrl, '15'),
            labeledField('Lift (°)', _mwLiftCtrl, '25'),
            labeledField('Fall (°)', _mwFallCtrl, '12'),
            labeledField('Time (ms)', _mwTimeCtrl, '400'),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: connected ? _sendMehdiConfig : null,
            icon: const Icon(Icons.upload, size: 18),
            label: const Text('Update MehdiWalk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade800,
            ),
          ),
        ),
        if (!connected)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Connect to a device to send config',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  void _sendRobotConfig() {
    // Param IDs match input.h: 0x01=STEP 0x02=LIFT 0x03=LEAN 0x04=MOVE_TIME 0x05=MOVE_STEPS
    // 0x10-0x15 = centerOffsets[0-5]
    final gaitParams = {
      0x01: int.tryParse(_stepCtrl.text.trim()) ?? 170,
      0x02: int.tryParse(_liftCtrl.text.trim()) ?? 120,
      0x03: int.tryParse(_leanCtrl.text.trim()) ?? 200,
      0x04: int.tryParse(_moveTimeCtrl.text.trim()) ?? 300,
      0x05: int.tryParse(_moveStepsCtrl.text.trim()) ?? 40,
    };
    gaitParams.forEach((id, value) {
      widget.bluetoothService.sendConfigPacket(id, value);
    });
    for (int i = 0; i < 6; i++) {
      final offset = int.tryParse(_offsetControllers[i].text.trim()) ?? 0;
      widget.bluetoothService.sendConfigPacket(0x10 + i, offset);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Robot config sent'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildRobotConfigPanel() {
    final connected = _btStatus == BluetoothConnectionStatus.connected;

    Widget labeledField(
      String label,
      TextEditingController ctrl, {
      bool signed = false,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              TextField(
                controller: ctrl,
                keyboardType:
                    signed
                        ? const TextInputType.numberWithOptions(signed: true)
                        : TextInputType.number,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(isDense: true),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        const Text(
          'Robot Walk Config',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            labeledField('STEP', _stepCtrl),
            labeledField('LIFT', _liftCtrl),
            labeledField('LEAN', _leanCtrl),
            labeledField('MOVE_TIME', _moveTimeCtrl),
            labeledField('MOVE_STEPS', _moveStepsCtrl),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Center Offsets (µs)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            6,
            (i) =>
                labeledField('S${i + 1}', _offsetControllers[i], signed: true),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: connected ? _sendRobotConfig : null,
            icon: const Icon(Icons.upload, size: 18),
            label: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade800,
            ),
          ),
        ),
        if (!connected)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Connect to a device to send config',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConfigPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _speedController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 15),
          decoration: const InputDecoration(
            labelText: 'Send Interval (ms)',
            labelStyle: TextStyle(fontSize: 15),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _btStopController,
          style: const TextStyle(fontSize: 15),
          decoration: const InputDecoration(
            labelText: 'Button Release Command (empty = none)',
            labelStyle: TextStyle(fontSize: 15),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _continuousSend,
              onChanged:
                  (v) => setState(() {
                    _continuousSend = v ?? false;
                  }),
            ),
            const Text('Send all continuously', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 16),
            Checkbox(
              value: _holdSliderSend,
              onChanged: (v) {
                if (_continuousSend) return;
                setState(() {
                  _holdSliderSend = v ?? false;
                });
              },
            ),
            const Text(
              'Hold-to-send per slider',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(width: 16),
            Checkbox(
              value: _sendAsBytes,
              onChanged:
                  (v) => setState(() {
                    _sendAsBytes = v ?? false;
                  }),
            ),
            const Text('Send as bytes', style: TextStyle(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Slider Config',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.only(right: 4, bottom: 6),
                  child: Text(
                    'Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 4, bottom: 6),
                  child: Text(
                    'Min',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Max',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Default',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            for (int i = 0; i < 9; i++)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4, top: 6),
                    child: TextField(
                      controller: _sliderNameControllers[i],
                      decoration: const InputDecoration(isDense: true),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4, top: 6),
                    child: TextField(
                      controller: _sliderMinControllers[i],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: TextField(
                      controller: _sliderMaxControllers[i],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: TextField(
                      controller: _sliderDefaultControllers[i],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackTap,
          tooltip: 'Back to Controller',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigPanel(),
            _buildRobotConfigPanel(),
            _buildMehdiConfigPanel(),
            const Divider(height: 32),
            _buildDevicePanel(),
          ],
        ),
      ),
    );
  }
}
