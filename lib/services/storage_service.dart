import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class StorageService {
  static Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = CommunicationMode.values.firstWhere(
      (e) => e.name == (prefs.getString('communicationMode') ?? 'udp'),
      orElse: () => CommunicationMode.udp,
    );
    // Before the control surface got its own switch it was tied to the
    // transport. Anyone upgrading without an explicit choice keeps the old
    // pairing: Bluetooth meant sliders, UDP meant the D-pad.
    final storedUi = prefs.getString('controlUi');
    return SettingsModel(
      communicationMode: mode,
      controlUi:
          storedUi == null
              ? (mode == CommunicationMode.bluetooth
                  ? ControlUi.sliders
                  : ControlUi.dpad)
              : ControlUi.values.firstWhere(
                (e) => e.name == storedUi,
                orElse: () => ControlUi.dpad,
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
      sliderConfigs: List.generate(defaultSliderConfigs.length, (i) {
        final defaults = defaultSliderConfigs[i];
        return SliderConfig(
          name: prefs.getString('sliderName$i') ?? defaults.name,
          min: prefs.getDouble('sliderMin$i') ?? defaults.min,
          max: prefs.getDouble('sliderMax$i') ?? defaults.max,
          defaultValue:
              prefs.getDouble('sliderDefault$i') ?? defaults.defaultValue,
        );
      }),
      continuousSend: prefs.getBool('continuousSend') ?? false,
      holdSliderSend: prefs.getBool('holdSliderSend') ?? false,
      btStopCommand: prefs.getString('btStopCommand') ?? 'S',
      sendAsBytes: prefs.getBool('sendAsBytes') ?? false,
      robotConfig: RobotConfig(
        step: prefs.getInt('robotStep') ?? 170,
        lift: prefs.getInt('robotLift') ?? 120,
        lean: prefs.getInt('robotLean') ?? 200,
        moveTime: prefs.getInt('robotMoveTime') ?? 300,
        moveSteps: prefs.getInt('robotMoveSteps') ?? 40,
        centerOffsets: List.generate(
          6,
          (i) => prefs.getInt('robotOffset$i') ?? 0,
        ),
      ),
      mehdiConfig: MehdiConfig(
        lean: prefs.getInt('mehdiLean') ?? 15,
        lift: prefs.getInt('mehdiLift') ?? 25,
        fall: prefs.getInt('mehdiFall') ?? 12,
        timeInterval: prefs.getInt('mehdiTimeInterval') ?? 400,
      ),
    );
  }

  static Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('communicationMode', settings.communicationMode.name);
    await prefs.setString('controlUi', settings.controlUi.name);
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
    for (int i = 0; i < settings.sliderConfigs.length; i++) {
      final slider = settings.sliderConfigs[i];
      await prefs.setString('sliderName$i', slider.name);
      await prefs.setDouble('sliderMin$i', slider.min);
      await prefs.setDouble('sliderMax$i', slider.max);
      await prefs.setDouble('sliderDefault$i', slider.defaultValue);
    }
    await prefs.setBool('continuousSend', settings.continuousSend);
    await prefs.setBool('holdSliderSend', settings.holdSliderSend);
    await prefs.setString('btStopCommand', settings.btStopCommand);
    await prefs.setBool('sendAsBytes', settings.sendAsBytes);
    await prefs.setInt('robotStep', settings.robotConfig.step);
    await prefs.setInt('robotLift', settings.robotConfig.lift);
    await prefs.setInt('robotLean', settings.robotConfig.lean);
    await prefs.setInt('robotMoveTime', settings.robotConfig.moveTime);
    await prefs.setInt('robotMoveSteps', settings.robotConfig.moveSteps);
    for (int i = 0; i < 6; i++) {
      await prefs.setInt(
        'robotOffset$i',
        settings.robotConfig.centerOffsets[i],
      );
    }
    await prefs.setInt('mehdiLean', settings.mehdiConfig.lean);
    await prefs.setInt('mehdiLift', settings.mehdiConfig.lift);
    await prefs.setInt('mehdiFall', settings.mehdiConfig.fall);
    await prefs.setInt('mehdiTimeInterval', settings.mehdiConfig.timeInterval);
  }
}
