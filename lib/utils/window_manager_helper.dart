import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowManagerHelper {
  static const Size _initialSize = Size(1500, 900);
  static const Size _minimumSize = Size(1280, 720);

  static final WindowManagerHelper _instance = WindowManagerHelper._internal();
  factory WindowManagerHelper() => _instance;
  WindowManagerHelper._internal();

  bool _isInitialized = false;

  Future<void> initializeMainWindow() async {
    if (_isInitialized) return;

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: _initialSize,
      minimumSize: _minimumSize,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setMinimumSize(_minimumSize);
      await windowManager.setSize(_initialSize);
      await windowManager.center();
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
