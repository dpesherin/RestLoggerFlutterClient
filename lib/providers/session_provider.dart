import 'package:flutter/material.dart';

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
      id: json['id']?.toString() ?? '',
      device: json['device'] ?? 'Неизвестное устройство',
      ip: json['ip'],
      lastActive: json['lastActive'],
      isCurrent: json['isCurrent'] ?? false,
    );
  }
}

class SessionProvider extends ChangeNotifier {
  List<SessionModel> _sessions = [];
  bool _isLoading = false;

  List<SessionModel> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;

  void updateSessions(List<SessionModel> sessions) {
    _sessions = sessions;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void removeSession(String sessionId) {
    _sessions.removeWhere((session) => session.id == sessionId);
    notifyListeners();
  }

  void clearSessions() {
    _sessions.clear();
    notifyListeners();
  }
}
