import 'package:flutter/material.dart';

Future<void> showMainScreenClearMessagesDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Очистить все сообщения?'),
      content: const Text('Это действие нельзя отменить'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text(
            'Очистить',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

Future<bool> showMainScreenLogoutConfirmDialog({
  required BuildContext context,
  required bool allDevices,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        allDevices ? 'Выйти со всех устройств?' : 'Выход из аккаунта',
      ),
      content: Text(
        allDevices
            ? 'Вы будете разлогинены на всех устройствах, включая текущее.'
            : 'Вы уверены, что хотите выйти?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(allDevices ? 'Выйти со всех' : 'Выйти'),
        ),
      ],
    ),
  );

  return result == true;
}

Future<void> showMainScreenBlockingProgressDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}
