import 'package:flutter/material.dart';

import '../../models/api_documentation_project.dart';
import '../../utils/theme.dart';

class ApiDocsSidebarIconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDanger;

  const ApiDocsSidebarIconAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? const Color(0xFFD94B62) : AppTheme.accent;
    return InkWell(
      onTap: onTap,
      onHover: (_) {},
      borderRadius: BorderRadius.circular(999),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 250),
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class ApiDocsProjectTile extends StatelessWidget {
  final ApiDocumentationProject project;
  final bool selected;
  final VoidCallback onTap;

  const ApiDocsProjectTile({
    super.key,
    required this.project,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? AppTheme.accent.withValues(
                  alpha: context.isDarkMode ? 0.18 : 0.12,
                )
              : context.appPanel.withValues(alpha: 0.68),
          border: Border.all(
            color: selected
                ? AppTheme.accent.withValues(alpha: 0.35)
                : context.appBorder.withValues(alpha: 0.26),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              project.baseUrl.isEmpty ? 'Без base URL' : project.baseUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appTextMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiDocsCollectionListTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ApiDocsCollectionListTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.12)
              : context.appPanel.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppTheme.accent.withValues(alpha: 0.28)
                : context.appBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.layers_outlined,
              size: 16,
              color: selected ? AppTheme.accentDeep : AppTheme.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Удалить коллекцию',
                waitDuration: const Duration(milliseconds: 250),
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD94B62).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD94B62).withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Color(0xFFD94B62),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
