import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import 'main_screen_toolbar_action.dart';

class MainScreenSearchOverlay extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final int currentMatchIndex;
  final int matchCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onClose;

  const MainScreenSearchOverlay({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.currentMatchIndex,
    required this.matchCount,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
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
                          focusNode: focusNode,
                          controller: controller,
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
                    if (controller.text.isNotEmpty) ...[
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
                          matchCount == 0
                              ? '0 из 0'
                              : '${currentMatchIndex + 1} из $matchCount',
                          style: TextStyle(
                            fontSize: 11,
                            color: matchCount == 0
                                ? Colors.redAccent
                                : context.appTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      MainScreenSearchActionButton(
                        icon: Icons.keyboard_arrow_up_rounded,
                        onPressed: onPrevious,
                      ),
                      const SizedBox(width: 6),
                      MainScreenSearchActionButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onPressed: onNext,
                      ),
                      const SizedBox(width: 6),
                    ],
                    MainScreenSearchActionButton(
                      icon: Icons.close_rounded,
                      onPressed: onClose,
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
}
