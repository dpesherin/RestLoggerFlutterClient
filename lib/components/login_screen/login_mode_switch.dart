import 'package:flutter/material.dart';

import '../../utils/theme.dart';

class LoginModeSwitch extends StatelessWidget {
  final bool isLoginMode;
  final ValueChanged<bool> onChanged;

  const LoginModeSwitch({
    super.key,
    required this.isLoginMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              onTap: () => onChanged(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: isLoginMode ? context.appAccentGradient : null,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isLoginMode ? context.appGlowShadow : null,
                ),
                child: Center(
                  child: Text(
                    'Вход',
                    style: TextStyle(
                      color: isLoginMode ? Colors.white : context.appTextMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: !isLoginMode ? context.appAccentGradient : null,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: !isLoginMode ? context.appGlowShadow : null,
                ),
                child: Center(
                  child: Text(
                    'Регистрация',
                    style: TextStyle(
                      color: !isLoginMode ? Colors.white : context.appTextMuted,
                      fontWeight: FontWeight.w700,
                    ),
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
