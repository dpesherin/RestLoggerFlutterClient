class SessionModel {
  final String id;
  final String device;
  final String? ip;
  final String? lastActive;
  final bool isCurrent;

  SessionModel({
    required this.id,
    required this.device,
    this.ip,
    this.lastActive,
    this.isCurrent = false,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['sessionId']?.toString() ?? json['id']?.toString() ?? '',
      device: json['userAgent']?.toString() ??
          json['device']?.toString() ??
          'Неизвестное устройство',
      ip: json['ip']?.toString(),
      lastActive: json['lastActive']?.toString(),
      isCurrent: json['current'] == true || json['isCurrent'] == true,
    );
  }
}
