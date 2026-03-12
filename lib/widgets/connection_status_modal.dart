import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../utils/theme.dart';

class ConnectionStatusModal extends StatelessWidget {
  final ConnectionStatus connectionStatus;
  final AuthStatusInfo authStatus;
  final VoidCallback onReconnect;

  const ConnectionStatusModal({
    super.key,
    required this.connectionStatus,
    required this.authStatus,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final canReconnect = !connectionStatus.isConnected &&
        connectionStatus.reconnectAttempts < connectionStatus.maxReconnectAttempts;
    final handshakeMs = connectionStatus.latencyMs ?? 0;
    final authMs = authStatus.latencyMs;
    final combinedMs = handshakeMs + authMs;

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
            width: 560,
            decoration: context.panelDecoration(radius: 30).copyWith(
                  color: context.appPanel.withValues(alpha: 0.66),
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: context.appBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_outlined,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Состояние соединения',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Это не WebSocket ping, а время handshake и проверки авторизации',
                              style: TextStyle(
                                color: context.appTextMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: context.appPanelAlt,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                label: 'WebSocket',
                                value: connectionStatus.isConnected
                                    ? 'Connected'
                                    : (connectionStatus.isReconnecting
                                        ? 'Reconnecting'
                                        : 'Disconnected'),
                                accentColor: connectionStatus.isConnected
                                    ? Colors.green
                                    : (connectionStatus.isReconnecting
                                        ? Colors.orange
                                        : Colors.redAccent),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                label: 'Handshake + Auth',
                                value: '$combinedMs ms',
                                subtitle:
                                    'Handshake: $handshakeMs ms • Auth: $authMs ms',
                                accentColor: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                label: 'Reconnects',
                                value:
                                    '${connectionStatus.reconnectAttempts}/${connectionStatus.maxReconnectAttempts}',
                                subtitle:
                                    'Всего переподключений: ${connectionStatus.totalReconnects}',
                                accentColor: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                label: 'Auth',
                                value: authStatus.isAuthenticated
                                    ? 'Authenticated'
                                    : 'Failed',
                                subtitle: authStatus.message,
                                accentColor: authStatus.isAuthenticated
                                    ? Colors.green
                                    : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (connectionStatus.lastError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            connectionStatus.lastError!,
                            style: TextStyle(
                              color: context.appTextPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: context.appBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: context.appPanelAlt,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canReconnect ? onReconnect : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Reconnect',
                            style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    String? subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appPanelAlt.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.appTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: context.appTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                color: context.appTextMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
