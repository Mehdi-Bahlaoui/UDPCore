enum CommunicationMode { udp, bluetooth }

class SliderConfig {
  final String name;
  final double min;
  final double max;
  final double defaultValue;
  const SliderConfig({this.name = '', this.min = 0, this.max = 180, this.defaultValue = 0});
  SliderConfig copyWith({String? name, double? min, double? max, double? defaultValue}) =>
      SliderConfig(
        name: name ?? this.name,
        min: min ?? this.min,
        max: max ?? this.max,
        defaultValue: defaultValue ?? this.defaultValue,
      );
}

class SettingsModel {
  final CommunicationMode communicationMode;
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

  SettingsModel({
    this.communicationMode = CommunicationMode.udp,
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
  }) : sliderConfigs = sliderConfigs ?? const [
    SliderConfig(name: 'S1', min: 28.6, max: 141.3, defaultValue: 87.4),
    SliderConfig(name: 'S2', min: 11.2, max: 180, defaultValue: 90),
    SliderConfig(name: 'S3', min: 51.9, max: 149.1, defaultValue: 95.2),
    SliderConfig(name: 'S4', min: 8.6, max: 165.3, defaultValue: 87.4),

    SliderConfig(name: 'S5', min: 0, max: 180, defaultValue: 84.1),
    SliderConfig(name: 'S6', min: 0, max: 180, defaultValue: 90.7),

    SliderConfig(name: 'S7', min: 0, max: 180, defaultValue: 90),
    SliderConfig(name: 'S8', min: 0, max: 180, defaultValue: 90),
    SliderConfig(name: 'S9', min: 0, max: 180, defaultValue: 90),
  ];

  SettingsModel copyWith({
    CommunicationMode? communicationMode,
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
  }) {
    return SettingsModel(
      communicationMode: communicationMode ?? this.communicationMode,
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
    );
  }
}
