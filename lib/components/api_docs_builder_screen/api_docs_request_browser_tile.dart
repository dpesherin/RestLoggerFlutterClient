import 'package:flutter/material.dart';

import '../../models/api_documentation_project.dart';
import '../../utils/theme.dart';
import 'api_docs_common_widgets.dart';

class ApiDocsRequestBrowserTile extends StatelessWidget {
  final ApiRequestDefinition request;
  final String groupLabel;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const ApiDocsRequestBrowserTile({
    super.key,
    required this.request,
    required this.groupLabel,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: context.appPanel.withValues(alpha: 0.74),
          border: Border.all(
            color: context.appBorder.withValues(alpha: 0.32),
          ),
          boxShadow: context.appSoftShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ApiDocsMethodBadge(method: request.method),
                const Spacer(),
                IconButton(
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appTextMuted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ApiDocsTileTag(label: groupLabel),
                ApiDocsTileTag(label: '${request.responses.length} resp'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
