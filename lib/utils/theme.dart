import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final savedTheme = await StorageService.getThemeMode();
      if (savedTheme != null) {
        _themeMode = savedTheme;
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await StorageService.saveThemeMode(_themeMode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await StorageService.saveThemeMode(_themeMode);
      notifyListeners();
    }
  }
}

class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF5A8FEC),
    scaffoldBackgroundColor: const Color(0xFFE0E5EC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE0E5EC),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF2D4059)),
      titleTextStyle: TextStyle(
        color: Color(0xFF2D4059),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardColor: Colors.white,
    dividerColor: Colors.grey.shade300,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2D4059)),
      bodyMedium: TextStyle(color: Color(0xFF2D4059)),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF5A8FEC),
    scaffoldBackgroundColor: const Color(0xFF1A1E24),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1E24),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardColor: const Color(0xFF2C313A),
    dividerColor: Colors.grey.shade800,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}
