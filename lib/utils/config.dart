import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://logger.dp-projects.ru';

  static String get wsUrl =>
      dotenv.env['WS_URL'] ?? 'https://logger.dp-projects.ru';

  static String get docsUrl =>
      dotenv.env['DOCS_URL'] ?? 'https://logger.dp-projects.ru/docs';

  static String get appEnvironment =>
      dotenv.env['APP_ENVIRONMENT'] ?? 'production';

  static bool get isProduction => appEnvironment == 'production';

  static bool get isDevelopment => appEnvironment == 'development';
}
