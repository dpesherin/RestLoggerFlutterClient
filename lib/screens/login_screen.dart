import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/toast_widget.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      ToastWidget.show(
        context,
        message: 'Заполните все поля',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await ApiService.auth(
          _loginController.text,
          _passwordController.text,
        );
      } else {
        await ApiService.register(
          _loginController.text,
          _passwordController.text,
        );
      }

      if (!mounted) return;

      ToastWidget.show(
        context,
        message: _isLoginMode ? 'Вход выполнен' : 'Регистрация успешна',
        type: ToastType.success,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Ошибка: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.appBackground,
                    context.appPanelAlt,
                    context.appBackground,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -20,
            child: _buildGlowBlob(
              size: 220,
              color: AppTheme.accent.withValues(alpha: isDark ? 0.18 : 0.14),
            ),
          ),
          Positioned(
            right: -40,
            bottom: -120,
            child: _buildGlowBlob(
              size: 320,
              color: AppTheme.accentSoft.withValues(alpha: isDark ? 0.16 : 0.1),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(34),
                decoration: context.panelDecoration(radius: 32).copyWith(
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        'REALTIME LOG STREAM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: context.appTextMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '{..Logger..}',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Современный просмотр логов в реальном времени',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.appTextMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: context.appBackground.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: context.appBorder.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isLoginMode = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: _isLoginMode
                                      ? context.appAccentGradient
                                      : null,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: _isLoginMode
                                      ? context.appGlowShadow
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Вход',
                                    style: TextStyle(
                                      color: _isLoginMode
                                          ? Colors.white
                                          : context.appTextMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _isLoginMode = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  gradient: !_isLoginMode
                                      ? context.appAccentGradient
                                      : null,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: !_isLoginMode
                                      ? context.appGlowShadow
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Регистрация',
                                    style: TextStyle(
                                      color: !_isLoginMode
                                          ? Colors.white
                                          : context.appTextMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    _buildField(
                      context: context,
                      controller: _loginController,
                      enabled: !_isLoading,
                      hintText: 'Логин',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      context: context,
                      controller: _passwordController,
                      enabled: !_isLoading,
                      hintText: 'Пароль',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: context.appAccentGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: context.appGlowShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _isLoginMode
                                      ? 'Войти в консоль'
                                      : 'Создать аккаунт',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required bool enabled,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.appPanel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.9)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        style: TextStyle(color: context.appTextPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: AppTheme.accent),
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildGlowBlob({
    required double size,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
