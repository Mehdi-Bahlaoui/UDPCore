enum CommunicationMode { udp, bluetooth }

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
  });

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
    );
  }
}
