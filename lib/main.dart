import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/controller_page.dart';
import 'pages/settings_page.dart';
import 'pages/bluetooth_settings_page.dart';
import 'pages/about_page.dart';
import 'models/settings_model.dart';
import 'services/storage_service.dart';
import 'services/bluetooth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(debugShowCheckedModeBanner: false, home: MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _selectedPage = 'controller';
  late BluetoothService _btService;
  SettingsModel _settings = SettingsModel(
    targetIp: '172.22.25.169',
    targetPort: 4210,
    speed: 100,
    forwardCommand: 'F',
    leftCommand: 'L',
    backwardCommand: 'B',
    rightCommand: 'R',
    stopCommand: 'S',
  );

  @override
  void initState() {
    super.initState();
    _btService = BluetoothService();
    _loadSettings();
  }

  @override
  void dispose() {
    _btService.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.loadSettings();
    setState(() {
      _settings = settings;
    });
  }

  Future<void> _updateSettings(SettingsModel settings) async {
    await StorageService.saveSettings(settings);
    setState(() {
      _settings = settings;
    });
  }

  Widget _buildPage() {
    if (_selectedPage == 'controller') {
      return ControllerPage(
        settings: _settings,
        bluetoothService: _btService,
        onSettingsTap: () => setState(() => _selectedPage = 'settings'),
        onAboutTap: () => setState(() => _selectedPage = 'about'),
        onModeChanged: _updateSettings,
      );
    } else if (_selectedPage == 'settings') {
      if (_settings.communicationMode == CommunicationMode.bluetooth) {
        return BluetoothSettingsPage(
          settings: _settings,
          bluetoothService: _btService,
          onSave: _updateSettings,
          onBackTap: () => setState(() => _selectedPage = 'controller'),
        );
      }
      return SettingsPage(
        settings: _settings,
        onConnect: _updateSettings,
        onBackTap: () => setState(() => _selectedPage = 'controller'),
      );
    } else {
      return AboutThisApp(
        onBackTap: () => setState(() => _selectedPage = 'controller'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildPage());
  }
}
