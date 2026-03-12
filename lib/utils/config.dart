import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

class AppConfig {
  static final Map<String, String> _env = <String, String>{};
  static bool _initialized = false;
  static String _appVersion = '1.0.0';
  static String _appBuildNumber = '1';

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final envFile = File(
        '${Directory.current.path}${Platform.pathSeparator}.env',
      );

      if (await envFile.exists()) {
        final lines = await envFile.readAsLines();
        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.isEmpty || line.startsWith('#')) continue;

          final separatorIndex = line.indexOf('=');
          if (separatorIndex <= 0) continue;

          final key = line.substring(0, separatorIndex).trim();
          final value = line.substring(separatorIndex + 1).trim();
          _env[key] = value;
        }
      }

      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _appBuildNumber = packageInfo.buildNumber;
    } catch (_) {
      // Fallback values below keep the app usable even without .env.
    } finally {
      _initialized = true;
    }
  }

  static String _read(String key, String fallback) {
    return _env[key] ?? fallback;
  }

  static String get apiBaseUrl =>
      _read('API_BASE_URL', 'https://logger.dp-projects.ru');

  static String get wsUrl => _read('WS_URL', 'wss://logger.dp-projects.ru');

  static String get docsUrl =>
      _read('DOCS_URL', 'https://logger.dp-projects.ru/docs');

  static String get updaterBaseUrl =>
      _read('UPDATER_BASE_URL', 'https://updater.dp-projects.ru');

  static String get appVersion => _appVersion;

  static String get appBuildNumber => _appBuildNumber;

  static String get fullVersion => '$_appVersion+$_appBuildNumber';

  static String get appEnvironment =>
      _read('APP_ENVIRONMENT', 'production');

  static bool get isProduction => appEnvironment == 'production';

  static bool get isDevelopment => appEnvironment == 'development';
}
