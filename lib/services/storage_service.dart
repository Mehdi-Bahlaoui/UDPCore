import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class StorageService {
  static Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsModel(
      targetIp: prefs.getString('targetIp') ?? '172.22.25.169',
      targetPort: prefs.getInt('targetPort') ?? 4210,
      speed: prefs.getInt('speed') ?? 100,
      forwardCommand: prefs.getString('forwardCommand') ?? 'F',
      leftCommand: prefs.getString('leftCommand') ?? 'L',
      backwardCommand: prefs.getString('backwardCommand') ?? 'B',
      rightCommand: prefs.getString('rightCommand') ?? 'R',
      stopCommand: prefs.getString('stopCommand') ?? 'S',
    );
  }

  static Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('targetIp', settings.targetIp);
    await prefs.setInt('targetPort', settings.targetPort);
    await prefs.setInt('speed', settings.speed);
    await prefs.setString('forwardCommand', settings.forwardCommand);
    await prefs.setString('leftCommand', settings.leftCommand);
    await prefs.setString('backwardCommand', settings.backwardCommand);
    await prefs.setString('rightCommand', settings.rightCommand);
    await prefs.setString('stopCommand', settings.stopCommand);
  }
}