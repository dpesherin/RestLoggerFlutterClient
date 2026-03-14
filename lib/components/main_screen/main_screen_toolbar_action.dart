import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/theme.dart';

class MainScreenToolbarAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;

  const MainScreenToolbarAction({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: context.panelDecoration(radius: 22).copyWith(
                  color: context.appPanel.withValues(alpha: 0.44),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.appPanel.withValues(alpha: 0.52),
                      context.appPanelAlt.withValues(alpha: 0.28),
                    ],
                  ),
                ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return child;

    return Tooltip(
      message: tooltip!,
      waitDuration: const Duration(milliseconds: 250),
      child: child,
    );
  }
}

class MainScreenSearchActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const MainScreenSearchActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: context.appPanelAlt.withValues(alpha: 0.56),
          foregroundColor: AppTheme.accent,
          disabledForegroundColor: context.appTextMuted,
          side: BorderSide(color: context.appBorder.withValues(alpha: 0.34)),
        ),
      ),
    );
  }
}
