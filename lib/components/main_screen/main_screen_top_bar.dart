import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import '../../widgets/theme_toggle.dart';
import 'main_screen_toolbar_action.dart';

class MainScreenTopBar extends StatelessWidget {
  final bool showLogsSection;
  final bool showApiDocsSection;
  final String? username;
  final bool isConnected;
  final bool isCheckingUpdates;
  final bool isInstallingUpdate;
  final bool hasAvailableUpdate;
  final VoidCallback onShowLogs;
  final VoidCallback onShowApiDocs;
  final VoidCallback onShowKeyModal;
  final VoidCallback onOpenDocs;
  final VoidCallback onShowConnectionStatus;
  final VoidCallback onShowUpdates;

  const MainScreenTopBar({
    super.key,
    required this.showLogsSection,
    required this.showApiDocsSection,
    required this.username,
    required this.isConnected,
    required this.isCheckingUpdates,
    required this.isInstallingUpdate,
    required this.hasAvailableUpdate,
    required this.onShowLogs,
    required this.onShowApiDocs,
    required this.onShowKeyModal,
    required this.onOpenDocs,
    required this.onShowConnectionStatus,
    required this.onShowUpdates,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              decoration: context.panelDecoration(radius: 28).copyWith(
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: onShowLogs,
                        child: Text(
                          'Главная',
                          style: TextStyle(
                            color: showLogsSection
                                ? const Color(0xFF5A8FEC)
                                : context.appTextMuted,
                            fontWeight: showLogsSection
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onShowApiDocs,
                        child: Text(
                          'API Конструктор',
                          style: TextStyle(
                            color: showApiDocsSection
                                ? const Color(0xFF5A8FEC)
                                : context.appTextMuted,
                            fontWeight: showApiDocsSection
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (username != null)
                        Tooltip(
                          message: 'Профиль и ключ доступа',
                          waitDuration: const Duration(milliseconds: 250),
                          child: InkWell(
                            onTap: onShowKeyModal,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color:
                                      AppTheme.accent.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Color(0xFF5A8FEC),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    username!,
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
                                      color: isConnected
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isConnected
                                              ? Colors.green
                                                  .withValues(alpha: 0.4)
                                              : Colors.red
                                                  .withValues(alpha: 0.4),
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
                        ),
                      if (username != null) const SizedBox(width: 8),
                      MainScreenToolbarAction(
                        icon: Icons.open_in_browser_rounded,
                        color: AppTheme.accent,
                        onTap: onOpenDocs,
                        tooltip: 'Открыть документацию',
                      ),
                      const SizedBox(width: 8),
                      MainScreenToolbarAction(
                        icon: Icons.monitor_heart_outlined,
                        color: isConnected
                            ? Colors.green
                            : const Color(0xFFFF6B6B),
                        onTap: onShowConnectionStatus,
                        tooltip: 'Статус соединения',
                      ),
                      const SizedBox(width: 8),
                      MainScreenToolbarAction(
                        icon: isCheckingUpdates
                            ? Icons.sync_rounded
                            : (isInstallingUpdate
                                ? Icons.download_for_offline_rounded
                                : Icons.system_update_alt_rounded),
                        color: hasAvailableUpdate
                            ? Colors.orange
                            : AppTheme.accent,
                        onTap: onShowUpdates,
                        tooltip: 'Обновления приложения',
                      ),
                      const SizedBox(width: 8),
                      const ThemeToggle(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
