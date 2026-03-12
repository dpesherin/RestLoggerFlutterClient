import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import '../models/message.dart';
import '../utils/theme.dart';
import '../utils/json_helper.dart';
import 'fullscreen_view.dart';

class MessageCard extends StatefulWidget {
  final Message message;
  final VoidCallback onPinToggle;
  final String? highlightText;
  final bool isCurrentMatch;

  const MessageCard({
    super.key,
    required this.message,
    required this.onPinToggle,
    this.highlightText,
    this.isCurrentMatch = false,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _showCopied = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyContent() async {
    await FlutterClipboard.copy(widget.message.displayContent);

    setState(() => _showCopied = true);
    _animationController.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _showCopied = false);
          _animationController.reverse();
        }
      });
    });
  }

  void _showFullscreen() {
    showDialog(
      context: context,
      builder: (context) => FullscreenView(message: widget.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: context.panelDecoration(radius: 26).copyWith(
                color: context.appPanel.withValues(alpha: 0.38),
                border: Border.all(
                  color: widget.message.isPinned
                      ? AppTheme.accent.withValues(alpha: 0.48)
                      : context.appBorder.withValues(alpha: 0.46),
                  width: widget.message.isPinned ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Row(
                        children: [
                          Text(
                            widget.message.formattedTime,
                            style: TextStyle(
                              color: context.appTextMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.accent.withValues(alpha: 0.24),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.message.moduleName,
                              style: const TextStyle(
                                color: Color(0xFF5A8FEC),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 80),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF09101D)
                              : const Color(0xFFF8FBFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1D2C45)
                                : const Color(0xFFD7E6F8),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: _buildHighlightedContent(),
                            ),
                            if (_isHovered)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildControlButton(
                                      icon: widget.message.isPinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined,
                                      color: widget.message.isPinned
                                          ? const Color(0xFF5A8FEC)
                                          : Colors.grey,
                                      tooltip: widget.message.isPinned
                                          ? 'Открепить'
                                          : 'Закрепить',
                                      onTap: widget.onPinToggle,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildControlButton(
                                      icon: _showCopied ? Icons.check : Icons.copy,
                                      color: _showCopied
                                          ? const Color(0xFF51CF66)
                                          : Colors.grey,
                                      tooltip: 'Копировать',
                                      onTap: _copyContent,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildControlButton(
                                      icon: Icons.open_in_full,
                                      color: Colors.grey,
                                      tooltip: 'Развернуть',
                                      onTap: _showFullscreen,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.message.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.accent.withValues(alpha: 0.24),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.accent.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.push_pin,
                                    size: 12,
                                    color: Color(0xFF5A8FEC),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Закреплено',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5A8FEC),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                        ),
                      ),
                    ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedContent() {
    final text = JsonHelper.formatContent(widget.message.displayContent);
    final query = widget.highlightText?.toLowerCase() ?? '';

    if (query.isEmpty) {
      return SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: context.isDarkMode
              ? const Color(0xFFDCE7F8)
              : const Color(0xFF21324B),
          height: 1.5,
        ),
      );
    }

    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    int lastIndex = 0;

    int searchIndex = 0;
    while ((searchIndex = textLower.indexOf(query, lastIndex)) != -1) {
      if (searchIndex > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, searchIndex),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: context.isDarkMode
                ? const Color(0xFFDCE7F8)
                : const Color(0xFF21324B),
            height: 1.5,
          ),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(searchIndex, searchIndex + query.length),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: const Color(0xFF09101D),
          backgroundColor: widget.isCurrentMatch
              ? const Color(0xFFFFD84D)
              : const Color(0xFFFFE892),
          height: 1.5,
          fontWeight:
              widget.isCurrentMatch ? FontWeight.bold : FontWeight.normal,
        ),
      ));

      lastIndex = searchIndex + query.length;
      searchIndex = lastIndex;
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: context.isDarkMode
              ? const Color(0xFFDCE7F8)
              : const Color(0xFF21324B),
          height: 1.5,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: context.panelDecoration(radius: 999).copyWith(
                color: context.appPanel.withValues(alpha: 0.92),
              ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}
