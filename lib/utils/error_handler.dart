import 'dart:async';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  static bool _initialized = false;
  static final List<Zone> _zones = [];

  static void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (FlutterErrorDetails details) {
      if (_isIgnorableError(details.exception, details.stack)) {
        _logSuppressedError(details.exception);
        return;
      }

      if (kReleaseMode) {
        _logError(details.exception, details.stack);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (_isIgnorableError(error, stack)) {
        _logSuppressedError(error);
        return true;
      }

      if (kReleaseMode) {
        _logError(error, stack);
      } else {}
      return false;
    };

    _createErrorZone();
  }

  static void _createErrorZone() {
    final zone = Zone.current.fork(
      specification: ZoneSpecification(
        handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone,
            Object error, StackTrace stack) {
          if (_isIgnorableError(error, stack)) {
            _logSuppressedError(error);
            return;
          }

          if (kReleaseMode) {
            _logError(error, stack);
          } else {}
        },
      ),
    );

    _zones.add(zone);
    zone.run(() {});
  }

  static bool _isIgnorableError(Object error, StackTrace? stack) {
    final errorStr = error.toString().toLowerCase();
    final stackStr = stack?.toString().toLowerCase() ?? '';

    final ignorablePatterns = [
      'rangeerror',
      'invalid value: only valid value is 0: 1',
      'parseqs',
      'socket_io_client',
      'socket.io',
      'websocket',
      'web_socket',
    ];

    for (final pattern in ignorablePatterns) {
      if (errorStr.contains(pattern) || stackStr.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  static void _logSuppressedError(Object error) {
    if (kDebugMode) {}
  }

  static void _logError(Object error, StackTrace? stack) {
    if (stack != null) {}
  }

  static Future<T> guardAsync<T>(Future<T> Function() callback) async {
    try {
      return await callback();
    } catch (e, stack) {
      if (_isIgnorableError(e, stack)) {
        _logSuppressedError(e);
        return _defaultValue<T>();
      }
      rethrow;
    }
  }

  static T guardSync<T>(T Function() callback) {
    try {
      return callback();
    } catch (e, stack) {
      if (_isIgnorableError(e, stack)) {
        _logSuppressedError(e);
        return _defaultValue<T>();
      }
      rethrow;
    }
  }

  static T _defaultValue<T>() {
    if (T == dynamic) {
      return null as T;
    }
    if (T == bool) {
      return false as T;
    }
    if (T == int) {
      return 0 as T;
    }
    if (T == double) {
      return 0.0 as T;
    }
    if (T == String) {
      return '' as T;
    }
    if (T == List) {
      return [] as T;
    }
    if (T == Map) {
      return {} as T;
    }
    return null as T;
  }

  static T suppressAll<T>(T Function() callback) {
    try {
      return callback();
    } catch (e) {
      _logSuppressedError(e);
      return _defaultValue<T>();
    }
  }

  static Future<T> suppressAllAsync<T>(Future<T> Function() callback) async {
    try {
      return await callback();
    } catch (e) {
      _logSuppressedError(e);
      return _defaultValue<T>();
    }
  }
}

extension ErrorHandlerExtension on Function {
  Future<T> guardAsync<T>() =>
      ErrorHandler.guardAsync(() => this() as Future<T>);
  T guardSync<T>() => ErrorHandler.guardSync(() => this() as T);
}

T suppressErrors<T>(T Function() callback) {
  return ErrorHandler.suppressAll(callback);
}

Future<T> suppressErrorsAsync<T>(Future<T> Function() callback) {
  return ErrorHandler.suppressAllAsync(callback);
}
