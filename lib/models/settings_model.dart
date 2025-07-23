class SettingsModel {
  final String targetIp;
  final int targetPort;
  final int speed;
  final String forwardCommand;
  final String leftCommand;
  final String backwardCommand;
  final String rightCommand;
  final String stopCommand;

  SettingsModel({
    required this.targetIp,
    required this.targetPort,
    required this.speed,
    required this.forwardCommand,
    required this.leftCommand,
    required this.backwardCommand,
    required this.rightCommand,
    required this.stopCommand,
  });

  // Optional: Add a copyWith method for updating settings
  SettingsModel copyWith({
    String? targetIp,
    int? targetPort,
    int? speed,
    String? forwardCommand,
    String? leftCommand,
    String? backwardCommand,
    String? rightCommand,
    String? stopCommand,
  }) {
    return SettingsModel(
      targetIp: targetIp ?? this.targetIp,
      targetPort: targetPort ?? this.targetPort,
      speed: speed ?? this.speed,
      forwardCommand: forwardCommand ?? this.forwardCommand,
      leftCommand: leftCommand ?? this.leftCommand,
      backwardCommand: backwardCommand ?? this.backwardCommand,
      rightCommand: rightCommand ?? this.rightCommand,
      stopCommand: stopCommand ?? this.stopCommand,
    );
  }
}