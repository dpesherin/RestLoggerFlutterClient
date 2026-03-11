import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import '../models/message.dart';
import '../utils/json_helper.dart';
import '../utils/theme.dart';

class FullscreenView extends StatefulWidget {
  final Message message;

  const FullscreenView({super.key, required this.message});

  @override
  State<FullscreenView> createState() => _FullscreenViewState();
}

class _FullscreenViewState extends State<FullscreenView> {
  bool _showCopied = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.9,
        decoration: context.panelDecoration(radius: 24).copyWith(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.appPanel.withValues(alpha: 0.96),
                  context.appPanelAlt.withValues(alpha: 0.88),
                ],
              ),
            ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.appBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.message.moduleName,
                            style: const TextStyle(
                              color: Color(0xFF5A8FEC),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.message.formattedTime,
                          style: TextStyle(
                            color: context.appTextMuted,
                            fontSize: 14,
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
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF09101D) : const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.appBorder),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    JsonHelper.formatContent(widget.message.displayContent),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: context.appTextPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: context.appBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildButton(
                    icon: _showCopied ? Icons.check : Icons.copy,
                    label: _showCopied ? 'Скопировано' : 'Копировать',
                    onTap: () async {
                      await FlutterClipboard.copy(
                          widget.message.displayContent);
                      setState(() => _showCopied = true);
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) {
                        setState(() => _showCopied = false);
                      }
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildButton(
                    icon: Icons.close,
                    label: 'Закрыть',
                    isPrimary: true,
                    onTap: () => Navigator.pop(context),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
                  gradient: isPrimary
              ? context.appAccentGradient
              : null,
          color: isPrimary
              ? null
              : context.appPanelAlt,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : context.appBorder,
          ),
          boxShadow: isPrimary ? context.appGlowShadow : context.appSoftShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.grey[700]),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.grey[700]),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
