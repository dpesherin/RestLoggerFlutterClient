import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/config.dart';
import '../utils/logger.dart';

class AppUpdateInfo {
  final String version;
  final int buildNumber;
  final String channel;
  final bool mandatory;
  final String downloadUrl;
  final String fileName;
  final String? notes;
  final String? publishedAt;

  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.channel,
    required this.mandatory,
    required this.downloadUrl,
    required this.fileName,
    this.notes,
    this.publishedAt,
  });

  String get fullVersion => '$version+$buildNumber';

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version']?.toString() ?? '0.0.0',
      buildNumber: _parseInt(json['buildNumber']) ?? 0,
      channel: json['channel']?.toString() ?? 'stable',
      mandatory: json['mandatory'] == true,
      downloadUrl: json['downloadUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      notes: json['notes']?.toString(),
      publishedAt: json['publishedAt']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class UpdateCheckResult {
  final bool isSupportedPlatform;
  final bool hasUpdate;
  final AppUpdateInfo? updateInfo;
  final String currentVersion;
  final String currentPlatform;

  const UpdateCheckResult({
    required this.isSupportedPlatform,
    required this.hasUpdate,
    required this.currentVersion,
    required this.currentPlatform,
    this.updateInfo,
  });
}

class UpdateInstallResult {
  final bool started;
  final String message;

  const UpdateInstallResult({
    required this.started,
    required this.message,
  });
}

class UpdateService {
  static const Duration _timeout = Duration(seconds: 12);

  static bool get isSupportedPlatform => Platform.isWindows || Platform.isMacOS;

  static String get currentPlatform {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return 'unsupported';
  }

  static String get currentVersion => AppConfig.fullVersion;

  static Future<UpdateCheckResult> checkForUpdates() async {
    if (!isSupportedPlatform) {
      return UpdateCheckResult(
        isSupportedPlatform: false,
        hasUpdate: false,
        currentVersion: AppConfig.fullVersion,
        currentPlatform: 'unsupported',
      );
    }

    final uri = Uri.parse(
      '${AppConfig.updaterBaseUrl}/api/v1/releases/$currentPlatform/latest',
    ).replace(queryParameters: {
      'channel': 'stable',
      'currentVersion': currentVersion,
    });

    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw HttpException(
        'Update server returned ${response.statusCode}',
        uri: uri,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid update response format');
    }

    final updateInfo = AppUpdateInfo.fromJson(decoded);
    return UpdateCheckResult(
      isSupportedPlatform: true,
      hasUpdate: _isNewerVersion(updateInfo),
      updateInfo: updateInfo,
      currentVersion: currentVersion,
      currentPlatform: currentPlatform,
    );
  }

  static Future<UpdateInstallResult> downloadAndInstallUpdate(
    AppUpdateInfo update,
  ) async {
    if (!isSupportedPlatform) {
      return const UpdateInstallResult(
        started: false,
        message: 'Обновления поддерживаются только на Windows и macOS',
      );
    }

    final workingDir = await Directory.systemTemp.createTemp(
      'logger_flutter_update_',
    );
    final packageFile = File('${workingDir.path}${Platform.pathSeparator}${update.fileName}');

    await _downloadFile(update.downloadUrl, packageFile);

    if (Platform.isWindows) {
      await _startWindowsInstaller(packageFile);
      return const UpdateInstallResult(
        started: true,
        message: 'Установщик обновления запущен. Приложение будет закрыто и перезапущено.',
      );
    }

    await _startMacOsInstaller(packageFile);
    return const UpdateInstallResult(
      started: true,
      message: 'Обновление для macOS запущено. Приложение будет закрыто и перезапущено.',
    );
  }

  static Future<void> _downloadFile(String url, File targetFile) async {
    final uri = Uri.parse(url);
    final request = http.Request('GET', uri);
    final response = await request.send().timeout(_timeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'Не удалось скачать обновление: ${response.statusCode}',
        uri: uri,
      );
    }

    await targetFile.parent.create(recursive: true);
    final sink = targetFile.openWrite();
    await response.stream.pipe(sink);
    await sink.flush();
    await sink.close();
  }

  static Future<void> _startWindowsInstaller(File installerFile) async {
    final scriptFile = File(
      '${installerFile.parent.path}${Platform.pathSeparator}run_update.ps1',
    );
    final logFile = File(
      '${installerFile.parent.path}${Platform.pathSeparator}update.log',
    );
    final currentPid = pid;
    final currentExe = Platform.resolvedExecutable.replaceAll("'", "''");
    final installerPath = installerFile.path.replaceAll("'", "''");
    final logPath = logFile.path.replaceAll("'", "''");
    final script = '''
\$ErrorActionPreference = 'Stop'
\$installerPath = '$installerPath'
\$targetExe = '$currentExe'
\$pidToWait = $currentPid
\$logFile = '$logPath'

function Write-UpdateLog {
  param([string]\$message)
  \$timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fff'
  Add-Content -Path \$logFile -Value "[\$timestamp] \$message"
}

Write-UpdateLog "Windows updater script started"
Write-UpdateLog "Installer path: \$installerPath"
Write-UpdateLog "Target exe: \$targetExe"
Write-UpdateLog "Waiting for PID \$pidToWait to exit"

try {
  while (Get-Process -Id \$pidToWait -ErrorAction SilentlyContinue) {
    Start-Sleep -Milliseconds 500
  }

  Write-UpdateLog "Main app exited, starting installer"
  \$installerProcess = Start-Process -FilePath \$installerPath -ArgumentList '/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Verb RunAs -Wait -PassThru
  Write-UpdateLog "Installer finished with exit code: \$((\$installerProcess | Select-Object -ExpandProperty ExitCode))"

  if (Test-Path \$targetExe) {
    Write-UpdateLog "Restarting app"
    Start-Process -FilePath \$targetExe
  } else {
    Write-UpdateLog "Target exe not found after install"
  }
} catch {
  Write-UpdateLog "Updater failed: \$(\$PSItem.Exception.Message)"
  Write-UpdateLog "Stack: \$(\$PSItem.ScriptStackTrace)"
  throw
}
''';

    await scriptFile.writeAsString(script);

    await logFile.writeAsString(
      '[${DateTime.now().toIso8601String()}] Prepared Windows updater files\n',
    );

    final powerShellPath = _resolveWindowsPowerShellPath();

    await Process.start(
      'cmd.exe',
      [
        '/c',
        'start',
        '""',
        '/min',
        powerShellPath,
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
      ],
      mode: ProcessStartMode.detached,
    );

    logger.info(
      'Запущен Windows updater: ${scriptFile.path} (log: ${logFile.path}, shell: $powerShellPath)',
    );
  }

  static String _resolveWindowsPowerShellPath() {
    final systemRoot = Platform.environment['SystemRoot'];
    if (systemRoot != null && systemRoot.isNotEmpty) {
      return '$systemRoot\\System32\\WindowsPowerShell\\v1.0\\powershell.exe';
    }

    return 'powershell.exe';
  }

  static Future<void> _startMacOsInstaller(File dmgFile) async {
    final currentAppBundle = _currentMacOsAppBundlePath();
    final mountDir =
        '${dmgFile.parent.path}${Platform.pathSeparator}mount_point';
    final scriptFile = File(
      '${dmgFile.parent.path}${Platform.pathSeparator}run_update.sh',
    );
    final logFile = File(
      '${dmgFile.parent.path}${Platform.pathSeparator}update.log',
    );
    final escapedDmg = _shellEscape(dmgFile.path);
    final escapedMount = _shellEscape(mountDir);
    final escapedTarget = _shellEscape(currentAppBundle.path);
    final escapedLogFile = _shellEscape(logFile.path);

    final script = '''#!/bin/bash
set -euo pipefail

APP_PID=$pid
DMG_PATH=$escapedDmg
MOUNT_DIR=$escapedMount
TARGET_APP=$escapedTarget
TMP_APP="\${TARGET_APP}.new"
BACKUP_APP="\${TARGET_APP}.backup"
LOG_FILE=$escapedLogFile

exec > >(tee -a "\$LOG_FILE") 2>&1

cleanup() {
  /usr/bin/hdiutil detach "\$MOUNT_DIR" -quiet >/dev/null 2>&1 || true
}

trap cleanup EXIT

while kill -0 "\$APP_PID" 2>/dev/null; do
  sleep 0.5
done

mkdir -p "\$MOUNT_DIR"
/bin/rm -rf "\$TMP_APP" "\$BACKUP_APP"
/usr/bin/hdiutil attach "\$DMG_PATH" -nobrowse -quiet -mountpoint "\$MOUNT_DIR"
SOURCE_APP=\$(/usr/bin/find "\$MOUNT_DIR" -maxdepth 1 -type d -name "*.app" -print -quit)

if [ -z "\$SOURCE_APP" ]; then
  echo "Source app not found inside mounted DMG"
  exit 1
fi

/usr/bin/ditto "\$SOURCE_APP" "\$TMP_APP"

if [ ! -d "\$TMP_APP" ]; then
  echo "Temporary updated app was not created"
  exit 1
fi

if [ -d "\$TARGET_APP" ]; then
  /bin/mv "\$TARGET_APP" "\$BACKUP_APP"
fi

if ! /bin/mv "\$TMP_APP" "\$TARGET_APP"; then
  echo "Failed to move updated app into place"
  if [ -d "\$BACKUP_APP" ]; then
    /bin/mv "\$BACKUP_APP" "\$TARGET_APP" || true
  fi
  exit 1
fi

/bin/rm -rf "\$BACKUP_APP"
/usr/bin/xattr -dr com.apple.quarantine "\$TARGET_APP" >/dev/null 2>&1 || true
/usr/bin/open "\$TARGET_APP"
''';

    await scriptFile.writeAsString(script);
    await Process.run('chmod', ['+x', scriptFile.path]);

    final command = '/bin/bash ${_shellEscape(scriptFile.path)}';
    await Process.start(
      'osascript',
      [
        '-e',
        'do shell script "${_appleScriptEscape(command)}" with administrator privileges',
      ],
      mode: ProcessStartMode.detached,
    );

    logger.info('Запущен macOS updater: ${scriptFile.path}');
  }

  static Directory _currentMacOsAppBundlePath() {
    final executable = File(Platform.resolvedExecutable);
    final macOsDir = executable.parent;
    final contentsDir = macOsDir.parent;
    final appDir = contentsDir.parent;

    if (!appDir.path.endsWith('.app')) {
      throw const FileSystemException(
        'Не удалось определить путь до .app bundle',
      );
    }

    return appDir;
  }

  static bool _isNewerVersion(AppUpdateInfo remote) {
    final localVersionParts = _parseVersion(AppConfig.appVersion);
    final remoteVersionParts = _parseVersion(remote.version);

    for (var i = 0; i < 3; i++) {
      final local = i < localVersionParts.length ? localVersionParts[i] : 0;
      final next = i < remoteVersionParts.length ? remoteVersionParts[i] : 0;
      if (next > local) return true;
      if (next < local) return false;
    }

    return remote.buildNumber > int.parse(AppConfig.appBuildNumber);
  }

  static List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList(growable: false);
  }

  static String _shellEscape(String value) {
    return "'${value.replaceAll("'", "'\"'\"'")}'";
  }

  static String _appleScriptEscape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"');
  }
}
