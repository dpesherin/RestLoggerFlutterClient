import 'package:flutter/material.dart';

class ModalGuardService {
  ModalGuardService._();

  static final Map<String, bool> _openState = <String, bool>{};

  static void reset() {
    _openState.clear();
  }

  static Future<T?> showGuarded<T>(
    BuildContext context,
    String modalType,
    Widget modal, {
    bool barrierDismissible = true,
  }) async {
    if (_openState[modalType] == true) {
      return null;
    }

    _openState[modalType] = true;

    try {
      return await showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => PopScope(
          onPopInvokedWithResult: (_, __) {
            _openState[modalType] = false;
          },
          child: modal,
        ),
      );
    } finally {
      _openState[modalType] = false;
    }
  }
}
