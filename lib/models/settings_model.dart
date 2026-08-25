enum CommunicationMode { udp, bluetooth }

/// Which control surface the controller page shows. Independent of the
/// transport in [CommunicationMode] — either surface can drive either
/// transport.
enum ControlUi { dpad, sliders }

class RobotConfig {
  final int step;
  final int lift;
  final int lean;
  final int moveTime;
  final int moveSteps;
  final List<int> centerOffsets; // 6 values, one per servo

  const RobotConfig({
    this.step = 170,
    this.lift = 120,
    this.lean = 200,
    this.moveTime = 300,
    this.moveSteps = 40,
    List<int>? centerOffsets,
  }) : centerOffsets = centerOffsets ?? const [0, 0, 0, 0, 0, 0];

  RobotConfig copyWith({
    int? step,
    int? lift,
    int? lean,
    int? moveTime,
    int? moveSteps,
    List<int>? centerOffsets,
  }) => RobotConfig(
    step: step ?? this.step,
    lift: lift ?? this.lift,
    lean: lean ?? this.lean,
    moveTime: moveTime ?? this.moveTime,
    moveSteps: moveSteps ?? this.moveSteps,
    centerOffsets: centerOffsets ?? List<int>.from(this.centerOffsets),
  );
}

class MehdiConfig {
  final int lean; // degrees (converted to µs at ~13 µs/° before sending)
  final int lift; // degrees
  final int fall; // degrees
  final int timeInterval; // ms

  const MehdiConfig({
    this.lean = 15,
    this.lift = 25,
    this.fall = 12,
    this.timeInterval = 400,
  });

  MehdiConfig copyWith({int? lean, int? lift, int? fall, int? timeInterval}) =>
      MehdiConfig(
        lean: lean ?? this.lean,
        lift: lift ?? this.lift,
        fall: fall ?? this.fall,
        timeInterval: timeInterval ?? this.timeInterval,
      );
}

class SliderConfig {
  final String name;
  final double min;
  final double max;
  final double defaultValue;
  const SliderConfig({
    this.name = '',
    this.min = 0,
    this.max = 180,
    this.defaultValue = 0,
  });
  SliderConfig copyWith({
    String? name,
    double? min,
    double? max,
    double? defaultValue,
  }) => SliderConfig(
    name: name ?? this.name,
    min: min ?? this.min,
    max: max ?? this.max,
    defaultValue: defaultValue ?? this.defaultValue,
  );
}

const defaultSliderConfigs = [
  SliderConfig(name: 'S1', min: 28.6, max: 141.3, defaultValue: 87),
  SliderConfig(name: 'S2', min: 11.2, max: 180, defaultValue: 106),
  SliderConfig(name: 'S3', min: 51.9, max: 149.1, defaultValue: 93),
  SliderConfig(name: 'S4', min: 8.6, max: 165.3, defaultValue: 87),
  SliderConfig(name: 'S5', min: 0, max: 180, defaultValue: 84),
  SliderConfig(name: 'S6', min: 0, max: 180, defaultValue: 91),
  SliderConfig(name: 'S7', min: 0, max: 180, defaultValue: 90),
  SliderConfig(name: 'S8', min: 0, max: 180, defaultValue: 90),
  SliderConfig(name: 'S9', min: 0, max: 180, defaultValue: 90),
];

class SettingsModel {
  final CommunicationMode communicationMode;
  final ControlUi controlUi;
  final String targetIp;
  final int targetPort;
  final int speed;
  final String forwardCommand;
  final String leftCommand;
  final String backwardCommand;
  final String rightCommand;
  final String stopCommand;
  final String? btDeviceAddress;
  final String? btDeviceName;
  final List<SliderConfig> sliderConfigs;
  final bool continuousSend;
  final bool holdSliderSend;
  final String btStopCommand;
  final bool sendAsBytes;
  final RobotConfig robotConfig;
  final MehdiConfig mehdiConfig;

  SettingsModel({
    this.communicationMode = CommunicationMode.udp,
    this.controlUi = ControlUi.dpad,
    required this.targetIp,
    required this.targetPort,
    required this.speed,
    required this.forwardCommand,
    required this.leftCommand,
    required this.backwardCommand,
    required this.rightCommand,
    required this.stopCommand,
    this.btDeviceAddress,
    this.btDeviceName,
    List<SliderConfig>? sliderConfigs,
    this.continuousSend = false,
    this.holdSliderSend = false,
    this.btStopCommand = 'S',
    this.sendAsBytes = false,
    RobotConfig? robotConfig,
    MehdiConfig? mehdiConfig,
  }) : robotConfig = robotConfig ?? const RobotConfig(),
       mehdiConfig = mehdiConfig ?? const MehdiConfig(),
       sliderConfigs = sliderConfigs ?? defaultSliderConfigs;

  SettingsModel copyWith({
    CommunicationMode? communicationMode,
    ControlUi? controlUi,
    String? targetIp,
    int? targetPort,
    int? speed,
    String? forwardCommand,
    String? leftCommand,
    String? backwardCommand,
    String? rightCommand,
    String? stopCommand,
    String? btDeviceAddress,
    String? btDeviceName,
    List<SliderConfig>? sliderConfigs,
    bool? continuousSend,
    bool? holdSliderSend,
    String? btStopCommand,
    bool? sendAsBytes,
    RobotConfig? robotConfig,
    MehdiConfig? mehdiConfig,
  }) {
    return SettingsModel(
      communicationMode: communicationMode ?? this.communicationMode,
      controlUi: controlUi ?? this.controlUi,
      targetIp: targetIp ?? this.targetIp,
      targetPort: targetPort ?? this.targetPort,
      speed: speed ?? this.speed,
      forwardCommand: forwardCommand ?? this.forwardCommand,
      leftCommand: leftCommand ?? this.leftCommand,
      backwardCommand: backwardCommand ?? this.backwardCommand,
      rightCommand: rightCommand ?? this.rightCommand,
      stopCommand: stopCommand ?? this.stopCommand,
      btDeviceAddress: btDeviceAddress ?? this.btDeviceAddress,
      btDeviceName: btDeviceName ?? this.btDeviceName,
      sliderConfigs: sliderConfigs ?? this.sliderConfigs,
      continuousSend: continuousSend ?? this.continuousSend,
      holdSliderSend: holdSliderSend ?? this.holdSliderSend,
      btStopCommand: btStopCommand ?? this.btStopCommand,
      sendAsBytes: sendAsBytes ?? this.sendAsBytes,
      robotConfig: robotConfig ?? this.robotConfig,
      mehdiConfig: mehdiConfig ?? this.mehdiConfig,
    );
  }
}
