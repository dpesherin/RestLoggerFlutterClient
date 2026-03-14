import 'dart:ui';

import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import 'main_screen_toolbar_action.dart';

class MainScreenLogsToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onClearSearch;
  final VoidCallback onCopyAll;
  final VoidCallback onClearAll;

  const MainScreenLogsToolbar({
    super.key,
    required this.searchController,
    required this.onClearSearch,
    required this.onCopyAll,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: context.panelDecoration(radius: 24).copyWith(
                        color: context.appPanel.withValues(alpha: 0.4),
                      ),
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(
                      color: context.appTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Поиск по модулю...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppTheme.accent,
                                size: 18,
                              ),
                              onPressed: onClearSearch,
                            )
                          : null,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MainScreenToolbarAction(
            icon: Icons.copy_all_rounded,
            color: AppTheme.accent,
            onTap: onCopyAll,
          ),
          const SizedBox(width: 8),
          MainScreenToolbarAction(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFFF6B6B),
            onTap: onClearAll,
          ),
        ],
      ),
    );
  }
}
