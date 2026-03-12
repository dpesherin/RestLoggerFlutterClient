import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/update_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../utils/config.dart';
import '../utils/logger.dart';
import '../widgets/message_card.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/key_modal.dart';
import '../widgets/sessions_modal.dart';
import '../widgets/connection_status_modal.dart';
import '../widgets/toast_widget.dart';
import '../widgets/update_modal.dart';
import 'login_screen.dart';

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

class _CloseSearchIntent extends Intent {
  const _CloseSearchIntent();
}

class _NextMatchIntent extends Intent {
  const _NextMatchIntent();
}

class _PreviousMatchIntent extends Intent {
  const _PreviousMatchIntent();
}

Map<String, bool> _modalOpenState = {
  'keyModal': false,
  'sessionsModal': false,
  'connectionStatusModal': false,
  'updateModal': false,
};

Future<T?> showModalWithGuard<T>(
  BuildContext context,
  String modalType,
  Widget modal, {
  bool barrierDismissible = true,
}) async {
  if (_modalOpenState[modalType] == true) {
    return null;
  }

  _modalOpenState[modalType] = true;

  try {
    final result = await showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => PopScope(
        onPopInvokedWithResult: (_, __) {
          _modalOpenState[modalType] = false;
        },
        child: modal,
      ),
    );

    return result;
  } finally {
    _modalOpenState[modalType] = false;
  }
}

