import 'package:flutter/material.dart';
import '../models/session_model.dart';

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
