import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return InkWell(
      onTap: themeProvider.toggleTheme,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 46,
        height: 46,
        decoration: context.panelDecoration(radius: 999).copyWith(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.appPanel.withValues(alpha: 0.95),
                  context.appPanelAlt.withValues(alpha: 0.86),
                ],
              ),
            ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) =>
              RotationTransition(turns: animation, child: child),
          child: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            key: ValueKey<bool>(isDark),
            color: isDark ? Colors.white : const Color(0xFF2D4059),
            size: 20,
          ),
        ),
      ),
    );
  }
}
