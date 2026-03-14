import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'services/storage_service.dart';
import 'utils/theme.dart';
import 'utils/logger.dart';
import 'utils/config.dart';
import 'utils/window_manager_helper.dart';
import 'providers/session_provider.dart';
import 'screens/splash_screen.dart';

bool _isAnyModalOpen = false;

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await AppConfig.init();

    if (Platform.isWindows || Platform.isMacOS) {
      await WindowManagerHelper().initializeMainWindow();
    }

    if (Platform.isWindows) {
      _initWindowsConsole();
      await _setupSecureContext();
    }

    await logger.init(minLevel: LogLevel.debug);

    FlutterError.onError = (FlutterErrorDetails details) {
      logger.error('Flutter ошибка: ${details.exception}', details.exception,
          details.stack);
      if (kReleaseMode) _showErrorDialog(details.exception.toString());
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      logger.error('Платформенная ошибка', error, stack);
      if (kReleaseMode) _showErrorDialog(error.toString());
      return false;
    };

    try {
      await StorageService.init();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => SessionProvider()),
          ],
          child: const MyApp(),
        ),
      );
    } catch (e, stack) {
      logger.fatal('Критическая ошибка при запуске', e, stack);
      _showErrorDialog('Критическая ошибка: $e');
    }
  }, (error, stack) {
    logger.fatal('Необработанная ошибка', error, stack);
    _showErrorDialog('Необработанная ошибка: $error');
  });
}

Future<T?> showModalWithGuard<T>(
  BuildContext context,
  Widget modal, {
  bool barrierDismissible = true,
}) async {
  if (_isAnyModalOpen) return null;

  _isAnyModalOpen = true;

  final result = await showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => PopScope(
      onPopInvokedWithResult: (_, __) {
        _isAnyModalOpen = false;
      },
      child: modal,
    ),
  );

  _isAnyModalOpen = false;
  return result;
}

Future<void> _setupSecureContext() async {
  try {
    final ByteData certData =
        await rootBundle.load('assets/certificates/isrgrootx1.pem');
    final List<int> certBytes = certData.buffer.asUint8List();
    SecurityContext.defaultContext.setTrustedCertificatesBytes(certBytes);
    logger.info('✅ Сертификат Let\'s Encrypt загружен');
  } catch (e) {
    logger.fatal('Не удалось загрузить корневой сертификат TLS', e);
    rethrow;
  }
}

void _initWindowsConsole() {
  try {
    if (Platform.isWindows) {
      Process.run('chcp', ['65001']).then((result) {}).catchError((error) {});
    }
  } catch (_) {}
}

void _showErrorDialog(String message) {
  if (Platform.isWindows) {
    try {
      Process.run('msg', ['*', 'Ошибка LogOnline:\n$message']);
    } catch (_) {}
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'LoggerFlutterClient',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          navigatorObservers: [ModalRouteObserver()],
        );
      },
    );
  }
}

class ModalRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is DialogRoute) {
      _isAnyModalOpen = true;
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is DialogRoute) {
      _isAnyModalOpen = false;
    }
  }
}
