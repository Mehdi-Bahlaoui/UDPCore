import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/controller_page.dart';
import 'pages/settings_page.dart';
import 'pages/about_page.dart';
import 'models/settings_model.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      MaterialApp(debugShowCheckedModeBanner: false, home: MainApp());
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _selectedPage = 'controller';
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
    _loadSettings();
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
        onSettingsTap: () => setState(() => _selectedPage = 'settings'),
        onAboutTap: () => setState(() => _selectedPage = 'about'),
      );
    } else if (_selectedPage == 'settings') {
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