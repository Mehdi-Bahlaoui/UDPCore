import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class StorageService {
  static Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sliderConfigs = List.generate(9, (i) {
      final idx = i + 1;
      return SliderConfig(
        name: prefs.getString('bt_s${idx}_name') ?? 'S$idx',
        min: prefs.getDouble('bt_s${idx}_min') ?? 0.0,
        max: prefs.getDouble('bt_s${idx}_max') ?? 180.0,
      );
    });
    return SettingsModel(
      communicationMode: CommunicationMode.values.firstWhere(
        (e) => e.name == (prefs.getString('communicationMode') ?? 'udp'),
        orElse: () => CommunicationMode.udp,
      ),
      targetIp: prefs.getString('targetIp') ?? '172.22.25.169',
      targetPort: prefs.getInt('targetPort') ?? 4210,
      speed: prefs.getInt('speed') ?? 100,
      forwardCommand: prefs.getString('forwardCommand') ?? 'F',
      leftCommand: prefs.getString('leftCommand') ?? 'L',
      backwardCommand: prefs.getString('backwardCommand') ?? 'B',
      rightCommand: prefs.getString('rightCommand') ?? 'R',
      stopCommand: prefs.getString('stopCommand') ?? 'S',
      btDeviceAddress: prefs.getString('btDeviceAddress'),
      btDeviceName: prefs.getString('btDeviceName'),
      sliderConfigs: sliderConfigs,
      continuousSend: prefs.getBool('continuousSend') ?? false,
      holdSliderSend: prefs.getBool('holdSliderSend') ?? false,
      btStopCommand: prefs.getString('btStopCommand') ?? 'S',
      sendAsBytes: prefs.getBool('sendAsBytes') ?? false,
    );
  }

  static Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('communicationMode', settings.communicationMode.name);
    await prefs.setString('targetIp', settings.targetIp);
    await prefs.setInt('targetPort', settings.targetPort);
    await prefs.setInt('speed', settings.speed);
    await prefs.setString('forwardCommand', settings.forwardCommand);
    await prefs.setString('leftCommand', settings.leftCommand);
    await prefs.setString('backwardCommand', settings.backwardCommand);
    await prefs.setString('rightCommand', settings.rightCommand);
    await prefs.setString('stopCommand', settings.stopCommand);
    if (settings.btDeviceAddress != null) {
      await prefs.setString('btDeviceAddress', settings.btDeviceAddress!);
    }
    if (settings.btDeviceName != null) {
      await prefs.setString('btDeviceName', settings.btDeviceName!);
    }
    await prefs.setBool('continuousSend', settings.continuousSend);
    await prefs.setBool('holdSliderSend', settings.holdSliderSend);
    await prefs.setString('btStopCommand', settings.btStopCommand);
    await prefs.setBool('sendAsBytes', settings.sendAsBytes);
    for (int i = 0; i < 9; i++) {
      final idx = i + 1;
      await prefs.setString('bt_s${idx}_name', settings.sliderConfigs[i].name);
      await prefs.setDouble('bt_s${idx}_min', settings.sliderConfigs[i].min);
      await prefs.setDouble('bt_s${idx}_max', settings.sliderConfigs[i].max);
    }
  }
}
