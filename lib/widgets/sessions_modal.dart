import 'package:flutter/material.dart';
import 'dart:ui';
import '../controllers/sessions_modal_controller.dart';
import '../models/session_model.dart';
import '../utils/theme.dart';
import 'toast_widget.dart';

class SessionsModal extends StatefulWidget {
  final VoidCallback onLogoutAll;

  const SessionsModal({
    super.key,
    required this.onLogoutAll,
  });

  @override
  State<SessionsModal> createState() => _SessionsModalState();
}

class _SessionsModalState extends State<SessionsModal> {
  late final SessionsModalController _controller;

  List<SessionModel> get _sessions => _controller.sessions;
  bool get _isLoading => _controller.isLoading;
  bool get _isProcessing => _controller.isProcessing;

  @override
  void initState() {
    super.initState();
    _controller = SessionsModalController()..addListener(_handleController);
    _controller.loadSessions().catchError((_) {
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Ошибка загрузки сессий',
        type: ToastType.error,
      );
    });
  }

  void _handleController() {
    if (mounted) setState(() {});
  }

  String _getDeviceIcon(String? userAgent) {
    if (userAgent == null) return '💻';
    if (userAgent.contains('iPhone') || userAgent.contains('Android')) {
      return '📱';
    }
    if (userAgent.contains('iPad')) return '📟';
    if (userAgent.contains('Mac')) return '🖥️';
    if (userAgent.contains('Windows')) return '🪟';
    return '💻';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Неизвестно';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'только что';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} мин назад';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} ч назад';
      } else {
        return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _handleTerminate(String sessionId) async {
    if (_isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить сессию'),
        content: const Text('Это устройство будет разлогинено. Продолжить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final success = await _controller.terminateSession(sessionId);
        if (!mounted) return;
        if (success) {
          ToastWidget.show(
            context,
            message: 'Сессия завершена',
            type: ToastType.success,
          );
        } else {
          ToastWidget.show(
            context,
            message: 'Ошибка при завершении сессии',
            type: ToastType.error,
          );
        }
      } catch (e) {
        if (mounted) {
          ToastWidget.show(
            context,
            message: 'Ошибка при завершении сессии',
            type: ToastType.error,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 500),
            decoration: context.panelDecoration(radius: 30).copyWith(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.appPanel.withValues(alpha: 0.72),
                      context.appPanelAlt.withValues(alpha: 0.58),
                    ],
                  ),
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: context.appBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: context.appAccentGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.devices,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Активные сессии',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Устройства, на которых выполнен вход',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.appTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: context.appPanelAlt,
                        ),
                      ),
                    ],
                  ),
                ),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF5A8FEC)),
                          ),
                        ),
                      )
                    : _sessions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('Нет активных сессий'),
                            ),
                          )
                        : Flexible(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _sessions.length,
                              itemBuilder: (context, index) {
                                final session = _sessions[index];

                                final isCurrent = session.isCurrent;
                                final sessionId = session.id;
                                final device = session.device;
                                final ip = session.ip ?? 'Неизвестно';
                                final lastActive = session.lastActive;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: context
                                      .panelDecoration(radius: 20)
                                      .copyWith(
                                        color: context.appPanel
                                            .withValues(alpha: 0.78),
                                        border: Border.all(
                                          color: isCurrent
                                              ? AppTheme.accent
                                                  .withValues(alpha: 0.65)
                                              : context.appBorder,
                                          width: isCurrent ? 1.6 : 1,
                                        ),
                                      ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: isCurrent
                                              ? context.appAccentGradient
                                              : null,
                                          color: isCurrent
                                              ? null
                                              : context.appPanelAlt,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getDeviceIcon(device),
                                            style:
                                                const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    device,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: context
                                                          .appTextPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isCurrent)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFF5A8FEC),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: const Text(
                                                      'Текущая',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'IP: $ip',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: context.appTextMuted,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Последняя активность: ${_formatDate(lastActive)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: context.appTextMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isCurrent && sessionId.isNotEmpty)
                                        IconButton(
                                          icon: _isProcessing
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(Icons.logout,
                                                  color: Colors.red),
                                          onPressed: _isProcessing
                                              ? null
                                              : () =>
                                                  _handleTerminate(sessionId),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: context.appBorder,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side:
                                BorderSide(color: context.appBorder, width: 1),
                            backgroundColor: context.appPanelAlt,
                          ),
                          child: Text(
                            'Закрыть',
                            style: TextStyle(
                              color: context.appTextMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  widget.onLogoutAll();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Выйти со всех',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
