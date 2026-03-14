Даваimport '../services/update_service.dart';

class UpdateRepository {
  const UpdateRepository();

  bool get isSupportedPlatform => UpdateService.isSupportedPlatform;
  String get currentVersion => UpdateService.currentVersion;
  String get currentPlatform => UpdateService.currentPlatform;

  Future<UpdateCheckResult> checkForUpdates() {
    return UpdateService.checkForUpdates();
  }

  Future<UpdateInstallResult> installUpdate(AppUpdateInfo update) {
    return UpdateService.downloadAndInstallUpdate(update);
  }
}
