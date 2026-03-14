import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/main_screen_controller.dart';
import '../components/main_screen/main_screen_empty_logs_state.dart';
import '../components/main_screen/main_screen_dialogs.dart';
import '../components/main_screen/main_screen_logs_toolbar.dart';
import '../components/main_screen/main_screen_message_list_builder.dart';
import '../components/main_screen/main_screen_search_overlay.dart';
import '../components/main_screen/main_screen_top_bar.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/update_service.dart';
import '../services/modal_guard_service.dart';
import '../services/websocket_service.dart';
import '../utils/theme.dart';
import '../utils/config.dart';
import '../utils/logger.dart';
import '../widgets/key_modal.dart';
import '../widgets/sessions_modal.dart';
import '../widgets/connection_status_modal.dart';
import '../widgets/toast_widget.dart';
import '../widgets/update_modal.dart';
import 'api_docs_builder_screen.dart';
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

enum _MainSection { logs, apiDocs }

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
  late final MainScreenController _controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _findController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();

  bool get _isConnected => _controller.isConnected;
  bool get _isLoading => _controller.isLoading;
  String? get _consumerKey => _controller.consumerKey;
  String? get _username => _controller.username;
  ConnectionStatus get _connectionStatus => _controller.connectionStatus;
  AuthStatusInfo get _authStatus => _controller.authStatus;
  bool get _isLoggingOut => _controller.isLoggingOut;
  bool get _isCheckingAuth => _controller.isCheckingAuth;
  bool get _showFAB => _controller.showFAB;
  bool get _searchPanelOpen => _controller.searchPanelOpen;
  bool get _isCheckingUpdates => _controller.isCheckingUpdates;
  int get _currentMatchIndex => _controller.currentMatchIndex;
  _MainSection get _currentSection =>
      _controller.currentSection == MainSection.logs
          ? _MainSection.logs
          : _MainSection.apiDocs;
  List<Message> get _matchedMessages => _controller.matchedMessages;
  List<Message> get _messages => _controller.messages;
  late _AppLifecycleObserver _lifecycleObserver;
  Timer? _searchDebounce;
  Timer? _findDebounce;

  @override
  void initState() {
    super.initState();
    _controller = MainScreenController()..addListener(_handleControllerChanged);
    _initData();
    _connectWebSocket();

    _lifecycleObserver = _AppLifecycleObserver(onResume: _checkAuthAndRedirect);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });

    _scrollController.addListener(() {
      _controller.updateScrollOffset(
        _scrollController.offset,
        hasClients: _scrollController.hasClients,
      );
    });

    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) _controller.setSearchQuery(_searchController.text);
      });
    });

    _findController.addListener(() {
      if (_findDebounce?.isActive ?? false) _findDebounce?.cancel();
      _findDebounce = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          _controller.setFindQuery(_findController.text);
          _scrollToCurrentMatch();
        }
      });
    });
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initData() async {
    final initData = await _controller.initialize();
    if (!mounted) return;

    if (initData.autoCheckUpdates) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _runAutoUpdateCheck();
      });
    }
  }

  Future<void> _openUpdateModal({
    required bool autoStartCheck,
    required bool dismissIfNoUpdate,
    UpdateCheckResult? initialResult,
  }) async {
    if (_isCheckingUpdates ||
        !_controller.updateRepository.isSupportedPlatform) {
      return;
    }

    _controller.markCheckingUpdates(true);

    await ModalGuardService.showGuarded(
      context,
      'updateModal',
      UpdateModal(
        autoStartCheck: autoStartCheck,
        dismissIfNoUpdate: dismissIfNoUpdate,
        initialResult: initialResult,
      ),
      barrierDismissible: false,
    );

    if (!mounted) return;
    _controller.markCheckingUpdates(false);
  }

  Future<void> _runAutoUpdateCheck() async {
    final result = await _controller.runAutoUpdateCheck();
    if (!mounted || result == null) return;
    await _openUpdateModal(
      autoStartCheck: false,
      dismissIfNoUpdate: false,
      initialResult: result,
    );
  }

  void _connectWebSocket() {
    _controller.connectWebSocket(
      onConnected: () {
        if (!mounted) return;
        ToastWidget.show(
          context,
          message: 'Подключено к серверу',
          type: ToastType.success,
        );
      },
    );
  }

  List<Message> get _filteredMessages {
    return _controller.filteredMessages;
  }

  List<Message> get _pinnedMessages => _controller.pinnedMessages;
  List<Message> get _unpinnedMessages => _controller.unpinnedMessages;

  void _togglePin(Message message) {
    _controller.togglePin(message);

    ToastWidget.show(
      context,
      message:
          message.isPinned ? 'Сообщение закреплено' : 'Сообщение откреплено',
      type: message.isPinned ? ToastType.success : ToastType.info,
    );
  }

  List<Widget> _buildMessageList() {
    return buildMainScreenMessageList(
      pinnedMessages: _pinnedMessages,
      unpinnedMessages: _unpinnedMessages,
      matchedMessages: _matchedMessages,
      currentMatchIndex: _currentMatchIndex,
      findQuery: _findController.text,
      onPinToggle: _togglePin,
    );
  }

  void _clearAllMessages() {
    showMainScreenClearMessagesDialog(
      context: context,
      onConfirm: () {
        _controller.clearMessages();
        ToastWidget.show(
          context,
          message: 'Все сообщения удалены',
          type: ToastType.success,
        );
      },
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
    ModalGuardService.showGuarded(
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
    final isAuth = await _controller.checkAuth();
    if (!isAuth && mounted) {
      _redirectToLogin();
      return;
    }

    if (!mounted) return;

    ModalGuardService.showGuarded(
      context,
      'sessionsModal',
      SessionsModal(
        onLogoutAll: _logoutAll,
      ),
    );
  }

  Future<void> _showConnectionStatusModal() async {
    await _refreshAuthStatus();

    if (!mounted) return;

    ModalGuardService.showGuarded(
      context,
      'connectionStatusModal',
      ConnectionStatusModal(
        connectionStatus: _connectionStatus,
        authStatus: _authStatus,
        onReconnect: () {
          Navigator.pop(context);
          _controller.reconnectWebSocket();
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

    _controller.setCheckingAuth(true);
    try {
      final isAuth = await _controller.checkAuth();
      if (!isAuth && mounted) _redirectToLogin();
    } catch (e) {
      logger.error('Error checking auth', e);
    } finally {
      _controller.setCheckingAuth(false);
    }
  }

  Future<void> _refreshAuthStatus() async {
    await _controller.refreshAuthStatus();
  }

  void _dismissTransientRoutes() {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.popUntil((route) => route is PageRoute<dynamic>);
    ModalGuardService.reset();
  }

  void _redirectToLogin() {
    _controller.disconnectWebSocket();
    if (!mounted) return;

    _controller.clearMessages();
    _dismissTransientRoutes();

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

    final confirm = await showMainScreenLogoutConfirmDialog(
      context: context,
      allDevices: false,
    );
    if (!confirm) return;

    await _controller.setLoggingOut(true);

    if (!mounted) return;
    showMainScreenBlockingProgressDialog(context);

    try {
      _controller.disconnectWebSocket();
      await _controller.logout();

      if (!mounted) return;

      Navigator.pop(context);
      _dismissTransientRoutes();
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
      if (mounted) await _controller.setLoggingOut(false);
    }
  }

  Future<void> _logoutAll() async {
    if (_isLoggingOut) return;

    final confirm = await showMainScreenLogoutConfirmDialog(
      context: context,
      allDevices: true,
    );
    if (!confirm) return;

    await _controller.setLoggingOut(true);

    if (!mounted) return;
    showMainScreenBlockingProgressDialog(context);

    try {
      _controller.disconnectWebSocket();
      await _controller.logoutAll();

      if (!mounted) return;

      Navigator.pop(context);
      _dismissTransientRoutes();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);
      ToastWidget.show(context, message: 'Ошибка: $e', type: ToastType.error);
    } finally {
      if (mounted) await _controller.setLoggingOut(false);
    }
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
    _controller.goToNextMatch();
    _scrollToCurrentMatch();
  }

  void _goToPreviousMatch() {
    if (_matchedMessages.isEmpty) return;
    _controller.goToPreviousMatch();
    _scrollToCurrentMatch();
  }

  void _openSearchPanel() {
    _controller.openSearchPanel();
    _findFocusNode.requestFocus();
  }

  void _closeSearchPanel() {
    _findController.clear();
    _controller.closeSearchPanel();
    Future.delayed(const Duration(milliseconds: 50), () {
      _mainFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _findDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _controller.removeListener(_handleControllerChanged);
    _controller.disconnectWebSocket();
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
                  child: MainScreenTopBar(
                    showLogsSection: _currentSection == _MainSection.logs,
                    showApiDocsSection: _currentSection == _MainSection.apiDocs,
                    username: _username,
                    isConnected: _isConnected,
                    isCheckingUpdates: _isCheckingUpdates,
                    isInstallingUpdate: false,
                    hasAvailableUpdate: false,
                    onShowLogs: () =>
                        _controller.selectSection(MainSection.logs),
                    onShowApiDocs: () =>
                        _controller.selectSection(MainSection.apiDocs),
                    onShowKeyModal: _showKeyModal,
                    onOpenDocs: _openDocs,
                    onShowConnectionStatus: _showConnectionStatusModal,
                    onShowUpdates: () => _openUpdateModal(
                      autoStartCheck: true,
                      dismissIfNoUpdate: false,
                    ),
                  ),
                ),
                if (_currentSection == _MainSection.logs)
                  MainScreenLogsToolbar(
                    searchController: _searchController,
                    onClearSearch: () {
                      _searchController.clear();
                      _controller.setSearchQuery('');
                    },
                    onCopyAll: _copyAllMessages,
                    onClearAll: _clearAllMessages,
                  ),
                Expanded(
                  child: _currentSection == _MainSection.apiDocs
                      ? const ApiDocsBuilderScreen()
                      : _messages.isEmpty
                          ? const MainScreenEmptyLogsState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 16),
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
          floatingActionButton: _currentSection == _MainSection.logs && _showFAB
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
        if (_currentSection == _MainSection.logs && _searchPanelOpen)
          MainScreenSearchOverlay(
            focusNode: _findFocusNode,
            controller: _findController,
            currentMatchIndex: _currentMatchIndex,
            matchCount: _matchedMessages.length,
            onPrevious: _matchedMessages.isNotEmpty ? _goToPreviousMatch : null,
            onNext: _matchedMessages.isNotEmpty ? _goToNextMatch : null,
            onClose: _closeSearchPanel,
          ),
      ],
    );
  }

  Widget _buildMessageWithHighlight(
      Widget messageWidget, int index, bool isDark) {
    return messageWidget;
  }
}
