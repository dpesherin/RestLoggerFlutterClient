import 'package:flutter/foundation.dart';

import '../repositories/settings_repository.dart';
import '../repositories/update_repository.dart';
import '../services/update_service.dart';

class UpdateModalController extends ChangeNotifier {
  UpdateModalController({
    SettingsRepository? settingsRepository,
    UpdateRepository? updateRepository,
  })  : _settingsRepository = settingsRepository ?? const SettingsRepository(),
        _updateRepository = updateRepository ?? const UpdateRepository();

  final SettingsRepository _settingsRepository;
  final UpdateRepository _updateRepository;

  UpdateCheckResult? _result;
  bool _isLoading = false;
  bool _isInstalling = false;
  bool _autoCheckEnabled = true;
  String? _errorMessage;

  UpdateCheckResult? get result => _result;
  bool get isLoading => _isLoading;
  bool get isInstalling => _isInstalling;
  bool get autoCheckEnabled => _autoCheckEnabled;
  String? get errorMessage => _errorMessage;
  String get currentVersion => _updateRepository.currentVersion;
  String get currentPlatform => _updateRepository.currentPlatform;

  Future<void> initialize({
    required bool autoStartCheck,
    UpdateCheckResult? initialResult,
  }) async {
    _result = initialResult;
    _autoCheckEnabled = await _settingsRepository.getAutoCheckUpdates();
    notifyListeners();

    if (autoStartCheck) {
      await checkForUpdates();
    }
  }

  Future<void> toggleAutoCheck(bool value) async {
    _autoCheckEnabled = value;
    notifyListeners();
    await _settingsRepository.saveAutoCheckUpdates(value);
  }

  Future<bool> checkForUpdates({bool dismissIfNoUpdate = false}) async {
    if (_isLoading || _isInstalling) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _result = await _updateRepository.checkForUpdates();
      return !dismissIfNoUpdate || _result?.hasUpdate == true;
    } catch (e) {
      _errorMessage = 'Не удалось проверить обновления: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UpdateInstallResult> installUpdate() async {
    final update = _result?.updateInfo;
    if (update == null) {
      throw StateError('Нет доступного обновления для установки');
    }

    _isInstalling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _updateRepository.installUpdate(update);
    } catch (e) {
      _errorMessage = 'Не удалось установить обновление: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isInstalling = false;
      notifyListeners();
    }
  }
}
