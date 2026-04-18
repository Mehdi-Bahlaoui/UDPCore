import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum BluetoothConnectionStatus { disconnected, connecting, connected, error }

class BluetoothService {
  final _statusController =
      StreamController<BluetoothConnectionStatus>.broadcast();
  final _dataController = StreamController<String>.broadcast();

  Stream<BluetoothConnectionStatus> get statusStream =>
      _statusController.stream;
  Stream<String> get dataStream => _dataController.stream;

  BluetoothConnectionStatus _status = BluetoothConnectionStatus.disconnected;
  BluetoothConnectionStatus get status => _status;

  BluetoothConnection? _connection;

  bool get isConnected {
    try {
      return _connection != null && _connection!.isConnected;
    } catch (_) {
      return false;
    }
  }

  // --- Connection lifecycle ---

  Future<void> connect(String address) async {
    if (isConnected) await disconnect();
    _emit(BluetoothConnectionStatus.connecting);
    try {
      _connection = await BluetoothConnection.toAddress(address);
      _emit(BluetoothConnectionStatus.connected);

      // Watch for incoming data and disconnect
      _connection!.input!.listen(
        (data) {
          if (!_dataController.isClosed) {
            _dataController.add(utf8.decode(data, allowMalformed: true));
          }
        },
        onDone: () {
          _connection = null;
          _emit(BluetoothConnectionStatus.disconnected);
        },
        onError: (_) {
          _connection = null;
          _emit(BluetoothConnectionStatus.error);
        },
      );
    } catch (_) {
      _connection = null;
      _emit(BluetoothConnectionStatus.error);
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;
    _emit(BluetoothConnectionStatus.disconnected);
  }

  // --- Command sending (fire-and-forget, mirrors UDP socket.send semantics) ---

  void sendCommand(String command) {
    if (!isConnected) return;
    try {
      _connection!.output.add(Uint8List.fromList(command.codeUnits));
    } catch (_) {
      _connection = null;
      _emit(BluetoothConnectionStatus.error);
    }
  }

  void sendRawBytes(List<int> bytes) {
    if (!isConnected) return;
    try {
      _connection!.output.add(Uint8List.fromList(bytes));
    } catch (_) {
      _connection = null;
      _emit(BluetoothConnectionStatus.error);
    }
  }

  // --- Discovery helpers (used by BluetoothSettingsPage) ---

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Stream<BluetoothDiscoveryResult> startDiscovery() {
    return FlutterBluetoothSerial.instance.startDiscovery();
  }

  Future<void> cancelDiscovery() async {
    await FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  Future<bool?> bondDevice(String address) async {
    return await FlutterBluetoothSerial.instance.bondDeviceAtAddress(address);
  }

  // --- Cleanup ---

  void _emit(BluetoothConnectionStatus s) {
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  void dispose() {
    _connection?.close();
    _statusController.close();
    _dataController.close();
  }
}
