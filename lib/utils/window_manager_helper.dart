import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowManagerHelper {
  static final WindowManagerHelper _instance = WindowManagerHelper._internal();
  factory WindowManagerHelper() => _instance;
  WindowManagerHelper._internal();

  bool _isInitialized = false;

  Future<void> initializeMainWindow() async {
    if (_isInitialized) return;

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: const Size(1200, 800),
      minimumSize: const Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    _isInitialized = true;
  }

  Future<void> showMainWindow() async {
    if (!_isInitialized) {
      await initializeMainWindow();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }
}
