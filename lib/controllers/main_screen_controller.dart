import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/message.dart';
import '../repositories/auth_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/update_repository.dart';
import '../services/api_service.dart';
import '../services/update_service.dart';
import '../services/websocket_service.dart';

enum MainSection { logs, apiDocs }

class MainScreenInitData {
  final bool autoCheckUpdates;

  const MainScreenInitData({
    required this.autoCheckUpdates,
  });
}

class MainScreenController extends ChangeNotifier {
  MainScreenController({
    WebSocketService? webSocketService,
    AuthRepository? authRepository,
    SessionRepository? sessionRepository,
    SettingsRepository? settingsRepository,
    UpdateRepository? updateRepository,
  })  : _wsService = webSocketService ?? WebSocketService(),
        _authRepository = authRepository ?? const AuthRepository(),
        _sessionRepository = sessionRepository ?? const SessionRepository(),
        _settingsRepository = settingsRepository ?? const SettingsRepository(),
        _updateRepository = updateRepository ?? const UpdateRepository();

  final WebSocketService _wsService;
  final AuthRepository _authRepository;
  final SessionRepository _sessionRepository;
  final SettingsRepository _settingsRepository;
  final UpdateRepository _updateRepository;

  List<Message> _messages = <Message>[];
  bool _isConnected = false;
  bool _isLoading = true;
  String? _consumerKey;
  String? _username;
  ConnectionStatus _connectionStatus = const ConnectionStatus(
    isConnected: false,
    isReconnecting: false,
    reconnectAttempts: 0,
    maxReconnectAttempts: WebSocketService.maxReconnectAttempts,
    totalReconnects: 0,
  );
  AuthStatusInfo _authStatus = const AuthStatusInfo(
    isAuthenticated: false,
    latencyMs: 0,
    message: 'Статус не загружен',
  );
  bool _isLoggingOut = false;
  bool _isCheckingAuth = false;
  bool _showFAB = false;
  bool _searchPanelOpen = false;
  bool _isCheckingUpdates = false;
  int _currentMatchIndex = -1;
  MainSection _currentSection = MainSection.logs;
  final List<Message> _matchedMessages = <Message>[];
  final Map<int, int> _messageMatchCount = <int, int>{};
  String _searchQuery = '';
  String _findQuery = '';

  List<Message> get messages => _messages;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get consumerKey => _consumerKey;
  String? get username => _username;
  ConnectionStatus get connectionStatus => _connectionStatus;
  AuthStatusInfo get authStatus => _authStatus;
  bool get isLoggingOut => _isLoggingOut;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get showFAB => _showFAB;
  bool get searchPanelOpen => _searchPanelOpen;
  bool get isCheckingUpdates => _isCheckingUpdates;
  int get currentMatchIndex => _currentMatchIndex;
  MainSection get currentSection => _currentSection;
  List<Message> get matchedMessages => _matchedMessages;
  Map<int, int> get messageMatchCount => _messageMatchCount;
  WebSocketService get wsService => _wsService;
  UpdateRepository get updateRepository => _updateRepository;

  List<Message> get filteredMessages {
    final query = _searchQuery.toLowerCase().trim();
    if (query.isEmpty) return _messages;
    return _messages
        .where((msg) => msg.moduleName.toLowerCase().contains(query))
        .toList();
  }

  List<Message> get pinnedMessages =>
      filteredMessages.where((msg) => msg.isPinned).toList();

  List<Message> get unpinnedMessages =>
      filteredMessages.where((msg) => !msg.isPinned).toList();

  Future<MainScreenInitData> initialize() async {
    try {
      final user = await _authRepository.getStoredUser();
      final key = await _authRepository.getStoredConsumerKey();
      final authStatus = await _authRepository.getAuthStatusInfo();
      final autoCheckUpdates = await _settingsRepository.getAutoCheckUpdates();

      _username = user?.login;
      _consumerKey = key;
      _authStatus = authStatus;
      _isLoading = false;
      notifyListeners();

      return MainScreenInitData(autoCheckUpdates: autoCheckUpdates);
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return const MainScreenInitData(autoCheckUpdates: false);
    }
  }

