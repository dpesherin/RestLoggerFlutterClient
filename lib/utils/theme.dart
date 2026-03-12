import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import 'logger.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final savedTheme = await StorageService.getThemeMode();
      if (savedTheme != null) {
        _themeMode = savedTheme;
        notifyListeners();
      }
    } catch (e, stack) {
      logger.warning('Не удалось загрузить тему: $e');
      logger.debug(stack.toString());
    }
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await StorageService.saveThemeMode(_themeMode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await StorageService.saveThemeMode(_themeMode);
      notifyListeners();
    }
  }
}

class AppTheme {
  static const Color accent = Color(0xFF5A8FEC);
  static const Color accentDeep = Color(0xFF3567D6);
  static const Color accentSoft = Color(0xFF7AB0FF);
  static const Color darkBg = Color(0xFF0C1220);
  static const Color darkPanel = Color(0xFF121C2F);
  static const Color darkPanelAlt = Color(0xFF17253C);
  static const Color lightBg = Color(0xFFF3F7FD);
  static const Color lightPanel = Color(0xFFFFFFFF);
  static const Color lightPanelAlt = Color(0xFFE8F0FB);

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: accent,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: accent,
      secondary: accentSoft,
      surface: lightPanel,
      onSurface: Color(0xFF10203A),
      onPrimary: Colors.white,
      error: Color(0xFFD94B62),
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
      bodyColor: const Color(0xFF10203A),
      displayColor: const Color(0xFF10203A),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF10203A)),
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: const Color(0xFF10203A),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardColor: lightPanel,
    dividerColor: const Color(0xFFD6E2F3),
    dialogTheme: DialogThemeData(
      backgroundColor: lightPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF10203A),
      contentTextStyle: GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightPanel,
      hintStyle: GoogleFonts.spaceGrotesk(
        color: const Color(0xFF6A7A96),
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD4E1F2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD4E1F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: accent, width: 1.4),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF10203A),
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: accent,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accentSoft,
      surface: darkPanel,
      onSurface: Color(0xFFF4F7FC),
      onPrimary: Colors.white,
      error: Color(0xFFFF6E7F),
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme)
        .apply(
      bodyColor: const Color(0xFFF4F7FC),
      displayColor: const Color(0xFFF4F7FC),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFFF4F7FC)),
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: const Color(0xFFF4F7FC),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardColor: darkPanel,
    dividerColor: const Color(0xFF22324E),
    dialogTheme: DialogThemeData(
      backgroundColor: darkPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: darkPanelAlt,
      contentTextStyle: GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkPanelAlt,
      hintStyle: GoogleFonts.spaceGrotesk(
        color: const Color(0xFF8EA3C5),
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF22324E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF22324E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: accentSoft, width: 1.4),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFF4F7FC),
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground =>
      isDarkMode ? AppTheme.darkBg : AppTheme.lightBg;

  Color get appPanel =>
      isDarkMode ? AppTheme.darkPanel : AppTheme.lightPanel;

  Color get appPanelAlt =>
      isDarkMode ? AppTheme.darkPanelAlt : AppTheme.lightPanelAlt;

  Color get appTextPrimary =>
      isDarkMode ? const Color(0xFFF4F7FC) : const Color(0xFF10203A);

  Color get appTextMuted =>
      isDarkMode ? const Color(0xFF8EA3C5) : const Color(0xFF6A7A96);

  Color get appBorder =>
      isDarkMode ? const Color(0xFF22324E) : const Color(0xFFD4E1F2);

  List<BoxShadow> get appSoftShadow => isDarkMode
      ? [
          const BoxShadow(
            color: Color(0x66040A16),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ]
      : [
          const BoxShadow(
            color: Color(0x1A5A8FEC),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
          const BoxShadow(
            color: Color(0x0D10203A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ];

  List<BoxShadow> get appGlowShadow => [
        BoxShadow(
          color: AppTheme.accent.withValues(alpha: isDarkMode ? 0.24 : 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  Gradient get glassHighlightGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDarkMode ? 0.12 : 0.42),
          Colors.white.withValues(alpha: isDarkMode ? 0.05 : 0.16),
          Colors.white.withValues(alpha: 0.02),
        ],
      );

  LinearGradient get appAccentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.accentSoft, AppTheme.accent, AppTheme.accentDeep],
      );

  BoxDecoration panelDecoration({double radius = 24}) => BoxDecoration(
        color: appPanel.withValues(alpha: isDarkMode ? 0.72 : 0.68),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: appBorder.withValues(alpha: 0.42)),
        boxShadow: [
          ...appSoftShadow,
          BoxShadow(
            color: (isDarkMode ? Colors.white : AppTheme.accentSoft)
                .withValues(alpha: isDarkMode ? 0.05 : 0.08),
            blurRadius: 0,
            spreadRadius: 0.5,
          ),
        ],
      );
}
