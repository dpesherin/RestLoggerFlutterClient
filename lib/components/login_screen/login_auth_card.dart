import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import 'login_input_field.dart';
import 'login_mode_switch.dart';

class LoginAuthCard extends StatelessWidget {
  final bool isLoginMode;
  final bool isLoading;
  final TextEditingController loginController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onSubmit;

  const LoginAuthCard({
    super.key,
    required this.isLoginMode,
    required this.isLoading,
    required this.loginController,
    required this.passwordController,
    required this.onModeChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          LoginModeSwitch(
            isLoginMode: isLoginMode,
            onChanged: onModeChanged,
          ),
          const SizedBox(height: 26),
          LoginInputField(
            controller: loginController,
            enabled: !isLoading,
            hintText: 'Логин',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          LoginInputField(
            controller: passwordController,
            enabled: !isLoading,
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
                onPressed: isLoading ? null : onSubmit,
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
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        isLoginMode ? 'Войти в консоль' : 'Создать аккаунт',
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
    );
  }
}
