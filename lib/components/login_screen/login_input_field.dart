import 'package:flutter/material.dart';

import '../../utils/theme.dart';

class LoginInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final IconData icon;
  final bool obscureText;

  const LoginInputField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
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
}
