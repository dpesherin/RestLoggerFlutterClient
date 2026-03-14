import 'package:flutter/foundation.dart';

import '../models/session_model.dart';
import '../repositories/session_repository.dart';

class SessionsModalController extends ChangeNotifier {
  SessionsModalController({
    SessionRepository? sessionRepository,
  }) : _sessionRepository = sessionRepository ?? const SessionRepository();

  final SessionRepository _sessionRepository;

  List<SessionModel> _sessions = const <SessionModel>[];
  bool _isLoading = true;
  bool _isProcessing = false;

  List<SessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _sessionRepository.getSessions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> terminateSession(String sessionId) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _sessionRepository.terminateSession(sessionId);
      if (success) {
        await loadSessions();
      }
      return success;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
