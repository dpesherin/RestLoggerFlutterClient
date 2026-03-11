import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../utils/config.dart';
import '../utils/logger.dart';
import '../widgets/message_card.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/key_modal.dart';
import '../widgets/sessions_modal.dart';
import '../widgets/toast_widget.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/session_provider.dart';

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
      builder: (context) => WillPopScope(
        onWillPop: () async {
          _modalOpenState[modalType] = false;
          return true;
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
  bool _isLoggingOut = false;
  bool _isCheckingAuth = false;
  bool _showFAB = false;
  bool _searchPanelOpen = false;
  int _currentMatchIndex = -1;
  List<Message> _matchedMessages = [];
  Map<int, int> _messageMatchCount = {};
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

      if (mounted) {
        setState(() {
          _username = user?.login;
          _consumerKey = key;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _connectWebSocket() {
    _wsService.connect(
      onMessage: _handleNewMessage,
      onConnectionChange: (connected) {
        if (mounted) {
          setState(() => _isConnected = connected);
          if (connected) {
            ToastWidget.show(
              context,
              message: 'Подключено к серверу',
              type: ToastType.success,
            );
          }
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
      if (message.isPinned)
        message.pinnedAt = DateTime.now().millisecondsSinceEpoch;
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
      ToastWidget.show(context,
          message: 'Все сообщения скопированы', type: ToastType.success);
    }).catchError((_) {
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

  Future<void> _openDocs() async {
    final Uri url = Uri.parse(AppConfig.docsUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ToastWidget.show(context,
            message: 'Не удалось открыть браузер', type: ToastType.error);
      }
    } catch (_) {
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
      }
    } catch (_) {
      if (mounted)
        ToastWidget.show(context,
            message: 'Ошибка при завершении сессии', type: ToastType.error);
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
    final pinnedMessages = _pinnedMessages;
    final messageWidgets = _buildMessageList();

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
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark ? const Color(0xFF1A1E24) : const Color(0xFFE0E5EC),
            child: Column(
              children: [
                SafeArea(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1E24)
                          : const Color(0xFFE0E5EC),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black54
                              : Colors.grey.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(5, 5),
                        ),
                        BoxShadow(
                          color:
                              isDark ? const Color(0xFF2C313A) : Colors.white,
                          blurRadius: 10,
                          offset: const Offset(-5, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '{..Logger..}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Color(0xFF5A8FEC),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Главная',
                                style: TextStyle(
                                  color: const Color(0xFF5A8FEC),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _openDocs,
                              child: Text(
                                'Документация',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2D4059),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        if (_username != null)
                          InkWell(
                            onTap: _showKeyModal,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5A8FEC).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person,
                                      size: 18, color: Color(0xFF5A8FEC)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _username!,
                                    style: const TextStyle(
                                        color: Color(0xFF5A8FEC),
                                        fontWeight: FontWeight.w500),
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
                                              ? Colors.green.withOpacity(0.5)
                                              : Colors.red.withOpacity(0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const ThemeToggle(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black54
                                    : Colors.grey.withOpacity(0.5),
                                blurRadius: 6,
                                offset: const Offset(3, 3),
                              ),
                              BoxShadow(
                                color: isDark
                                    ? const Color(0xFF2C313A)
                                    : Colors.white,
                                blurRadius: 6,
                                offset: const Offset(-3, -3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2D4059)),
                            decoration: InputDecoration(
                              hintText: 'Поиск по модулю...',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : const Color(0xFF4A5C6E).withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(Icons.search,
                                  color: Color(0xFF5A8FEC), size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: Color(0xFF5A8FEC), size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1A1E24)
                                  : const Color(0xFFE0E5EC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _copyAllMessages,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A1E24)
                                : const Color(0xFFE0E5EC),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black54
                                    : Colors.grey.withOpacity(0.5),
                                blurRadius: 5,
                                offset: const Offset(3, 3),
                              ),
                              BoxShadow(
                                color: isDark
                                    ? const Color(0xFF2C313A)
                                    : Colors.white,
                                blurRadius: 5,
                                offset: const Offset(-3, -3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.copy_all,
                              color: Color(0xFF5A8FEC), size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _clearAllMessages,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A1E24)
                                : const Color(0xFFE0E5EC),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black54
                                    : Colors.grey.withOpacity(0.5),
                                blurRadius: 5,
                                offset: const Offset(3, 3),
                              ),
                              BoxShadow(
                                color: isDark
                                    ? const Color(0xFF2C313A)
                                    : Colors.white,
                                blurRadius: 5,
                                offset: const Offset(-3, -3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Color(0xFFFF6B6B), size: 20),
                        ),
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
                              Icon(Icons.inbox,
                                  size: 64,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('Нет сообщений',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600])),
                              const SizedBox(height: 8),
                              Text('Ожидание сообщений от сервера...',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500])),
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
                  backgroundColor: isDark
                      ? const Color(0xFF1A1E24)
                      : const Color(0xFFE0E5EC),
                  child:
                      const Icon(Icons.arrow_upward, color: Color(0xFF5A8FEC)),
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
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 350,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1E24) : const Color(0xFFE0E5EC),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(3, 3),
                ),
                BoxShadow(
                  color: isDark ? const Color(0xFF2C313A) : Colors.white,
                  blurRadius: 10,
                  offset: const Offset(-3, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'ПОИСК',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _closeSearchPanel,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  focusNode: _findFocusNode,
                  controller: _findController,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF2D4059),
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Введите текст...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.grey[500]
                          : const Color(0xFF4A5C6E).withOpacity(0.5),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2C313A)
                        : const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                if (_findController.text.isNotEmpty)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          _matchedMessages.isEmpty
                              ? 'Совпадений не найдено'
                              : '${_currentMatchIndex + 1} из ${_matchedMessages.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _matchedMessages.isEmpty
                                ? Colors.red
                                : const Color(0xFF5A8FEC),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: _matchedMessages.isNotEmpty
                                  ? _goToPreviousMatch
                                  : null,
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              color: const Color(0xFF5A8FEC),
                              disabledColor: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: _matchedMessages.isNotEmpty
                                  ? _goToNextMatch
                                  : null,
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              color: const Color(0xFF5A8FEC),
                              disabledColor: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
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
}
