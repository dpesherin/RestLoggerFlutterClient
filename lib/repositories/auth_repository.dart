import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
  const AuthRepository();

  Future<void> login(String login, String password) async {
    await ApiService.auth(login, password);
  }

  Future<void> register(String login, String password) async {
    await ApiService.register(login, password);
  }

  Future<void> logout() {
    return ApiService.logout();
  }

  Future<void> logoutAll() {
    return ApiService.logoutAll();
  }

  Future<bool> checkAuth() {
    return ApiService.checkAuth();
  }

  Future<AuthStatusInfo> getAuthStatusInfo() {
    return ApiService.getAuthStatusInfo();
  }

  Future<User?> getStoredUser() {
    return StorageService.getUser();
  }

  Future<String?> getStoredConsumerKey() {
    return StorageService.getConsumerKey();
  }

  Future<bool> hasStoredSession() async {
    final user = await getStoredUser();
    final consumerKey = await getStoredConsumerKey();
    return user != null && consumerKey != null;
  }
}
