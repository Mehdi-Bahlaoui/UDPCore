enum CommunicationMode { udp, bluetooth }

class SliderConfig {
  final String name;
  final double min;
  final double max;
  final String buttonCommand;
  const SliderConfig({this.name = '', this.min = 0, this.max = 100, this.buttonCommand = ''});
  SliderConfig copyWith({String? name, double? min, double? max, String? buttonCommand}) =>
      SliderConfig(
        name: name ?? this.name,
        min: min ?? this.min,
        max: max ?? this.max,
        buttonCommand: buttonCommand ?? this.buttonCommand,
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
  }) : sliderConfigs = sliderConfigs ?? List.generate(9, (_) => const SliderConfig());

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
    );
  }
}
