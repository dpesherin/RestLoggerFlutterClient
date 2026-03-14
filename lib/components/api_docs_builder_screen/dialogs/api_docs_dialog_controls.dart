import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/theme.dart';
import '../api_docs_common_widgets.dart';

class ApiDocsDialogLayout {
  static const EdgeInsets insetPadding = EdgeInsets.symmetric(
    horizontal: 48,
    vertical: 24,
  );

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(
    28,
    28,
    28,
    8,
  );

  static const EdgeInsets actionsPadding = EdgeInsets.fromLTRB(
    24,
    24,
    24,
    20,
  );

  static const double fieldSpacing = 18;
}

class ApiDocsJsonEditorFormatter extends TextInputFormatter {
  const ApiDocsJsonEditorFormatter();

  static const Map<String, String> _pairs = <String, String>{
    '{': '}',
    '[': ']',
    '(': ')',
    '"': '"',
  };

  static const Set<String> _closingChars = <String>{
    '}',
    ']',
    ')',
    '"',
  };

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final selection = oldValue.selection;
    if (!selection.isValid) {
      return newValue;
    }

    final insertedText = _extractInsertedText(oldValue, newValue);
    if (insertedText == null || insertedText.length != 1) {
      return newValue;
    }

    final insertedChar = insertedText;

    if (_pairs.containsKey(insertedChar)) {
      final start = selection.start;
      final end = selection.end;
      final selectedText = oldValue.text.substring(start, end);
      final closingChar = _pairs[insertedChar]!;
      final replacement = '$insertedChar$selectedText$closingChar';
      final updatedText = oldValue.text.replaceRange(start, end, replacement);
      final caretOffset = start + 1 + selectedText.length;

      return TextEditingValue(
        text: updatedText,
        selection: TextSelection.collapsed(offset: caretOffset),
      );
    }

    if (selection.isCollapsed &&
        _closingChars.contains(insertedChar) &&
        selection.start < oldValue.text.length &&
        oldValue.text[selection.start] == insertedChar) {
      return TextEditingValue(
        text: oldValue.text,
        selection: TextSelection.collapsed(offset: selection.start + 1),
      );
    }

    return newValue;
  }

  String? _extractInsertedText(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lengthDiff = newValue.text.length - oldValue.text.length;
    if (lengthDiff <= 0) {
      return null;
    }

    final start = oldValue.selection.start;
    if (start < 0 || start + lengthDiff > newValue.text.length) {
      return null;
    }

    return newValue.text.substring(start, start + lengthDiff);
  }
}

class ApiDocsDialogFieldBadge extends StatelessWidget {
  final String label;
  final Color color;

  const ApiDocsDialogFieldBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.34),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Widget buildApiDocsDialogTextField({
  required TextEditingController controller,
  required String label,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      alignLabelWithHint: maxLines > 1,
      border: const OutlineInputBorder(),
    ),
  );
}

Widget buildApiDocsJsonEditorField({
  required BuildContext context,
  required TextEditingController controller,
  required FocusNode focusNode,
  required String label,
}) {
  return Focus(
    canRequestFocus: false,
    onKeyEvent: (node, event) {
      if (event is! KeyDownEvent) {
        return KeyEventResult.ignored;
      }

      if (event.logicalKey == LogicalKeyboardKey.tab) {
        final selection = controller.selection;
        final text = controller.text;
        final start = selection.start >= 0 ? selection.start : text.length;
        final end = selection.end >= 0 ? selection.end : text.length;
        final replaced = text.replaceRange(start, end, '  ');
        controller.value = TextEditingValue(
          text: replaced,
          selection: TextSelection.collapsed(offset: start + 2),
        );
        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    },
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: 18,
      keyboardType: TextInputType.multiline,
      inputFormatters: const <TextInputFormatter>[ApiDocsJsonEditorFormatter()],
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
      ),
      cursorColor: Colors.white,
      style: TextStyle(
        color: context.appTextPrimary.withValues(alpha: 0.95),
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.45,
      ),
    ),
  );
}

Widget buildApiDocsJsonPreviewBlock(BuildContext context, String source) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.appPanelAlt.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: context.appBorder.withValues(alpha: 0.28),
      ),
    ),
    child: ApiDocsJsonCodeBlock(
      source: source,
      fontSize: 13,
    ),
  );
}

Widget buildApiDocsDialogCancelButton({
  required VoidCallback onPressed,
}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      minimumSize: const Size(132, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    child: const Text('Отмена'),
  );
}

Widget buildApiDocsDialogSubmitButton({
  required VoidCallback onPressed,
  required String label,
  bool isDanger = false,
}) {
  return FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: isDanger ? Colors.red : null,
      minimumSize: const Size(148, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    child: Text(label),
  );
}
