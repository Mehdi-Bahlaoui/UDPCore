import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/services.dart' show PlatformException;

enum BluetoothConnectionStatus { disconnected, connecting, connected, error }

class BluetoothPermissionException implements Exception {
  final String message;

  const BluetoothPermissionException(this.message);

  @override
  String toString() => message;
}

String describeBluetoothError(Object error) {
  if (error is BluetoothPermissionException) return error.message;
  if (error is PlatformException) {
    return error.message?.trim().isNotEmpty == true
        ? error.message!.trim()
        : error.code;
  }
  return error.toString().replaceFirst('Exception: ', '');
}

class BluetoothService {
  final _statusController =
      StreamController<BluetoothConnectionStatus>.broadcast();
  final _dataController = StreamController<String>.broadcast();

  Stream<BluetoothConnectionStatus> get statusStream =>
      _statusController.stream;
  Stream<String> get dataStream => _dataController.stream;

  BluetoothConnectionStatus _status = BluetoothConnectionStatus.disconnected;
  BluetoothConnectionStatus get status => _status;

  String? _lastError;
  String? get lastError => _lastError;

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
    _lastError = null;
    try {
      await _requireConnectPermission();
      if (isConnected) await disconnect();
      _emit(BluetoothConnectionStatus.connecting);
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
        onError: (Object error) {
          _lastError = describeBluetoothError(error);
          _connection = null;
          _emit(BluetoothConnectionStatus.error);
        },
      );
    } catch (error) {
      _lastError = describeBluetoothError(error);
      _connection = null;
      _emit(BluetoothConnectionStatus.error);
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;
    _lastError = null;
    _emit(BluetoothConnectionStatus.disconnected);
  }

  // --- Command sending (fire-and-forget, mirrors UDP socket.send semantics) ---

  void sendCommand(String command) {
    if (!isConnected) return;
    try {
      _connection!.output.add(Uint8List.fromList(command.codeUnits));
    } catch (error) {
      _lastError = describeBluetoothError(error);
      _connection = null;
      _emit(BluetoothConnectionStatus.error);
    }
  }

  void sendRawBytes(List<int> bytes) {
    if (!isConnected) return;
    try {
      _connection!.output.add(Uint8List.fromList(bytes));
    } catch (error) {
      _lastError = describeBluetoothError(error);
      _connection = null;
      _emit(BluetoothConnectionStatus.error);
    }
  }

  // Sends a 4-byte config packet: [0xFE][paramId][valLow][valHigh]
  // value is int16 (can be negative, e.g. center offsets)
  void sendConfigPacket(int paramId, int value) {
    final v = value & 0xFFFF; // two's complement for negatives
    sendRawBytes([0xFE, paramId, v & 0xFF, (v >> 8) & 0xFF]);
  }

  // --- Discovery helpers (used by BluetoothSettingsPage) ---

  Future<List<BluetoothDevice>> getBondedDevices() async {
    await _requireConnectPermission();
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Stream<BluetoothDiscoveryResult> startDiscovery() async* {
    await _requireDiscoveryPermissions();
    yield* FlutterBluetoothSerial.instance.startDiscovery();
  }

  Future<void> cancelDiscovery() async {
    await FlutterBluetoothSerial.instance.cancelDiscovery();
  }

  Future<bool?> bondDevice(String address) async {
    await _requireConnectPermission();
    return await FlutterBluetoothSerial.instance.bondDeviceAtAddress(address);
  }

  Future<void> _requireConnectPermission() async {
    final granted =
        await FlutterBluetoothSerial.instance.requestConnectPermissions();
    if (!granted) {
      throw const BluetoothPermissionException(
        'Nearby Devices permission is required to use Bluetooth',
      );
    }
  }

  Future<void> _requireDiscoveryPermissions() async {
    final granted =
        await FlutterBluetoothSerial.instance.requestDiscoveryPermissions();
    if (!granted) {
      throw const BluetoothPermissionException(
        'Allow Nearby Devices to scan on Android 12+, or Location on Android 11 and older',
      );
    }
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
