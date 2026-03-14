import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  fatal(4);

  const LogLevel(this.value);
  final int value;
}

class FileLogger {
  static final FileLogger _instance = FileLogger._internal();
  factory FileLogger() => _instance;
  FileLogger._internal();

  static FileLogger get instance => _instance;

  File? _logFile;
  bool _initialized = false;
  LogLevel _minLevel = LogLevel.debug;

  static const String logFileName = 'logonline_log.txt';
  static const int maxLogSize = 5 * 1024 * 1024;

  Future<void> init({LogLevel minLevel = LogLevel.debug}) async {
    if (_initialized) return;

    _minLevel = minLevel;

    try {
      Directory? logsDir;

      if (Platform.isWindows) {
        final appDataDir = await getApplicationSupportDirectory();
        logsDir = Directory('${appDataDir.path}\\logs');
      } else if (Platform.isMacOS) {
        final homeDir = await getApplicationSupportDirectory();
        logsDir = Directory('${homeDir.path}/logs');
      } else {
        final tempDir = await getTemporaryDirectory();
        logsDir = Directory('${tempDir.path}/logs');
      }

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _logFile = File('${logsDir.path}${Platform.pathSeparator}$logFileName');

      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > maxLogSize) {
          await _rotateLog();
        }
      }

      _initialized = true;

      _writeToFile('=' * 50, LogLevel.info);
      _writeToFile('🚀 LogOnline запущен', LogLevel.info);
      _writeToFile(
          '📱 Платформа: ${Platform.operatingSystem} ${Platform.version}',
          LogLevel.info);
      _writeToFile(
          '🕐 Время: ${DateTime.now().toIso8601String()}', LogLevel.info);
      _writeToFile('=' * 50, LogLevel.info);
    } catch (e, stackTrace) {
      _writeFallbackError('Failed to initialize file logger', e, stackTrace);
    }
  }

  Future<void> _rotateLog() async {
    if (_logFile == null) return;

    try {
      final rotatedFile = File('${_logFile!.path}.old');
      if (await rotatedFile.exists()) {
        await rotatedFile.delete();
      }
      await _logFile!.rename(rotatedFile.path);
    } catch (e, stackTrace) {
      _writeFallbackError('Failed to rotate log file', e, stackTrace);
    }
  }

  void _writeToFile(String message, LogLevel level) {
    if (!_initialized || _logFile == null) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      final levelStr = _levelToString(level);
      final logLine = '[$timestamp] [$levelStr] $message\n';

      _logFile!.writeAsStringSync(
        logLine,
        mode: FileMode.append,
        flush: true,
      );
    } catch (e, stackTrace) {
      _writeFallbackError('Failed to write log entry', e, stackTrace);
    }
  }

  String _levelToString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO ';
      case LogLevel.warning:
        return 'WARN ';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }

  void debug(String message) {
    if (_minLevel.value <= LogLevel.debug.value) {
      _writeToFile(message, LogLevel.debug);
    }
  }

  void info(String message) {
    if (_minLevel.value <= LogLevel.info.value) {
      _writeToFile(message, LogLevel.info);
    }
  }

  void warning(String message) {
    if (_minLevel.value <= LogLevel.warning.value) {
      _writeToFile(message, LogLevel.warning);
    }
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_minLevel.value <= LogLevel.error.value) {
      final fullMessage = StringBuffer(message);

      if (error != null) {
        fullMessage.writeln();
        fullMessage.writeln('Ошибка: $error');
      }

      if (stackTrace != null) {
        fullMessage.writeln('Стек:');
        fullMessage
            .writeln(stackTrace.toString().split('\n').take(10).join('\n'));
      }

      _writeToFile(fullMessage.toString(), LogLevel.error);
    }
  }

  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _writeToFile(message, LogLevel.fatal);

    if (_logFile != null) {
      try {
        _logFile!.writeAsStringSync('', mode: FileMode.append);
      } catch (e, stackTrace) {
        _writeFallbackError('Failed to flush fatal log entry', e, stackTrace);
      }
    }
  }

  Future<String?> getLogContent() async {
    if (_logFile == null || !await _logFile!.exists()) return null;
    return await _logFile!.readAsString();
  }

  Future<String?> getLogPath() async {
    return _logFile?.path;
  }

  Future<void> clearLog() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString('');
    }
  }

  Future<String?> getWindowsLogPath() async {
    if (!Platform.isWindows) return null;

    try {
      final appDataDir = await getApplicationSupportDirectory();
      final logDir = Directory('${appDataDir.path}\\logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final logFile =
          File('${logDir.path}${Platform.pathSeparator}$logFileName');
      return logFile.path;
    } catch (e) {
      _writeFallbackError('Failed to resolve Windows log path', e, null);
      return null;
    }
  }

  Future<void> openLogsFolder() async {
    if (!Platform.isWindows) return;

    try {
      final path = await getWindowsLogPath();
      if (path != null) {
        final dir = File(path).parent;
        await Process.run('explorer', [dir.path]);
      }
    } catch (e, stackTrace) {
      _writeFallbackError('Failed to open logs folder', e, stackTrace);
    }
  }

  void _writeFallbackError(
    String message,
    Object error,
    StackTrace? stackTrace,
  ) {
    stderr.writeln('[LOGGER_FALLBACK] $message: $error');
    if (stackTrace != null) {
      stderr.writeln(stackTrace.toString().split('\n').take(5).join('\n'));
    }
  }
}

final logger = FileLogger.instance;
