import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../widgets/message_card.dart';

List<Widget> buildMainScreenMessageList({
  required List<Message> pinnedMessages,
  required List<Message> unpinnedMessages,
  required List<Message> matchedMessages,
  required int currentMatchIndex,
  required String findQuery,
  required void Function(Message message) onPinToggle,
}) {
  final widgets = <Widget>[];

  for (final msg in pinnedMessages) {
    final isCurrentMatch =
        matchedMessages.isNotEmpty && matchedMessages[currentMatchIndex] == msg;
    widgets.add(
      MessageCard(
        message: msg,
        onPinToggle: () => onPinToggle(msg),
        highlightText: _resolveHighlightText(
          message: msg,
          findQuery: findQuery,
          isCurrentMatch: isCurrentMatch,
        ),
        isCurrentMatch: isCurrentMatch,
      ),
    );
  }

  if (pinnedMessages.isNotEmpty && unpinnedMessages.isNotEmpty) {
    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFF5A8FEC),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Новые',
                style: TextStyle(
                  color: Color(0xFF5A8FEC),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFF5A8FEC),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  for (final msg in unpinnedMessages) {
    final isCurrentMatch =
        matchedMessages.isNotEmpty && matchedMessages[currentMatchIndex] == msg;
    widgets.add(
      MessageCard(
        message: msg,
        onPinToggle: () => onPinToggle(msg),
        highlightText: _resolveHighlightText(
          message: msg,
          findQuery: findQuery,
          isCurrentMatch: isCurrentMatch,
        ),
        isCurrentMatch: isCurrentMatch,
      ),
    );
  }

  return widgets;
}

String? _resolveHighlightText({
  required Message message,
  required String findQuery,
  required bool isCurrentMatch,
}) {
  if (findQuery.isEmpty) {
    return null;
  }
  if (isCurrentMatch) {
    return findQuery;
  }
  if (message.displayContent.toLowerCase().contains(findQuery.toLowerCase())) {
    return findQuery;
  }
  return null;
}
