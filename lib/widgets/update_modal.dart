import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/update_service.dart';
import '../utils/theme.dart';

class UpdateModal extends StatelessWidget {
  final UpdateCheckResult result;
  final VoidCallback onInstall;

  const UpdateModal({
    super.key,
    required this.result,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final update = result.updateInfo;
    if (update == null) {
      return const SizedBox.shrink();
    }

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
                          Icons.system_update_alt_rounded,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Доступно обновление',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${result.currentPlatform} • ${result.currentVersion} -> ${update.fullVersion}',
                              style: TextStyle(
                                color: context.appTextMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!update.mandatory)
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        context,
                        'Текущая версия',
                        result.currentVersion,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        context,
                        'Новая версия',
                        update.fullVersion,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        context,
                        'Файл',
                        update.fileName,
                      ),
                      if (update.publishedAt != null) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          context,
                          'Дата публикации',
                          update.publishedAt!,
                        ),
                      ],
                      if ((update.notes ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Что нового',
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.appPanelAlt.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.appBorder),
                          ),
                          child: Text(
                            update.notes!,
                            style: TextStyle(
                              color: context.appTextMuted,
                              height: 1.45,
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
                      if (!update.mandatory) ...[
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
                              'Позже',
                              style: TextStyle(
                                color: context.appTextMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onInstall,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Установить обновление',
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              color: context.appTextMuted,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
