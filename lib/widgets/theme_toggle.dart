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
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1E24) : const Color(0xFFE0E5EC),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(3, 3),
            ),
            BoxShadow(
              color: isDark ? const Color(0xFF2C313A) : Colors.white,
              blurRadius: 6,
              offset: const Offset(-3, -3),
            ),
          ],
        ),
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: isDark ? Colors.white : const Color(0xFF2D4059),
          size: 20,
        ),
      ),
    );
  }
}
