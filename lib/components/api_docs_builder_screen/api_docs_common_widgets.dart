import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import '../../utils/theme.dart';

final Map<String, TextStyle> _jsonHighlightTheme = <String, TextStyle>{
  ...atomOneDarkTheme,
  'root': (atomOneDarkTheme['root'] ?? const TextStyle()).copyWith(
    backgroundColor: Colors.transparent,
    color: const Color(0xFFE8EEF9),
  ),
};

class ApiDocsJsonCodeBlock extends StatelessWidget {
  final String source;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const ApiDocsJsonCodeBlock({
    super.key,
    required this.source,
    this.padding = EdgeInsets.zero,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = source.trim().isEmpty ? '{\n  \n}' : source;

    return HighlightView(
      normalized,
      language: 'json',
      theme: _jsonHighlightTheme,
      padding: padding,
      textStyle: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        height: 1.45,
      ),
    );
  }
}

class ApiDocsSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onAdd;
  final Widget child;
  final Widget? extraAction;

  const ApiDocsSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onAdd,
    required this.child,
    this.extraAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: context.panelDecoration(radius: 28).copyWith(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.appPanel.withValues(alpha: 0.95),
                context.appPanelAlt.withValues(alpha: 0.92),
              ],
            ),
          ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: context.appTextMuted),
                    ),
                  ],
                ),
              ),
              if (extraAction != null) ...[
                extraAction!,
                const SizedBox(width: 8),
              ],
              if (onAdd != null)
                FilledButton.tonalIcon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class ApiDocsWorkspaceEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const ApiDocsWorkspaceEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: context.panelDecoration(radius: 30).copyWith(
            color: context.appPanel.withValues(alpha: 0.8),
          ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              subtitle,
              style: TextStyle(
                color: context.appTextMuted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class ApiDocsEmptySidebarNote extends StatelessWidget {
  final String label;

  const ApiDocsEmptySidebarNote({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appPanel.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.appTextMuted,
          height: 1.4,
        ),
      ),
    );
  }
}

class ApiDocsHeroInfoChip extends StatelessWidget {
  final String label;

  const ApiDocsHeroInfoChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ApiDocsTileTag extends StatelessWidget {
  final String label;

  const ApiDocsTileTag({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.appPanelAlt.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.appTextMuted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ApiDocsMethodBadge extends StatelessWidget {
  final String method;
  final bool large;

  const ApiDocsMethodBadge({
    super.key,
    required this.method,
    this.large = false,
  });

  Color _color(BuildContext context) {
    switch (method) {
      case 'POST':
        return Colors.green;
      case 'PUT':
      case 'PATCH':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10,
        vertical: large ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: _color(context).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: _color(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
