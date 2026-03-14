import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class SettingsRepository {
  const SettingsRepository();

  Future<void> saveThemeMode(ThemeMode mode) {
    return StorageService.saveThemeMode(mode);
  }

  Future<ThemeMode?> getThemeMode() {
    return StorageService.getThemeMode();
  }

  Future<void> saveAutoCheckUpdates(bool enabled) {
    return StorageService.saveAutoCheckUpdates(enabled);
  }

  Future<bool> getAutoCheckUpdates() {
    return StorageService.getAutoCheckUpdates();
  }
}
