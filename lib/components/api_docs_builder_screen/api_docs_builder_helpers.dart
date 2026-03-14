import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/api_documentation_project.dart';
import '../../utils/theme.dart';

String displayApiDocsGroupName(
  String value, {
  required String Function(String) normalizeGroupName,
  required String ungroupedLabel,
}) {
  final normalized = normalizeGroupName(value);
  return normalized.isEmpty ? ungroupedLabel : normalized;
}

List<ApiBodyFieldDefinition> buildApiDocsBodyFieldsFromJsonObject(
  Map<String, dynamic> object, {
  required String Function(String) nextId,
}) {
  return object.entries
      .map(
        (entry) => _bodyFieldFromJson(
          entry.key,
          entry.value,
          nextId: nextId,
        ),
      )
      .toList();
}

ApiBodyFieldDefinition _bodyFieldFromJson(
  String name,
  dynamic value, {
  required String Function(String) nextId,
}) {
  if (value is Map<String, dynamic>) {
    return ApiBodyFieldDefinition(
      id: nextId('body'),
      name: name,
      description: '',
      type: 'object',
      required: false,
      isArray: false,
      arrayItemType: 'string',
      arrayItemDescription: '',
      arrayItemExample: '',
      example: '',
      isDictionary: false,
      dictionaryEntries: const <ApiDictionaryEntry>[],
      children: buildApiDocsBodyFieldsFromJsonObject(
        value,
        nextId: nextId,
      ),
    );
  }

  if (value is List) {
    final first = value.isNotEmpty ? value.first : null;
    if (first is Map<String, dynamic>) {
      return ApiBodyFieldDefinition(
        id: nextId('body'),
        name: name,
        description: '',
        type: 'array',
        required: false,
        isArray: true,
        arrayItemType: 'object',
        arrayItemDescription: '',
        arrayItemExample: '',
        example: '',
        isDictionary: false,
        dictionaryEntries: const <ApiDictionaryEntry>[],
        children: buildApiDocsBodyFieldsFromJsonObject(
          first,
          nextId: nextId,
        ),
      );
    }

    final itemType = inferApiDocsPrimitiveBodyType(first);
    return ApiBodyFieldDefinition(
      id: nextId('body'),
      name: name,
      description: '',
      type: 'array',
      required: false,
      isArray: true,
      arrayItemType: itemType,
      arrayItemDescription: '',
      arrayItemExample: first == null ? '' : '$first',
      example: '',
      isDictionary: false,
      dictionaryEntries: const <ApiDictionaryEntry>[],
      children: const <ApiBodyFieldDefinition>[],
    );
  }

  final primitiveType = inferApiDocsPrimitiveBodyType(value);
  return ApiBodyFieldDefinition(
    id: nextId('body'),
    name: name,
    description: '',
    type: primitiveType,
    required: false,
    isArray: false,
    arrayItemType: 'string',
    arrayItemDescription: '',
    arrayItemExample: '',
    example: value == null ? '' : '$value',
    isDictionary: false,
    dictionaryEntries: const <ApiDictionaryEntry>[],
    children: const <ApiBodyFieldDefinition>[],
  );
}

String inferApiDocsPrimitiveBodyType(dynamic value) {
  if (value is bool) return 'boolean';
  if (value is int) return 'integer';
  if (value is num) return 'number';
  if (value is Map<String, dynamic>) return 'object';
  if (value is List) return 'array';
  return 'string';
}

ApiResponseDefinition createEmptyApiDocsResponse({
  required String Function(String) nextId,
}) {
  return ApiResponseDefinition(
    id: nextId('response'),
    statusCode: 200,
    description: 'Успешный ответ',
    bodyExample: const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'success': true,
    }),
  );
}

ApiRequestDefinition createEmptyApiDocsRequest(
  int index, {
  required String Function(String) nextId,
  required String Function(String) normalizeGroupName,
  String? group,
}) {
  return ApiRequestDefinition(
    id: nextId('request'),
    group: normalizeGroupName(group ?? ''),
    name: 'Новый запрос ${index + 1}',
    description: '',
    method: 'GET',
    path: '/resource',
    bodyMode: 'none',
    headers: const <ApiKeyValueEntry>[],
    queryParams: const <ApiParameterDefinition>[],
    pathParams: const <ApiParameterDefinition>[],
    bodyFields: const <ApiBodyFieldDefinition>[],
    requestBody: '',
    responses: <ApiResponseDefinition>[
      createEmptyApiDocsResponse(nextId: nextId),
    ],
    useProjectAuth: true,
    authConfig: ApiAuthConfig.empty,
  );
}

String apiDocsPathPlaceholder(String paramName) => '{$paramName}';

bool apiDocsPathContainsPlaceholder(String requestPath, String paramName) {
  return normalizeApiDocsRequestPath(requestPath)
      .contains(apiDocsPathPlaceholder(paramName));
}

String resolveApiDocsPathPlaceholder({
  required String requestPath,
  required String? oldParamName,
  required String newParamName,
}) {
  final normalizedPath = normalizeApiDocsRequestPath(requestPath);
  final newPlaceholder = apiDocsPathPlaceholder(newParamName);

  if (oldParamName != null && oldParamName.isNotEmpty) {
    final oldPlaceholder = apiDocsPathPlaceholder(oldParamName);
    if (normalizedPath.contains(oldPlaceholder)) {
      return normalizeApiDocsRequestPath(
        normalizedPath.replaceAll(oldPlaceholder, newPlaceholder),
      );
    }
  }
  return normalizedPath;
}

String removeApiDocsPathPlaceholder(String path, String paramName) {
  final placeholder = '{$paramName}';
  final segments = normalizeApiDocsRequestPath(path)
      .split('/')
      .where((item) => item.isNotEmpty && item != placeholder)
      .toList();

  if (segments.isEmpty) {
    return '/';
  }

  return '/${segments.join('/')}';
}

String normalizeApiDocsRequestPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '/';
  return trimmed.startsWith('/') ? trimmed : '/$trimmed';
}

String apiDocsBodyModeLabel(String mode) {
  switch (mode) {
    case 'json':
      return 'JSON';
    case 'form-data':
      return 'form-data';
    case 'x-www-form-urlencoded':
      return 'x-www-form-urlencoded';
    case 'none':
    default:
      return 'Без тела';
  }
}

String apiDocsBodyModeHelpText(String mode) {
  switch (mode) {
    case 'json':
      return 'Сначала укажи JSON шаблон, затем при необходимости дополни описание его полей и вложенных объектов.';
    case 'form-data':
      return 'Для form-data используются простые поля, близкие по смыслу к path/query параметрам.';
    case 'x-www-form-urlencoded':
      return 'Для x-www-form-urlencoded используются простые поля без вложенных объектов.';
    case 'none':
    default:
      return 'Тело запроса не используется.';
  }
}

Color apiDocsFieldBadgeColor(String value) {
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