  void connectWebSocket({
    required void Function() onConnected,
  }) {
    _wsService.connect(
      onMessage: handleNewMessage,
      onConnectionChange: (connected) {
        _isConnected = connected;
        notifyListeners();
        if (connected) {
          refreshAuthStatus();
          onConnected();
        }
      },
      onStatusChange: (status) {
        _connectionStatus = status;
        notifyListeners();
      },
    );
  }

  void disconnectWebSocket() {
    _wsService.disconnect();
  }

  void reconnectWebSocket() {
    _wsService.reconnect();
  }

  void handleNewMessage(Message message) {
    _messages = <Message>[message, ..._messages];
    if (_messages.length > 500) {
      _messages = _messages.take(500).toList();
    }
    notifyListeners();
  }

  void togglePin(Message message) {
    message.isPinned = !message.isPinned;
    if (message.isPinned) {
      message.pinnedAt = DateTime.now().millisecondsSinceEpoch;
    }
    notifyListeners();
  }

  void clearMessages() {
    _messages = <Message>[];
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setFindQuery(String value) {
    _findQuery = value;
    _performTextSearch();
  }

  void updateScrollOffset(double offset, {required bool hasClients}) {
    final shouldShow = hasClients && offset > 300;
    if (shouldShow != _showFAB) {
      _showFAB = shouldShow;
      notifyListeners();
    }
  }

  void selectSection(MainSection section) {
    if (_currentSection == section) return;
    _currentSection = section;
    notifyListeners();
  }

  void openSearchPanel() {
    _searchPanelOpen = true;
    notifyListeners();
  }

  void closeSearchPanel() {
    _searchPanelOpen = false;
    _findQuery = '';
    _matchedMessages.clear();
    _currentMatchIndex = -1;
    notifyListeners();
  }

  void goToNextMatch() {
    if (_matchedMessages.isEmpty) return;
    _currentMatchIndex = (_currentMatchIndex + 1) % _matchedMessages.length;
    notifyListeners();
  }

  void goToPreviousMatch() {
    if (_matchedMessages.isEmpty) return;
    _currentMatchIndex = (_currentMatchIndex - 1 + _matchedMessages.length) %
        _matchedMessages.length;
    notifyListeners();
  }

  void markCheckingUpdates(bool value) {
    _isCheckingUpdates = value;
    notifyListeners();
  }

  Future<UpdateCheckResult?> runAutoUpdateCheck() async {
    if (_isCheckingUpdates || !_updateRepository.isSupportedPlatform) {
      return null;
    }

    _isCheckingUpdates = true;
    notifyListeners();

    try {
      final result = await _updateRepository.checkForUpdates();
      return result.hasUpdate ? result : null;
    } catch (_) {
      return null;
    } finally {
      _isCheckingUpdates = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuth() async {
    return _authRepository.checkAuth();
  }

  Future<void> refreshAuthStatus() async {
    _authStatus = await _authRepository.getAuthStatusInfo();
    notifyListeners();
  }

  Future<void> setLoggingOut(bool value) async {
    _isLoggingOut = value;
    notifyListeners();
  }

  void setCheckingAuth(bool value) {
    _isCheckingAuth = value;
    notifyListeners();
  }

  Future<void> logout() => _authRepository.logout();
  Future<void> logoutAll() => _authRepository.logoutAll();
  Future<bool> terminateSession(String sessionId) =>
      _sessionRepository.terminateSession(sessionId);

  void _performTextSearch() {
    final query = _findQuery.toLowerCase().trim();
    _messageMatchCount.clear();
    _matchedMessages.clear();
    _currentMatchIndex = -1;

    if (query.isEmpty) {
      notifyListeners();
      return;
    }

    for (int i = 0; i < filteredMessages.length; i++) {
      final msg = filteredMessages[i];
      final content = msg.displayContent.toLowerCase();
      int matchCount = 0;
      int startIdx = 0;

      while ((startIdx = content.indexOf(query, startIdx)) != -1) {
        matchCount++;
        startIdx += query.length;
      }

      if (matchCount > 0) {
        _messageMatchCount[i] = matchCount;
        for (int j = 0; j < matchCount; j++) {
          _matchedMessages.add(msg);
        }
      }
    }

    if (_matchedMessages.isNotEmpty) {
      _currentMatchIndex = 0;
    }

    notifyListeners();
  }
}
