import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/settings_model.dart';
import '../services/bluetooth_service.dart';

class BluetoothSettingsPage extends StatefulWidget {
  final SettingsModel settings;
  final Function(SettingsModel) onSave;
  final VoidCallback onBackTap;

  const BluetoothSettingsPage({
    required this.settings,
    required this.onSave,
    required this.onBackTap,
  });

  @override
  _BluetoothSettingsPageState createState() => _BluetoothSettingsPageState();
}

class _BluetoothSettingsPageState extends State<BluetoothSettingsPage> {
  late BluetoothService _service;
  StreamSubscription<BluetoothConnectionStatus>? _statusSub;
  BluetoothConnectionStatus _btStatus = BluetoothConnectionStatus.disconnected;

  List<BluetoothDevice> _bondedDevices = [];
  List<BluetoothDiscoveryResult> _discoveredDevices = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySub;
  bool _isScanning = false;
  bool _isLoadingBonded = false;

  // Currently selected device (persisted address from settings or chosen during this session)
  String? _selectedAddress;
  String? _selectedName;

  // Config controllers
  late TextEditingController _speedController;
  late TextEditingController _forwardController;
  late TextEditingController _leftController;
  late TextEditingController _backwardController;
  late TextEditingController _rightController;
  late TextEditingController _stopController;

  @override
  void initState() {
    super.initState();
    _service = BluetoothService();
    _statusSub = _service.statusStream.listen((s) {
      if (mounted) setState(() => _btStatus = s);
    });

    _selectedAddress = widget.settings.btDeviceAddress;
    _selectedName = widget.settings.btDeviceName;

    _speedController =
        TextEditingController(text: widget.settings.speed.toString());
    _forwardController =
        TextEditingController(text: widget.settings.forwardCommand);
    _leftController =
        TextEditingController(text: widget.settings.leftCommand);
    _backwardController =
        TextEditingController(text: widget.settings.backwardCommand);
    _rightController =
        TextEditingController(text: widget.settings.rightCommand);
    _stopController =
        TextEditingController(text: widget.settings.stopCommand);

    _loadBondedDevices();
  }

  @override
  void dispose() {
    _discoverySub?.cancel();
    _statusSub?.cancel();
    _service.disconnect();
    _service.dispose();

    // Persist config on leave
    final updated = widget.settings.copyWith(
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
      btDeviceAddress: _selectedAddress,
      btDeviceName: _selectedName,
    );
    widget.onSave(updated);

    _speedController.dispose();
    _forwardController.dispose();
    _leftController.dispose();
    _backwardController.dispose();
    _rightController.dispose();
    _stopController.dispose();

    super.dispose();
  }

  Future<void> _loadBondedDevices() async {
    setState(() => _isLoadingBonded = true);
    try {
      final devices = await _service.getBondedDevices();
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
    _discoverySub = _service.startDiscovery().listen(
      (result) {
        if (mounted) {
          setState(() {
            // Avoid duplicates
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
    await _service.cancelDiscovery();
    _discoverySub?.cancel();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _pairDevice(BluetoothDevice device) async {
    final granted = await _requestPermissions();
    if (!granted) return;
    try {
      final bonded = await _service.bondDevice(device.address);
      if (bonded == true) {
        await _loadBondedDevices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Paired with ${device.name ?? device.address}')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    await _service.connect(device.address);
    if (_service.isConnected) {
      setState(() {
        _selectedAddress = device.address;
        _selectedName = device.name ?? device.address;
      });
    }
  }

  Future<void> _disconnectDevice() async {
    await _service.disconnect();
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
            child: Text('No bonded devices', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
          decoration:
              const InputDecoration(labelText: 'Send Interval (ms)', isDense: true),
        ),
        const SizedBox(height: 16),
        const Text('Commands',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: TextField(
                  controller: _forwardController,
                  decoration: const InputDecoration(
                      labelText: 'Forward', isDense: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: TextField(
                  controller: _leftController,
                  decoration:
                      const InputDecoration(labelText: 'Left', isDense: true),
                ),
              ),
            ]),
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: TextField(
                  controller: _backwardController,
                  decoration: const InputDecoration(
                      labelText: 'Backward', isDense: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: TextField(
                  controller: _rightController,
                  decoration:
                      const InputDecoration(labelText: 'Right', isDense: true),
                ),
              ),
            ]),
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: TextField(
                  controller: _stopController,
                  decoration:
                      const InputDecoration(labelText: 'Stop', isDense: true),
                ),
              ),
              const SizedBox(),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: device management
            Expanded(
              child: SingleChildScrollView(
                child: _buildDevicePanel(),
              ),
            ),
            const VerticalDivider(width: 24),
            // Right: configuration
            Expanded(
              child: SingleChildScrollView(
                child: _buildConfigPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
