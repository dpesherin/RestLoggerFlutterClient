import '../models/session_model.dart';
import '../services/api_service.dart';

class SessionRepository {
  const SessionRepository();

  Future<List<SessionModel>> getSessions() async {
    final sessions = await ApiService.getSessions();
    return sessions
        .whereType<Map>()
        .map((item) => SessionModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<bool> terminateSession(String sessionId) {
    return ApiService.terminateSession(sessionId);
  }
}
