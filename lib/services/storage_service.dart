import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static const String _userKey = 'user';
  static const String _tokenKey = 'jwt_token';
  static const String _consumerKey = 'consumer_key';
  static const String _sessionIdKey = 'session_id';
  static const String _themeKey = 'theme_mode';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveUser(User user) async {
    try {
      final userJson = json.encode(user.toJson());
      await _prefs.setString(_userKey, userJson);
    } catch (e) {}
  }

  static Future<User?> getUser() async {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson != null) {
        final Map<String, dynamic> userMap = json.decode(userJson);
        return User.fromJson(userMap);
      }
    } catch (e) {}
    return null;
  }

  static Future<void> saveToken(String? token) async {
    try {
      if (token != null) {
        await _prefs.setString(_tokenKey, token);
      } else {
        await _prefs.remove(_tokenKey);
      }
    } catch (e) {}
  }

  static Future<String?> getToken() async {
    try {
      final token = _prefs.getString(_tokenKey);
      return token;
    } catch (e) {
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
    } catch (e) {}
  }

  static Future<String?> getConsumerKey() async {
    try {
      final key = _prefs.getString(_consumerKey);
      return key;
    } catch (e) {
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
    } catch (e) {}
  }

  static Future<String?> getSessionId() async {
    try {
      final sessionId = _prefs.getString(_sessionIdKey);
      return sessionId;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final String value = mode.toString().split('.').last;
      await _prefs.setString(_themeKey, value);
    } catch (e) {}
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
    } catch (e) {}
    return null;
  }

  static Future<void> clearAll() async {
    try {
      await _prefs.clear();
    } catch (e) {}
  }
}
