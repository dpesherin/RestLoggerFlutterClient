import 'package:flutter/material.dart';

import '../../utils/theme.dart';

class MainScreenEmptyLogsState extends StatelessWidget {
  const MainScreenEmptyLogsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: context.appTextMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет сообщений',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ожидание сообщений от сервера...',
            style: TextStyle(
              fontSize: 14,
              color: context.appTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
