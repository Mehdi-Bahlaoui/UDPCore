import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/settings_model.dart';
import '../services/bluetooth_service.dart';

class BluetoothSettingsPage extends StatefulWidget {
  final SettingsModel settings;
  final BluetoothService bluetoothService;
  final Function(SettingsModel) onSave;
  final VoidCallback onBackTap;

  const BluetoothSettingsPage({
    required this.settings,
    required this.bluetoothService,
    required this.onSave,
    required this.onBackTap,
  });

  @override
  _BluetoothSettingsPageState createState() => _BluetoothSettingsPageState();
}

class _BluetoothSettingsPageState extends State<BluetoothSettingsPage> {
  bool _disposed = false;
  StreamSubscription<BluetoothConnectionStatus>? _statusSub;
  late BluetoothConnectionStatus _btStatus;

  List<BluetoothDevice> _bondedDevices = [];
  List<BluetoothDiscoveryResult> _discoveredDevices = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySub;
  bool _isScanning = false;
  bool _isLoadingBonded = false;

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

  @override
  void initState() {
    super.initState();
    _btStatus = widget.bluetoothService.status;
    _statusSub = widget.bluetoothService.statusStream.listen((s) {
      if (!_disposed && mounted) setState(() => _btStatus = s);
    });

    _selectedAddress = widget.settings.btDeviceAddress;
    _selectedName = widget.settings.btDeviceName;

    _speedController =
        TextEditingController(text: widget.settings.speed.toString());
    _btStopController =
        TextEditingController(text: widget.settings.btStopCommand);
    _continuousSend = widget.settings.continuousSend;
    _holdSliderSend = widget.settings.holdSliderSend;
    _sendAsBytes = widget.settings.sendAsBytes;

    _sliderNameControllers = List.generate(
      9,
      (i) {
        final name = widget.settings.sliderConfigs[i].name;
        return TextEditingController(text: name.isNotEmpty ? name : 'S${i + 1}');
      },
    );
    _sliderMinControllers = List.generate(
      9,
      (i) => TextEditingController(
          text: widget.settings.sliderConfigs[i].min.toString()),
    );
    _sliderMaxControllers = List.generate(
      9,
      (i) => TextEditingController(
          text: widget.settings.sliderConfigs[i].max.toString()),
    );
    _sliderDefaultControllers = List.generate(
      9,
      (i) => TextEditingController(
          text: widget.settings.sliderConfigs[i].defaultValue.round().toString()),
    );

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
        name: _sliderNameControllers[i].text.trim().isNotEmpty
            ? _sliderNameControllers[i].text.trim()
            : 'S${i + 1}',
        min: double.tryParse(_sliderMinControllers[i].text.trim()) ??
            widget.settings.sliderConfigs[i].min,
        max: double.tryParse(_sliderMaxControllers[i].text.trim()) ??
            widget.settings.sliderConfigs[i].max,
        defaultValue: double.tryParse(_sliderDefaultControllers[i].text.trim()) ??
            widget.settings.sliderConfigs[i].defaultValue,
      ),
    );
    final updated = widget.settings.copyWith(
      speed: int.tryParse(_speedController.text.trim()) ?? widget.settings.speed,
      btDeviceAddress: _selectedAddress,
      btDeviceName: _selectedName,
      sliderConfigs: updatedSliderConfigs,
      continuousSend: _continuousSend,
      holdSliderSend: _holdSliderSend,
      btStopCommand: _btStopController.text.trim(),
      sendAsBytes: _sendAsBytes,
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

    super.dispose();
  }

  Future<void> _loadBondedDevices() async {
    setState(() => _isLoadingBonded = true);
    try {
      final devices = await widget.bluetoothService.getBondedDevices();
      if (mounted) setState(() => _bondedDevices = devices);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingBonded = false);
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    final btGranted = (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
        (statuses[Permission.bluetoothConnect]?.isGranted ?? false);
    final locGranted = statuses[Permission.location]?.isGranted ?? false;
    return btGranted || locGranted;
  }

  Future<void> _startScan() async {
    final granted = await _requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth/location permission denied')),
        );
      }
      return;
    }
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });
    _discoverySub?.cancel();
    _discoverySub = widget.bluetoothService.startDiscovery().listen(
      (result) {
        if (mounted) {
          setState(() {
            _discoveredDevices.removeWhere(
                (r) => r.device.address == result.device.address);
            _discoveredDevices.add(result);
          });
        }
      },
      onDone: () {
        if (mounted) setState(() => _isScanning = false);
      },
      onError: (_) {
        if (mounted) setState(() => _isScanning = false);
      },
    );
  }

  Future<void> _stopScan() async {
    await widget.bluetoothService.cancelDiscovery();
    _discoverySub?.cancel();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _pairDevice(BluetoothDevice device) async {
    final granted = await _requestPermissions();
    if (!granted) return;
    try {
      final bonded = await widget.bluetoothService.bondDevice(device.address);
      if (bonded == true) {
        await _loadBondedDevices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Paired with ${device.name ?? device.address}')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    await widget.bluetoothService.connect(device.address);
    if (widget.bluetoothService.isConnected) {
      setState(() {
        _selectedAddress = device.address;
        _selectedName = device.name ?? device.address;
      });
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
        return 'Connection error';
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
        color: isConnected
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
                  padding: const EdgeInsets.symmetric(horizontal: 6)),
              child: const Text('Pair', style: TextStyle(fontSize: 12)),
            ),
          TextButton(
            onPressed: isConnected
                ? _disconnectDevice
                : () => _connectDevice(device),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6)),
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

        // Bonded devices
        Row(
          children: [
            const Text('Bonded Devices',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            child: Text('No bonded devices',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else
          ...(_bondedDevices
              .map((d) => _buildDeviceTile(d, isBonded: true))
              .toList()),

        const Divider(height: 16),

        // Discovery
        Row(
          children: [
            const Text('Nearby Devices',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            _isScanning
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: _stopScan,
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child:
                            const Text('Stop', style: TextStyle(fontSize: 12)),
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
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
          ],
        ),
        const SizedBox(height: 4),
        if (_discoveredDevices.isEmpty && !_isScanning)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Tap Scan to discover devices',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else
          ...(_discoveredDevices.map((r) {
            final alreadyBonded =
                _bondedDevices.any((b) => b.address == r.device.address);
            return _buildDeviceTile(r.device, isBonded: alreadyBonded);
          }).toList()),
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
              isDense: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _btStopController,
          style: const TextStyle(fontSize: 15),
          decoration: const InputDecoration(
              labelText: 'Button Release Command (empty = none)',
              labelStyle: TextStyle(fontSize: 15),
              isDense: true),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _continuousSend,
              onChanged: (v) => setState(() { _continuousSend = v ?? false; }),
            ),
            const Text('Send all continuously', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 16),
            Checkbox(
              value: _holdSliderSend,
              onChanged: (v) {
                if (_continuousSend) return;
                setState(() { _holdSliderSend = v ?? false; });
              },
            ),
            const Text('Hold-to-send per slider', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 16),
            Checkbox(
              value: _sendAsBytes,
              onChanged: (v) => setState(() { _sendAsBytes = v ?? false; }),
            ),
            const Text('Send as bytes', style: TextStyle(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Slider Config',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  child: Text('Name',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 4, bottom: 6),
                  child: Text('Min',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Max',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text('Default',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            for (int i = 0; i < 9; i++)
              TableRow(children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
              ]),
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
            const Divider(height: 32),
            _buildDevicePanel(),
          ],
        ),
      ),
    );
  }
}