class _AppLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResume;

  _AppLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final WebSocketService _wsService = WebSocketService();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _findController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();

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
  bool _isInstallingUpdate = false;
  int _currentMatchIndex = -1;
  final List<Message> _matchedMessages = [];
  final Map<int, int> _messageMatchCount = {};
  UpdateCheckResult? _lastUpdateResult;
  late _AppLifecycleObserver _lifecycleObserver;
  Timer? _searchDebounce;
  Timer? _findDebounce;

  @override
  void initState() {
    super.initState();
    _initData();
    _connectWebSocket();

    _lifecycleObserver = _AppLifecycleObserver(onResume: _checkAuthAndRedirect);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
      _checkForUpdates(silentIfCurrent: true);
    });

    _scrollController.addListener(() {
      final shouldShow =
          _scrollController.hasClients && _scrollController.offset > 300;
      if (shouldShow != _showFAB) {
        setState(() => _showFAB = shouldShow);
      }
    });

    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() {});
      });
    });

    _findController.addListener(() {
      if (_findDebounce?.isActive ?? false) _findDebounce?.cancel();
      _findDebounce = Timer(const Duration(milliseconds: 200), () {
        if (mounted) _performTextSearch();
      });
    });
  }

  Future<void> _initData() async {
    try {
      final user = await StorageService.getUser();
      final key = await StorageService.getConsumerKey();
      final authStatus = await ApiService.getAuthStatusInfo();

      if (mounted) {
        setState(() {
          _username = user?.login;
          _consumerKey = key;
          _authStatus = authStatus;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkForUpdates({required bool silentIfCurrent}) async {
    if (_isCheckingUpdates || !UpdateService.isSupportedPlatform) return;

    setState(() {
      _isCheckingUpdates = true;
    });

    try {
      final result = await UpdateService.checkForUpdates();
      if (!mounted) return;

      setState(() {
        _lastUpdateResult = result;
      });

      if (result.hasUpdate) {
        await _showUpdateModal(result);
      } else if (!silentIfCurrent) {
        ToastWidget.show(
          context,
          message: 'Установлена актуальная версия ${result.currentVersion}',
          type: ToastType.info,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (!silentIfCurrent) {
        ToastWidget.show(
          context,
          message: 'Не удалось проверить обновления: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdates = false;
        });
      }
    }
  }

  Future<void> _showUpdateModal(UpdateCheckResult result) async {
    await showModalWithGuard(
      context,
      'updateModal',
      UpdateModal(
        result: result,
        onInstall: () async {
          final update = result.updateInfo;
          if (update == null) return;

          if (!mounted) return;

          setState(() {
            _isInstallingUpdate = true;
          });

          try {
            final installResult =
                await UpdateService.downloadAndInstallUpdate(update);

            if (!mounted) return;

            ToastWidget.show(
              context,
              message: installResult.message,
              type: installResult.started
                  ? ToastType.success
                  : ToastType.warning,
            );

            if (installResult.started) {
              Navigator.of(context).pop();
              await Future<void>.delayed(const Duration(milliseconds: 500));
              exit(0);
            }
          } catch (e) {
            if (!mounted) return;
            ToastWidget.show(
              context,
              message: 'Не удалось установить обновление: $e',
              type: ToastType.error,
            );
          } finally {
            if (mounted) {
              setState(() {
                _isInstallingUpdate = false;
              });
            }
          }
        },
      ),
      barrierDismissible: !(result.updateInfo?.mandatory ?? false),
    );
  }

  void _connectWebSocket() {
    _wsService.connect(
      onMessage: _handleNewMessage,
      onConnectionChange: (connected) {
        if (mounted) {
          setState(() => _isConnected = connected);
          if (connected) {
            _refreshAuthStatus();
            ToastWidget.show(
              context,
              message: 'Подключено к серверу',
              type: ToastType.success,
            );
          }
        }
      },
      onStatusChange: (status) {
        if (mounted) {
          setState(() {
            _connectionStatus = status;
          });
        }
      },
    );
  }

  void _handleNewMessage(Message message) {
    if (!mounted) return;

    setState(() {
      _messages.insert(0, message);
      if (_messages.length > 500) _messages.removeLast();
    });
  }

  List<Message> get _filteredMessages {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _messages;
    return _messages
        .where((msg) => msg.moduleName.toLowerCase().contains(query))
        .toList();
  }

  List<Message> get _pinnedMessages =>
      _filteredMessages.where((msg) => msg.isPinned).toList();
  List<Message> get _unpinnedMessages =>
      _filteredMessages.where((msg) => !msg.isPinned).toList();

  void _togglePin(Message message) {
    setState(() {
      message.isPinned = !message.isPinned;
      if (message.isPinned) {
        message.pinnedAt = DateTime.now().millisecondsSinceEpoch;
      }
    });

    ToastWidget.show(
      context,
      message:
          message.isPinned ? 'Сообщение закреплено' : 'Сообщение откреплено',
      type: message.isPinned ? ToastType.success : ToastType.info,
    );
  }

  List<Widget> _buildMessageList() {
    final List<Widget> widgets = [];

    for (final msg in _pinnedMessages) {
      final isCurrentMatch = _matchedMessages.isNotEmpty &&
          _matchedMessages[_currentMatchIndex] == msg;
      widgets.add(MessageCard(
        message: msg,
        onPinToggle: () => _togglePin(msg),
        highlightText: _findController.text.isNotEmpty && isCurrentMatch
            ? _findController.text
            : (_findController.text.isNotEmpty &&
                    msg.displayContent
                        .toLowerCase()
                        .contains(_findController.text.toLowerCase())
                ? _findController.text
                : null),
        isCurrentMatch: isCurrentMatch,
      ));
    }

    if (_pinnedMessages.isNotEmpty && _unpinnedMessages.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFF5A8FEC),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Новые',
                style: TextStyle(
                  color: Color(0xFF5A8FEC),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFF5A8FEC),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ));
    }

    for (final msg in _unpinnedMessages) {
      final isCurrentMatch = _matchedMessages.isNotEmpty &&
          _matchedMessages[_currentMatchIndex] == msg;
      widgets.add(MessageCard(
        message: msg,
        onPinToggle: () => _togglePin(msg),
        highlightText: _findController.text.isNotEmpty && isCurrentMatch
            ? _findController.text
            : (_findController.text.isNotEmpty &&
                    msg.displayContent
                        .toLowerCase()
                        .contains(_findController.text.toLowerCase())
                ? _findController.text
                : null),
        isCurrentMatch: isCurrentMatch,
      ));
    }

    return widgets;
  }

  void _clearAllMessages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все сообщения?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _messages.clear());
              Navigator.pop(context);
              ToastWidget.show(
                context,
                message: 'Все сообщения удалены',
                type: ToastType.success,
              );
            },
            child: const Text(
              'Очистить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _copyAllMessages() {
    if (_messages.isEmpty) {
      ToastWidget.show(context,
          message: 'Нет сообщений для копирования', type: ToastType.info);
      return;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < _messages.length; i++) {
      buffer.writeln(
          '--- Сообщение ${i + 1} ---\n${_messages[i].displayContent}\n');
    }

    FlutterClipboard.copy(buffer.toString()).then((_) {
      if (!mounted) {
        return;
      }
      ToastWidget.show(context,
          message: 'Все сообщения скопированы', type: ToastType.success);
    }).catchError((_) {
      if (!mounted) {
        return;
      }
      ToastWidget.show(context,
          message: 'Ошибка копирования', type: ToastType.error);
    });
  }

  void _showKeyModal() {
    showModalWithGuard(
      context,
      'keyModal',
      KeyModal(
        consumerKey: _consumerKey,
        username: _username,
        onLogout: _logout,
        onShowSessions: _showSessionsModal,
      ),
    );
  }

  Future<void> _showSessionsModal() async {
    final isAuth = await ApiService.checkAuth();
    if (!isAuth && mounted) {
      _redirectToLogin();
      return;
    }

    if (!mounted) return;

    showModalWithGuard(
      context,
      'sessionsModal',
      SessionsModal(
        onLogoutAll: _logoutAll,
        onTerminateSession: _terminateSession,
      ),
    );
  }

  Future<void> _showConnectionStatusModal() async {
    await _refreshAuthStatus();

    if (!mounted) return;

    showModalWithGuard(
      context,
      'connectionStatusModal',
      ConnectionStatusModal(
        connectionStatus: _connectionStatus,
        authStatus: _authStatus,
        onReconnect: () {
          Navigator.pop(context);
          _wsService.reconnect();
        },
      ),
    );
  }

  Future<void> _openDocs() async {
    final Uri url = Uri.parse(AppConfig.docsUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) {
          return;
        }
        ToastWidget.show(context,
            message: 'Не удалось открыть браузер', type: ToastType.error);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ToastWidget.show(context,
          message: 'Ошибка при открытии браузера', type: ToastType.error);
    }
  }

  Future<void> _checkAuthAndRedirect() async {
    if (_isCheckingAuth || !mounted) return;

    _isCheckingAuth = true;
    try {
      final isAuth = await ApiService.checkAuth();
      if (!isAuth && mounted) _redirectToLogin();
    } catch (e) {
      logger.error('Error checking auth', e);
    } finally {
      _isCheckingAuth = false;
    }
  }

  Future<void> _refreshAuthStatus() async {
    final status = await ApiService.getAuthStatusInfo();

    if (!mounted) return;

    setState(() {
      _authStatus = status;
    });
  }

  void _redirectToLogin() {
    _wsService.disconnect();
    if (!mounted) return;

    setState(() => _messages.clear());

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    ToastWidget.show(context,
        message: 'Сессия истекла', type: ToastType.warning);
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    if (Navigator.canPop(context)) Navigator.pop(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoggingOut = true);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      _wsService.disconnect();
      await ApiService.logout();

      if (!mounted) return;

      Navigator.pop(context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);
      ToastWidget.show(context,
          message: 'Ошибка при выходе: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _logoutAll() async {
    if (_isLoggingOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти со всех устройств?'),
        content: const Text(
            'Вы будете разлогинены на всех устройствах, включая текущее.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Выйти со всех'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoggingOut = true);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      _wsService.disconnect();
      await ApiService.logoutAll();

      if (!mounted) return;

      Navigator.pop(context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);
      ToastWidget.show(context, message: 'Ошибка: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _terminateSession(String sessionId) async {
    try {
      final success = await ApiService.terminateSession(sessionId);
      if (success && mounted) {
        ToastWidget.show(context,
            message: 'Сессия завершена', type: ToastType.success);
      } else if (mounted) {
        ToastWidget.show(context,
            message: 'Не удалось завершить сессию', type: ToastType.error);
      }
    } catch (_) {
      if (mounted) {
        ToastWidget.show(context,
            message: 'Ошибка при завершении сессии', type: ToastType.error);
      }
    }
  }

  void _performTextSearch() {
    final query = _findController.text.toLowerCase().trim();
    _messageMatchCount.clear();
    _matchedMessages.clear();
    _currentMatchIndex = -1;

    if (query.isEmpty) {
      setState(() {});
      return;
    }

    for (int i = 0; i < _filteredMessages.length; i++) {
      final msg = _filteredMessages[i];
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
      _scrollToCurrentMatch();
    }

    setState(() {});
  }

  void _scrollToCurrentMatch() {
    if (_matchedMessages.isEmpty) return;

    final msg = _matchedMessages[_currentMatchIndex];
    final msgIndex = _filteredMessages.indexOf(msg);

    if (msgIndex != -1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        final offset = msgIndex * 300.0;
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _goToNextMatch() {
    if (_matchedMessages.isEmpty) return;

    _currentMatchIndex = (_currentMatchIndex + 1) % _matchedMessages.length;
    _scrollToCurrentMatch();
    setState(() {});
  }

  void _goToPreviousMatch() {
    if (_matchedMessages.isEmpty) return;

    _currentMatchIndex = (_currentMatchIndex - 1 + _matchedMessages.length) %
        _matchedMessages.length;
    _scrollToCurrentMatch();
    setState(() {});
  }

  void _openSearchPanel() {
    setState(() => _searchPanelOpen = true);
    _findFocusNode.requestFocus();
  }

  void _closeSearchPanel() {
    setState(() {
      _searchPanelOpen = false;
      _findController.clear();
      _matchedMessages.clear();
      _currentMatchIndex = -1;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      _mainFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _findDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _wsService.disconnect();
    _scrollController.dispose();
    _searchController.dispose();
    _findController.dispose();
    _findFocusNode.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final messageWidgets = _buildMessageList();

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white : const Color(0xFF5A8FEC),
            ),
          ),
        ),
      );
    }

    return _buildScaffold(isDark, messageWidgets);
  }

  Widget _buildScaffold(bool isDark, List<Widget> messageWidgets) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF):
            const _OpenSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const _OpenSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _CloseSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const _NextMatchIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const _PreviousMatchIntent(),
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF): () {
            _openSearchPanel();
          },
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
              () {
            _openSearchPanel();
          },
          LogicalKeySet(LogicalKeyboardKey.escape): () {
            if (_searchPanelOpen) _closeSearchPanel();
          },
          LogicalKeySet(LogicalKeyboardKey.arrowDown): () {
            if (_searchPanelOpen && _matchedMessages.isNotEmpty) {
              _goToNextMatch();
            }
          },
          LogicalKeySet(LogicalKeyboardKey.arrowUp): () {
            if (_searchPanelOpen && _matchedMessages.isNotEmpty) {
              _goToPreviousMatch();
            }
          },
        },
        child: Focus(
          focusNode: _mainFocusNode,
          autofocus: true,
          child: _buildMainContent(isDark, messageWidgets),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark, List<Widget> messageWidgets) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.appBackground,
          body: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration:
                              context.panelDecoration(radius: 28).copyWith(
                            color: context.appPanel.withValues(alpha: 0.42),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '{..Logger..}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      'Главная',
                                      style: TextStyle(
                                        color: Color(0xFF5A8FEC),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: _openDocs,
                                    child: Text(
                                      'Документация',
                                      style: TextStyle(
                                        color: context.appTextMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              if (_username != null)
                                InkWell(
                                  onTap: _showKeyModal,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.accent.withValues(alpha: 0.09),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppTheme.accent
                                            .withValues(alpha: 0.18),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          size: 18,
                                          color: Color(0xFF5A8FEC),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _username!,
                                          style: const TextStyle(
                                            color: AppTheme.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: _isConnected
                                                ? Colors.green
                                                : Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _isConnected
                                                    ? Colors.green.withValues(
                                                        alpha: 0.4)
                                                    : Colors.red.withValues(
                                                        alpha: 0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              _buildToolbarAction(
                                icon: Icons.monitor_heart_outlined,
                                color: _connectionStatus.isConnected
                                    ? Colors.green
                                    : (_connectionStatus.isReconnecting
                                        ? Colors.orange
                                        : const Color(0xFFFF6B6B)),
                                onTap: _showConnectionStatusModal,
                              ),
                              const SizedBox(width: 8),
                              _buildToolbarAction(
                                icon: _isCheckingUpdates
                                    ? Icons.sync_rounded
                                    : (_isInstallingUpdate
                                        ? Icons.download_for_offline_rounded
                                        : Icons.system_update_alt_rounded),
                                color: (_lastUpdateResult?.hasUpdate ?? false)
                                    ? Colors.orange
                                    : AppTheme.accent,
                                onTap: _isInstallingUpdate
                                    ? null
                                    : () => _checkForUpdates(
                                          silentIfCurrent: false,
                                        ),
                              ),
                              const SizedBox(width: 8),
                              const ThemeToggle(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              decoration:
                                  context.panelDecoration(radius: 24).copyWith(
                                color: context.appPanel.withValues(alpha: 0.4),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(
                                  color: context.appTextPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Поиск по модулю...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppTheme.accent,
                                    size: 20,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            color: AppTheme.accent,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildToolbarAction(
                        icon: Icons.copy_all_rounded,
                        color: AppTheme.accent,
                        onTap: _copyAllMessages,
                      ),
                      const SizedBox(width: 8),
                      _buildToolbarAction(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFFF6B6B),
                        onTap: _clearAllMessages,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: context.appTextMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Нет сообщений',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ожидание сообщений от сервера...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.appTextMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: messageWidgets.length,
                          itemBuilder: (context, index) =>
                              _buildMessageWithHighlight(
                            messageWidgets[index],
                            index,
                            isDark,
                          ),
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: _showFAB
              ? FloatingActionButton(
                  onPressed: () => _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                  backgroundColor: context.appPanel,
                  child: const Icon(Icons.arrow_upward, color: AppTheme.accent),
                )
              : null,
        ),
        if (_searchPanelOpen) _buildSearchPanel(isDark),
      ],
    );
  }

  Widget _buildSearchPanel(bool isDark) {
    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 480,
                decoration: context.panelDecoration(radius: 18).copyWith(
                      color: context.appPanel.withValues(alpha: 0.52),
                    ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.appPanelAlt.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.appPanelAlt.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.appBorder.withValues(alpha: 0.38),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: context.isDarkMode ? 0.03 : 0.18,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextField(
                          focusNode: _findFocusNode,
                          controller: _findController,
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Найти в сообщениях',
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_findController.text.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: context.appPanelAlt.withValues(alpha: 0.58),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: context.appBorder.withValues(alpha: 0.38),
                          ),
                        ),
                        child: Text(
                          _matchedMessages.isEmpty
                              ? '0 из 0'
                              : '${_currentMatchIndex + 1} из ${_matchedMessages.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _matchedMessages.isEmpty
                                ? Colors.redAccent
                                : context.appTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _buildSearchActionButton(
                        icon: Icons.keyboard_arrow_up_rounded,
                        onPressed: _matchedMessages.isNotEmpty
                            ? _goToPreviousMatch
                            : null,
                      ),
                      const SizedBox(width: 6),
                      _buildSearchActionButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onPressed:
                            _matchedMessages.isNotEmpty ? _goToNextMatch : null,
                      ),
                      const SizedBox(width: 6),
                    ],
                    _buildSearchActionButton(
                      icon: Icons.close_rounded,
                      onPressed: _closeSearchPanel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageWithHighlight(
      Widget messageWidget, int index, bool isDark) {
    return messageWidget;
  }

  Widget _buildToolbarAction({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: context.panelDecoration(radius: 22).copyWith(
              color: context.appPanel.withValues(alpha: 0.44),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.appPanel.withValues(alpha: 0.52),
                  context.appPanelAlt.withValues(alpha: 0.28),
                ],
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: context.appPanelAlt.withValues(alpha: 0.56),
          foregroundColor: AppTheme.accent,
          disabledForegroundColor: context.appTextMuted,
          side: BorderSide(color: context.appBorder.withValues(alpha: 0.34)),
        ),
      ),
    );
  }
}
