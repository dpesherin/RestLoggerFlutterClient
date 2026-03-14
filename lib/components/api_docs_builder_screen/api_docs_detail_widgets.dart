import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_docs_common_widgets.dart';
import '../../models/api_documentation_project.dart';
import '../../utils/theme.dart';

class ApiDocsAuthPreview extends StatelessWidget {
  final ApiAuthConfig config;

  const ApiDocsAuthPreview({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final entries = switch (config.type) {
      'bearer' => <MapEntry<String, String>>[
          const MapEntry<String, String>('Тип', 'bearer'),
          MapEntry<String, String>('Header', config.headerName),
          MapEntry<String, String>('Scheme', config.scheme),
          if (config.token.isNotEmpty)
            MapEntry<String, String>('Token', config.token),
        ],
      'basic' => <MapEntry<String, String>>[
          const MapEntry<String, String>('Тип', 'basic'),
          MapEntry<String, String>(
            'Username',
            config.username.isEmpty ? '-' : config.username,
          ),
          MapEntry<String, String>(
            'Password',
            config.password.isEmpty ? '-' : '***',
          ),
        ],
      'apiKey' => <MapEntry<String, String>>[
          const MapEntry<String, String>('Тип', 'apiKey'),
          MapEntry<String, String>('Имя ключа', config.apiKeyName),
          MapEntry<String, String>('Где передавать', config.apiKeyLocation),
          if (config.apiKey.isNotEmpty)
            MapEntry<String, String>('Значение', config.apiKey),
        ],
      _ => <MapEntry<String, String>>[
          const MapEntry<String, String>('Тип', 'none'),
        ],
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appPanelAlt.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.appBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Подгруженные параметры авторизации',
            style: TextStyle(
              color: context.appTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in entries) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: context.appTextMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    entry.value,
                    style: TextStyle(
                      color: context.appTextPrimary.withValues(alpha: 0.92),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (entry != entries.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class ApiDocsKeyValueTile extends StatelessWidget {
  final ApiKeyValueEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ApiDocsKeyValueTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = entry.value.isEmpty ? 'Без значения' : entry.value;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          entry.enabled
              ? Icons.check_circle_outline
              : Icons.pause_circle_outline,
          color: entry.enabled ? Colors.green : Colors.orange,
        ),
        title: SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: entry.key,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ': ',
                style: TextStyle(
                  color: context.appTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: displayValue,
                style: TextStyle(
                  color: context.appTextPrimary.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiDocsFieldDefinitionTile extends StatelessWidget {
  final String name;
  final String type;
  final String description;
  final bool required;
  final bool isArray;
  final String example;
  final String arrayItemType;
  final String arrayItemDescription;
  final String arrayItemExample;
  final bool isDictionary;
  final List<ApiDictionaryEntry> dictionaryEntries;
  final List<ApiBodyFieldDefinition> children;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ApiDocsFieldDefinitionTile({
    super.key,
    required this.name,
    required this.type,
    required this.description,
    required this.required,
    required this.isArray,
    required this.example,
    required this.arrayItemType,
    required this.arrayItemDescription,
    required this.arrayItemExample,
    required this.isDictionary,
    required this.dictionaryEntries,
    required this.children,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: context.appTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isArray)
                              _ArrayOfBadges(itemType: arrayItemType)
                            else
                              _FieldBadge(
                                label: type,
                                backgroundColor: _typeBadgeColor(type),
                              ),
                            if (required) ...[
                              const SizedBox(width: 8),
                              const _FieldBadge(
                                label: 'required',
                                backgroundColor: Color(0xFFB84C62),
                              ),
                            ],
                            if (isDictionary) ...[
                              const SizedBox(width: 8),
                              const _FieldBadge(
                                label: 'dict',
                                backgroundColor: Color(0xFFE4A646),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            color: context.appTextMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (isDictionary && dictionaryEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DictionaryInfoBlock(entries: dictionaryEntries),
            ] else if (example.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FieldInfoBlock(
                label: 'Пример',
                value: example,
              ),
            ],
            if (isArray) ...[
              const SizedBox(height: 12),
              _FieldInfoBlock(
                label: 'Элемент списка',
                value: arrayItemType,
              ),
              if (arrayItemDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  arrayItemDescription,
                  style: TextStyle(
                    color: context.appTextMuted,
                    height: 1.4,
                  ),
                ),
              ],
              if (arrayItemExample.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _FieldInfoBlock(
                    label: 'Пример элемента',
                    value: arrayItemExample,
                  ),
                ),
            ],
            if (children.isNotEmpty) ...[
              const SizedBox(height: 12),
              _NestedBodyFieldsBlock(
                title: isArray && arrayItemType == 'object'
                    ? 'Поля объекта в массиве'
                    : 'Вложенные поля',
                fields: children,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _typeBadgeColor(String value) {
    return _typeBadgeColorFor(value);
  }
}

class _NestedBodyFieldsBlock extends StatelessWidget {
  final String title;
  final List<ApiBodyFieldDefinition> fields;

  const _NestedBodyFieldsBlock({
    required this.title,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appPanelAlt.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appBorder.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.appTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          for (final field in fields) ...[
            _NestedBodyFieldRow(field: field),
            if (field != fields.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _NestedBodyFieldRow extends StatelessWidget {
  final ApiBodyFieldDefinition field;

  const _NestedBodyFieldRow({
    required this.field,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                field.name,
                style: TextStyle(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (field.isArray)
                _ArrayOfBadges(itemType: field.arrayItemType)
              else
                _FieldBadge(
                  label: field.type,
                  backgroundColor: _nestedTypeBadgeColor(field.type),
                ),
              if (field.required)
                const _FieldBadge(
                  label: 'required',
                  backgroundColor: Color(0xFFB84C62),
                ),
              if (field.isDictionary)
                const _FieldBadge(
                  label: 'dict',
                  backgroundColor: Color(0xFFE4A646),
                ),
            ],
          ),
          if (field.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              field.description,
              style: TextStyle(
                color: context.appTextMuted,
                height: 1.4,
              ),
            ),
          ],
          if (field.isDictionary && field.dictionaryEntries.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DictionaryInfoBlock(entries: field.dictionaryEntries),
          ],
          if (field.children.isNotEmpty) ...[
            const SizedBox(height: 10),
            _NestedBodyFieldsBlock(
              title: field.isArray && field.arrayItemType == 'object'
                  ? 'Поля объекта в массиве'
                  : 'Вложенные поля',
              fields: field.children,
            ),
          ],
        ],
      ),
    );
  }

  Color _nestedTypeBadgeColor(String value) {
    return _typeBadgeColorFor(value);
  }
}

class _ArrayOfBadges extends StatelessWidget {
  final String itemType;

  const _ArrayOfBadges({
    required this.itemType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _FieldBadge(
          label: 'array',
          backgroundColor: AppTheme.accentDeep,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'of',
            style: TextStyle(
              color: context.appTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        _FieldBadge(
          label: itemType,
          backgroundColor: _typeBadgeColorFor(itemType),
        ),
      ],
    );
  }
}

Color _typeBadgeColorFor(String value) {
  switch (value) {
    case 'string':
      return const Color(0xFF3F7AE0);
    case 'integer':
    case 'number':
      return const Color(0xFF1F9D72);
    case 'boolean':
      return const Color(0xFFB77A1A);
    case 'object':
      return const Color(0xFF7A56D6);
    case 'array':
      return const Color(0xFF0F8D9D);
    default:
      return AppTheme.accent;
  }
}

class ApiDocsPathParamTile extends StatelessWidget {
  final String requestPath;
  final String name;
  final String type;
  final String description;
  final String example;
  final bool isDictionary;
  final List<ApiDictionaryEntry> dictionaryEntries;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ApiDocsPathParamTile({
    super.key,
    required this.requestPath,
    required this.name,
    required this.type,
    required this.description,
    required this.example,
    required this.isDictionary,
    required this.dictionaryEntries,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = '{$name}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: context.appTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _FieldBadge(
                            label: type,
                            backgroundColor: const Color(0xFF3F7AE0),
                          ),
                          const SizedBox(width: 8),
                          const _FieldBadge(
                            label: 'path',
                            backgroundColor: AppTheme.accentDeep,
                          ),
                          if (isDictionary) ...[
                            const SizedBox(width: 8),
                            const _FieldBadge(
                              label: 'dict',
                              backgroundColor: Color(0xFFE4A646),
                            ),
                          ],
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            color: context.appTextMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RichFieldInfoBlock(
              label: 'Вставка в URL',
              content: requestPath.contains(placeholder)
                  ? TextSpan(
                      children: _buildPathPreviewSpans(
                        context,
                        requestPath,
                        placeholder,
                      ),
                    )
                  : TextSpan(
                      children: [
                        TextSpan(
                          text: requestPath,
                          style: TextStyle(
                            color:
                                context.appTextPrimary.withValues(alpha: 0.92),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.35,
                          ),
                        ),
                        TextSpan(
                          text: '  нет явной вставки $placeholder',
                          style: const TextStyle(
                            color: Color(0xFFE4A646),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
            ),
            if (isDictionary && dictionaryEntries.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DictionaryInfoBlock(entries: dictionaryEntries),
            ] else if (example.isNotEmpty) ...[
              const SizedBox(height: 10),
              _FieldInfoBlock(
                label: 'Пример значения',
                value: example,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildPathPreviewSpans(
    BuildContext context,
    String requestPath,
    String placeholder,
  ) {
    final parts = requestPath.split(placeholder);
    final spans = <InlineSpan>[];

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: TextStyle(
              color: context.appTextPrimary.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        );
      }

      if (i < parts.length - 1) {
        spans.add(
          const TextSpan(
            text: '{',
            style: TextStyle(
              color: Color(0xFFE4A646),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        );
        spans.add(
          TextSpan(
            text: placeholder.substring(1, placeholder.length - 1),
            style: const TextStyle(
              color: Color(0xFFE4A646),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        );
        spans.add(
          const TextSpan(
            text: '}',
            style: TextStyle(
              color: Color(0xFFE4A646),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        );
      }
    }

    return spans;
  }
}

class _FieldBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _FieldBadge({
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.34),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: backgroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FieldInfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _FieldInfoBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isJson = _looksLikeJson(value);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appPanelAlt.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.appTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          if (isJson)
            ApiDocsJsonCodeBlock(
              source: value,
              fontSize: 13,
            )
          else
            SelectableText(
              value,
              style: TextStyle(
                color: context.appTextPrimary.withValues(alpha: 0.92),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}

class _RichFieldInfoBlock extends StatelessWidget {
  final String label;
  final TextSpan content;

  const _RichFieldInfoBlock({
    required this.label,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appPanelAlt.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.appTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText.rich(content),
        ],
      ),
    );
  }
}

class _DictionaryInfoBlock extends StatelessWidget {
  final List<ApiDictionaryEntry> entries;

  const _DictionaryInfoBlock({
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appPanelAlt.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Справочник значений',
            style: TextStyle(
              color: context.appTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < entries.length; i++) ...[
            SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: entries[i].value,
                    style: const TextStyle(
                      color: Color(0xFFE4A646),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: ' - ${entries[i].description}',
                    style: TextStyle(
                      color: context.appTextPrimary.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (i != entries.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class ApiDocsResponseTile extends StatelessWidget {
  final ApiResponseDefinition response;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ApiDocsResponseTile({
    super.key,
    required this.response,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text('${response.statusCode}')),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.description,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (response.bodyExample.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _looksLikeJson(response.bodyExample)
                    ? ApiDocsJsonCodeBlock(
                        source: response.bodyExample,
                        fontSize: 13,
                      )
                    : SelectableText(response.bodyExample),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _looksLikeJson(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) return false;

  try {
    jsonDecode(trimmed);
    return true;
  } catch (_) {
    return false;
  }
}
