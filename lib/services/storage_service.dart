import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_documentation_project.dart';
import '../models/user.dart';
import '../utils/logger.dart';

class StorageService {
  static const String _userKey = 'user';
  static const String _tokenKey = 'jwt_token';
  static const String _consumerKey = 'consumer_key';
  static const String _sessionIdKey = 'session_id';
  static const String _themeKey = 'theme_mode';
  static const String _apiDocumentationProjectsKey =
      'api_documentation_projects';
  static const String _autoCheckUpdatesKey = 'auto_check_updates';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveUser(User user) async {
    try {
      final userJson = json.encode(user.toJson());
      await _prefs.setString(_userKey, userJson);
    } catch (e, stack) {
      logger.warning('Не удалось сохранить пользователя: $e');
      logger.debug(stack.toString());
    }
  }

  static Future<User?> getUser() async {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson != null) {
        final Map<String, dynamic> userMap = json.decode(userJson);
        return User.fromJson(userMap);
      }
    } catch (e, stack) {
      logger.warning('Не удалось прочитать пользователя: $e');
      logger.debug(stack.toString());
    }
    return null;
  }

  static Future<void> saveToken(String? token) async {
    try {
      if (token != null) {
        await _prefs.setString(_tokenKey, token);
      } else {
        await _prefs.remove(_tokenKey);
      }
    } catch (e, stack) {
      logger.warning('Не удалось сохранить токен: $e');
      logger.debug(stack.toString());
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = _prefs.getString(_tokenKey);
      return token;
    } catch (e) {
      logger.warning('Не удалось прочитать токен: $e');
      return null;
    }
  }

  static Future<void> saveConsumerKey(String? key) async {
    try {
      if (key != null) {
        await _prefs.setString(_consumerKey, key);
      } else {
        await _prefs.remove(_consumerKey);
      }
    } catch (e, stack) {
      logger.warning('Не удалось сохранить consumer key: $e');
      logger.debug(stack.toString());
    }
  }

  static Future<String?> getConsumerKey() async {
    try {
      final key = _prefs.getString(_consumerKey);
      return key;
    } catch (e) {
      logger.warning('Не удалось прочитать consumer key: $e');
      return null;
    }
  }

  static Future<void> saveSessionId(String? sessionId) async {
    try {
      if (sessionId != null) {
        await _prefs.setString(_sessionIdKey, sessionId);
      } else {
        await _prefs.remove(_sessionIdKey);
      }
    } catch (e, stack) {
      logger.warning('Не удалось сохранить session id: $e');
      logger.debug(stack.toString());
    }
  }

  static Future<String?> getSessionId() async {
    try {
      final sessionId = _prefs.getString(_sessionIdKey);
      return sessionId;
    } catch (e) {
      logger.warning('Не удалось прочитать session id: $e');
      return null;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final String value = mode.toString().split('.').last;
      await _prefs.setString(_themeKey, value);
    } catch (e, stack) {
      logger.warning('Не удалось сохранить тему: $e');
      logger.debug(stack.toString());
    }
  }

  static Future<ThemeMode?> getThemeMode() async {
    try {
      final String? value = _prefs.getString(_themeKey);
      if (value != null) {
        switch (value) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          default:
            return ThemeMode.system;
        }
      }
    } catch (e, stack) {
      logger.warning('Не удалось прочитать тему: $e');
      logger.debug(stack.toString());
    }
    return null;
  }

  static Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _prefs.remove(_userKey),
        _prefs.remove(_tokenKey),
        _prefs.remove(_consumerKey),
        _prefs.remove(_sessionIdKey),
      ]);
    } catch (e, stack) {
      logger.warning('Не удалось очистить auth-данные: $e');
      logger.debug(stack.toString());
    }
  }

  static Future<void> clearAll() async {
    try {
      await _prefs.clear();
    } catch (e, stack) {
      logger.warning('Не удалось очистить хранилище: $e');
      logger.debug(stack.toString());
    }
  }

  static Future<void> saveApiDocumentationProjects(
    List<ApiDocumentationProject> projects,
  ) async {
    try {
      final projectsJson =
          json.encode(projects.map((project) => project.toJson()).toList());
      await _prefs.setString(_apiDocumentationProjectsKey, projectsJson);
    } catch (e, stack) {
      logger.warning('Не удалось сохранить проекты документации: $e');
      logger.debug(stack.toString());
    }
  }

  static Future<List<ApiDocumentationProject>>
      getApiDocumentationProjects() async {
    try {
      final projectsJson = _prefs.getString(_apiDocumentationProjectsKey);
      if (projectsJson == null || projectsJson.isEmpty) {
        return const [];
      }

      final decoded = json.decode(projectsJson);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((item) => ApiDocumentationProject.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (e, stack) {
      logger.warning('Не удалось прочитать проекты документации: $e');
      logger.debug(stack.toString());
      return const [];
    }
  }

  static Future<void> saveAutoCheckUpdates(bool enabled) async {
    try {
      await _prefs.setBool(_autoCheckUpdatesKey, enabled);
    } catch (e, stack) {
      logger.warning('Не удалось сохранить настройку автообновлений: $e');
      logger.debug(stack.toString());
    }
  }

  static Future<bool> getAutoCheckUpdates() async {
    try {
      return _prefs.getBool(_autoCheckUpdatesKey) ?? true;
    } catch (e, stack) {
      logger.warning('Не удалось прочитать настройку автообновлений: $e');
      logger.debug(stack.toString());
      return true;
    }
  }
}
