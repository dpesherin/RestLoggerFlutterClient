import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import '../models/message.dart';
import '../utils/json_helper.dart';

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
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1E24) : const Color(0xFFE0E5EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
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
                            color: const Color(0xFF5A8FEC).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
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
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF4A5C6E),
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
                      backgroundColor:
                          isDark ? const Color(0xFF2C313A) : Colors.white,
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
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D2D2D)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    JsonHelper.formatContent(widget.message.displayContent),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Color(0xFFD4D4D4),
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
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
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
              ? const LinearGradient(
                  colors: [Color(0xFF5A8FEC), Color(0xFF4A7AD4)],
                )
              : null,
          color: isPrimary
              ? null
              : (isDark ? const Color(0xFF2C313A) : Colors.white),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF5A8FEC).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color:
                        isDark ? Colors.black26 : Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  ),
                  BoxShadow(
                    color: isDark ? const Color(0xFF3A404B) : Colors.white,
                    blurRadius: 5,
                    offset: const Offset(-2, -2),
                  ),
                ],
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
