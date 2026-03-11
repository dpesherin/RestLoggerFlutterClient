import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../utils/config.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final sessionId = await StorageService.getSessionId();
    final token = await StorageService.getToken();

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (sessionId != null) {
      headers['Cookie'] = 'sessionId=$sessionId';
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static String? _extractConsumerKeyFromJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        final payload =
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final Map<String, dynamic> payloadData = jsonDecode(payload);
        return payloadData['consumerKey'] as String?;
      }
    } catch (e) {}
    return null;
  }

  static Future<Map<String, dynamic>> auth(
      String login, String password) async {
    final url = Uri.parse('$baseUrl/auth');
    final headers = await _getHeaders();

    try {
      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = jsonEncode({'login': login, 'pass': password});

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 8),
          );

      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = utf8.decode(response.bodyBytes);

      if (responseBody.isNotEmpty) {
        final data = jsonDecode(responseBody);

        if (response.statusCode == 401) {
          throw AuthException(data['msg'] ?? 'Сессия истекла');
        }

        if (response.statusCode >= 400) {
          throw ApiException(data['msg'] ?? 'Ошибка ${response.statusCode}');
        }

        if (data['status'] == 'ok') {
          final String? jwtToken = data['token'];
          String? consumerKey;

          if (jwtToken != null && jwtToken.isNotEmpty) {
            await StorageService.saveToken(jwtToken);
            consumerKey = _extractConsumerKeyFromJWT(jwtToken);
          }

          if (data['user'] != null) {
            final userData = Map<String, dynamic>.from(data['user']);
            if (consumerKey != null) {
              userData['consumerKey'] = consumerKey;
            }

            final user = User.fromJson(userData);
            await StorageService.saveUser(user);
          }

          if (consumerKey != null) {
            await StorageService.saveConsumerKey(consumerKey);
          }

          if (data['sessionId'] != null) {
            await StorageService.saveSessionId(data['sessionId']);
          }
        }

        return data;
      } else {
        throw ApiException('Пустой ответ от сервера');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register(
      String login, String password) async {
    final data = await _request('/registration',
        method: 'POST', body: {'login': login, 'pass': password});

    if (data['status'] == 'ok') {
      final String? jwtToken = data['token'];
      String? consumerKey;

      if (jwtToken != null && jwtToken.isNotEmpty) {
        await StorageService.saveToken(jwtToken);
        consumerKey = _extractConsumerKeyFromJWT(jwtToken);
      }

      if (data['user'] != null) {
        final userData = Map<String, dynamic>.from(data['user']);
        if (consumerKey != null) {
          userData['consumerKey'] = consumerKey;
        }

        final user = User.fromJson(userData);
        await StorageService.saveUser(user);
      }

      if (consumerKey != null) {
        await StorageService.saveConsumerKey(consumerKey);
      } else if (data['consumerKey'] != null) {
        await StorageService.saveConsumerKey(data['consumerKey']);
      }

      if (data['sessionId'] != null) {
        await StorageService.saveSessionId(data['sessionId']);
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final request = http.Request(method, url)
        ..headers.addAll(headers)
        ..body = body != null ? jsonEncode(body) : '';

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 8),
          );

      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = utf8.decode(response.bodyBytes);

      if (responseBody.isNotEmpty) {
        try {
          final data = jsonDecode(responseBody);

          if (response.statusCode == 401) {
            throw AuthException(data['msg'] ?? 'Сессия истекла');
          }

          if (response.statusCode == 403) {
            throw AuthException('Доступ запрещен');
          }

          if (response.statusCode >= 400) {
            throw ApiException(data['msg'] ?? 'Ошибка ${response.statusCode}');
          }

          return data;
        } catch (e) {
          rethrow;
        }
      } else {
        throw ApiException('Пустой ответ от сервера');
      }
    } catch (e) {
      if (e is AuthException || e is ApiException) rethrow;
      throw ApiException('Ошибка соединения: $e');
    }
  }

  static Future<Map<String, dynamic>> whoami() async {
    final data = await _request('/whoami');
    return data;
  }

  static Future<void> logout() async {
    try {
      await _request('/logout', method: 'POST');
    } finally {
      await StorageService.clearAll();
    }
  }

  static Future<void> logoutAll() async {
    try {
      await _request('/logout-all', method: 'POST');
    } finally {
      await StorageService.clearAll();
    }
  }

  static Future<List<dynamic>> getSessions() async {
    try {
      final data = await _request('/sessions');
      return data['sessions'] ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> terminateSession(String sessionId) async {
    try {
      final data = await _request('/sessions/$sessionId', method: 'DELETE');
      return data['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkAuth() async {
    try {
      final data = await whoami();
      final isAuth = data['status'] == 'ok';
      return isAuth;
    } catch (e) {
      return false;
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
