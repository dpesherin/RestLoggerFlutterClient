import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/api_documentation_project.dart';
import '../../../utils/theme.dart';
import 'api_docs_dialog_controls.dart';

class ApiDocsBasicDialogs {
  static Future<ApiDocumentationProject?> showProjectDialog({
    required BuildContext context,
    required ApiDocumentationProject initial,
    required String Function(String) nextId,
    required void Function(String) showRequiredFieldMessage,
    bool isNew = false,
  }) async {
    final nameController = TextEditingController(text: initial.name);
    final descriptionController =
        TextEditingController(text: initial.description);
    final baseUrlController = TextEditingController(text: initial.baseUrl);

    final project = await showDialog<ApiDocumentationProject>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? 'Новый проект' : 'Редактировать проект'),
        insetPadding: ApiDocsDialogLayout.insetPadding,
        contentPadding: ApiDocsDialogLayout.contentPadding,
        actionsPadding: ApiDocsDialogLayout.actionsPadding,
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 640,
            maxWidth: 720,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildApiDocsDialogTextField(
                  controller: nameController,
                  label: 'Название проекта',
                ),
                const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                buildApiDocsDialogTextField(
                  controller: baseUrlController,
                  label: 'Base URL',
                ),
                const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                buildApiDocsDialogTextField(
                  controller: descriptionController,
                  label: 'Описание',
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        actions: [
          buildApiDocsDialogCancelButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          buildApiDocsDialogSubmitButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                showRequiredFieldMessage('Название проекта');
                return;
              }
              Navigator.of(context).pop(
                initial.copyWith(
                  id: isNew ? nextId('project') : initial.id,
                  name: name,
                  baseUrl: baseUrlController.text.trim(),
                  description: descriptionController.text.trim(),
                  createdAt: isNew ? DateTime.now() : initial.createdAt,
                  updatedAt: DateTime.now(),
                ),
              );
            },
            label: 'Сохранить',
          ),
        ],
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
    baseUrlController.dispose();
    return project;
  }

  static Future<ApiRequestDefinition?> showRequestDialog({
    required BuildContext context,
    required ApiRequestDefinition initial,
    required List<String> existingGroups,
    required List<String> methods,
    required List<String> bodyModes,
    required String ungroupedLabel,
    required String Function(String) normalizeGroupName,
    required String Function(String) bodyModeLabel,
    required String Function(String) nextId,
    required void Function(String) showRequiredFieldMessage,
    bool isNew = false,
  }) async {
    final nameController = TextEditingController(text: initial.name);
    final descriptionController =
        TextEditingController(text: initial.description);
    final pathController = TextEditingController(text: initial.path);
    final newGroupController = TextEditingController();
    var selectedMethod = initial.method;
    var selectedBodyMode = initial.bodyMode;
    var useProjectAuth = initial.useProjectAuth;
    final normalizedExistingGroups = existingGroups
        .map(normalizeGroupName)
        .where((group) => group.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    const createNewGroupValue = '__create_new_group__';
    var selectedGroup = initial.group.isEmpty
        ? ''
        : (normalizedExistingGroups.contains(initial.group)
            ? initial.group
            : (normalizedExistingGroups.isNotEmpty
                ? normalizedExistingGroups.first
                : createNewGroupValue));
    var createNewGroup = initial.group.isNotEmpty &&
        !normalizedExistingGroups.contains(initial.group);
    if (createNewGroup) {
      newGroupController.text = initial.group;
      selectedGroup = createNewGroupValue;
    }

    final request = await showDialog<ApiRequestDefinition>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isNew ? 'Новый запрос' : 'Редактировать запрос'),
          insetPadding: ApiDocsDialogLayout.insetPadding,
          contentPadding: ApiDocsDialogLayout.contentPadding,
          actionsPadding: ApiDocsDialogLayout.actionsPadding,
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 680,
              maxWidth: 780,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildApiDocsDialogTextField(
                    controller: nameController,
                    label: 'Название запроса',
                  ),
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMethod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Метод',
                      border: OutlineInputBorder(),
                    ),
                    items: methods
                        .map(
                          (method) => DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedMethod = value);
                    },
                  ),
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGroup,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Коллекция',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(ungroupedLabel),
                      ),
                      ...normalizedExistingGroups.map(
                        (group) => DropdownMenuItem<String>(
                          value: group,
                          child: Text(group.isEmpty ? ungroupedLabel : group),
                        ),
                      ),
                      const DropdownMenuItem<String>(
                        value: createNewGroupValue,
                        child: Text('Создать новую коллекцию'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedGroup = value;
                        createNewGroup = value == createNewGroupValue;
                      });
                    },
                  ),
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBodyMode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Тип тела запроса',
                      border: OutlineInputBorder(),
                    ),
                    items: bodyModes
                        .map(
                          (mode) => DropdownMenuItem<String>(
                            value: mode,
                            child: Text(bodyModeLabel(mode)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedBodyMode = value);
                    },
                  ),
                  if (createNewGroup) ...[
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: newGroupController,
                      label: 'Новая коллекция',
                    ),
                  ],
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                  buildApiDocsDialogTextField(
                    controller: pathController,
                    label: 'Path',
                  ),
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                  buildApiDocsDialogTextField(
                    controller: descriptionController,
                    label: 'Описание',
                    maxLines: 5,
                  ),
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Использовать auth проекта'),
                      subtitle: const Text(
                        'Возьмёт настройки авторизации из проекта по умолчанию',
                      ),
                      value: useProjectAuth,
                      onChanged: (value) =>
                          setState(() => useProjectAuth = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            buildApiDocsDialogCancelButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            buildApiDocsDialogSubmitButton(
              onPressed: () {
                final name = nameController.text.trim();
                final resolvedGroup = createNewGroup
                    ? normalizeGroupName(newGroupController.text)
                    : normalizeGroupName(selectedGroup);
                if (name.isEmpty) {
                  showRequiredFieldMessage('Название запроса');
                  return;
                }
                if (createNewGroup && resolvedGroup.isEmpty) {
                  showRequiredFieldMessage('Название коллекции');
                  return;
                }
                Navigator.of(context).pop(
                  initial.copyWith(
                    id: isNew ? nextId('request') : initial.id,
                    group: resolvedGroup,
                    name: name,
                    description: descriptionController.text.trim(),
                    method: selectedMethod,
                    path: pathController.text.trim(),
                    bodyMode: selectedBodyMode,
                    useProjectAuth: useProjectAuth,
                  ),
                );
              },
              label: 'Сохранить',
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
    pathController.dispose();
    newGroupController.dispose();
    return request;
  }

  static Future<String?> showCollectionDialog({
    required BuildContext context,
    required String Function(String) normalizeGroupName,
    required void Function(String) showRequiredFieldMessage,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая коллекция'),
        insetPadding: ApiDocsDialogLayout.insetPadding,
        contentPadding: ApiDocsDialogLayout.contentPadding,
        actionsPadding: ApiDocsDialogLayout.actionsPadding,
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 560,
            maxWidth: 640,
          ),
          child: buildApiDocsDialogTextField(
            controller: controller,
            label: 'Название коллекции',
          ),
        ),
        actions: [
          buildApiDocsDialogCancelButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          buildApiDocsDialogSubmitButton(
            onPressed: () {
              final value = normalizeGroupName(controller.text);
              if (value.isEmpty) {
                showRequiredFieldMessage('Название коллекции');
                return;
              }
              Navigator.of(context).pop(value);
            },
            label: 'Создать',
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  static Future<ApiAuthConfig?> showAuthDialog({
    required BuildContext context,
    required ApiAuthConfig initial,
    required List<String> authTypes,
    required List<String> apiKeyLocations,
  }) async {
    var authType = initial.type;
    final headerNameController =
        TextEditingController(text: initial.headerName);
    final schemeController = TextEditingController(text: initial.scheme);
    final tokenController = TextEditingController(text: initial.token);
    final usernameController = TextEditingController(text: initial.username);
    final passwordController = TextEditingController(text: initial.password);
    final apiKeyController = TextEditingController(text: initial.apiKey);
    final apiKeyNameController =
        TextEditingController(text: initial.apiKeyName);
    var apiKeyLocation = initial.apiKeyLocation;

    final config = await showDialog<ApiAuthConfig>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Настройки auth'),
          insetPadding: ApiDocsDialogLayout.insetPadding,
          contentPadding: ApiDocsDialogLayout.contentPadding,
          actionsPadding: ApiDocsDialogLayout.actionsPadding,
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 640,
              maxWidth: 720,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: authType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Тип auth',
                      border: OutlineInputBorder(),
                    ),
                    items: authTypes
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => authType = value);
                    },
                  ),
                  if (authType == 'bearer') ...[
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: headerNameController,
                      label: 'Имя header',
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: schemeController,
                      label: 'Схема',
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: tokenController,
                      label: 'Токен / placeholder',
                    ),
                  ],
                  if (authType == 'basic') ...[
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: usernameController,
                      label: 'Username',
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: passwordController,
                      label: 'Password',
                    ),
                  ],
                  if (authType == 'apiKey') ...[
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: apiKeyNameController,
                      label: 'Имя ключа',
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    DropdownButtonFormField<String>(
                      initialValue: apiKeyLocation,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Расположение ключа',
                        border: OutlineInputBorder(),
                      ),
                      items: apiKeyLocations
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => apiKeyLocation = value);
                      },
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: apiKeyController,
                      label: 'Значение / placeholder',
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            buildApiDocsDialogCancelButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            buildApiDocsDialogSubmitButton(
              onPressed: () {
                Navigator.of(context).pop(
                  initial.copyWith(
                    type: authType,
                    headerName: headerNameController.text.trim().isEmpty
                        ? 'Authorization'
                        : headerNameController.text.trim(),
                    scheme: schemeController.text.trim().isEmpty
                        ? 'Bearer'
                        : schemeController.text.trim(),
                    token: tokenController.text.trim(),
                    username: usernameController.text.trim(),
                    password: passwordController.text.trim(),
                    apiKey: apiKeyController.text.trim(),
                    apiKeyLocation: apiKeyLocation,
                    apiKeyName: apiKeyNameController.text.trim().isEmpty
                        ? 'X-API-Key'
                        : apiKeyNameController.text.trim(),
                  ),
                );
              },
              label: 'Сохранить',
            ),
          ],
        ),
      ),
    );

    headerNameController.dispose();
    schemeController.dispose();
    tokenController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    apiKeyController.dispose();
    apiKeyNameController.dispose();
    return config;
  }

  static Future<ApiKeyValueEntry?> showHeaderDialog({
    required BuildContext context,
    required void Function(String) showRequiredFieldMessage,
    ApiKeyValueEntry? initial,
  }) async {
    final current = initial ?? const ApiKeyValueEntry(key: '', value: '');
    final keyController = TextEditingController(text: current.key);
    final valueController = TextEditingController(text: current.value);
    var enabled = current.enabled;

    final entry = await showDialog<ApiKeyValueEntry>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Header'),
          insetPadding: ApiDocsDialogLayout.insetPadding,
          contentPadding: ApiDocsDialogLayout.contentPadding,
          actionsPadding: ApiDocsDialogLayout.actionsPadding,
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 560,
              maxWidth: 640,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildApiDocsDialogTextField(
                  controller: keyController,
                  label: 'Ключ',
                ),
                const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                buildApiDocsDialogTextField(
                  controller: valueController,
                  label: 'Значение',
                ),
                const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Активен'),
                    value: enabled,
                    onChanged: (value) => setState(() => enabled = value),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            buildApiDocsDialogCancelButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            buildApiDocsDialogSubmitButton(
              onPressed: () {
                if (keyController.text.trim().isEmpty) {
                  showRequiredFieldMessage('Ключ');
                  return;
                }
                Navigator.of(context).pop(
                  current.copyWith(
                    key: keyController.text.trim(),
                    value: valueController.text.trim(),
                    enabled: enabled,
                  ),
                );
              },
              label: 'Сохранить',
            ),
          ],
        ),
      ),
    );

    keyController.dispose();
    valueController.dispose();
    return entry;
  }

  static Future<ApiDictionaryEntry?> showDictionaryEntryDialog({
    required BuildContext context,
    required void Function(String) showRequiredFieldMessage,
    ApiDictionaryEntry? initial,
  }) async {
    final current = initial ??
        const ApiDictionaryEntry(
          value: '',
          description: '',
        );
    final valueController = TextEditingController(text: current.value);
    final descriptionController =
        TextEditingController(text: current.description);

    final result = await showDialog<ApiDictionaryEntry>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(initial == null ? 'Новое значение' : 'Редактировать значение'),
        insetPadding: ApiDocsDialogLayout.insetPadding,
        contentPadding: ApiDocsDialogLayout.contentPadding,
        actionsPadding: ApiDocsDialogLayout.actionsPadding,
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 560,
            maxWidth: 640,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildApiDocsDialogTextField(
                controller: valueController,
                label: 'Значение',
              ),
              const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
              buildApiDocsDialogTextField(
                controller: descriptionController,
                label: 'Расшифровка',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          buildApiDocsDialogCancelButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          buildApiDocsDialogSubmitButton(
            onPressed: () {
              final value = valueController.text.trim();
              final description = descriptionController.text.trim();
              if (value.isEmpty) {
                showRequiredFieldMessage('Значение');
                return;
              }
              if (description.isEmpty) {
                showRequiredFieldMessage('Расшифровка');
                return;
              }
              Navigator.of(context).pop(
                current.copyWith(
                  value: value,
                  description: description,
                ),
              );
            },
            label: 'Сохранить',
          ),
        ],
      ),
    );

    valueController.dispose();
    descriptionController.dispose();
    return result;
  }

  static Future<String?> showJsonTemplateDialog({
    required BuildContext context,
    required String initialValue,
    required void Function(String) showRequiredFieldMessage,
  }) async {
    final controller = TextEditingController(
      text: initialValue.trim().isEmpty
          ? const JsonEncoder.withIndent('  ').convert(<String, dynamic>{})
          : initialValue,
    );
    final focusNode = FocusNode();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON шаблон body'),
        insetPadding: ApiDocsDialogLayout.insetPadding,
        contentPadding: ApiDocsDialogLayout.contentPadding,
        actionsPadding: ApiDocsDialogLayout.actionsPadding,
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 760,
            maxWidth: 900,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Укажи JSON объекта запроса. После сохранения конструктор пересоберёт поля тела из этого шаблона.',
                    style: TextStyle(color: context.appTextMuted),
                  ),
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing + 2),
                  buildApiDocsJsonEditorField(
                    context: context,
                    controller: controller,
                    focusNode: focusNode,
                    label: 'JSON',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          buildApiDocsDialogCancelButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          buildApiDocsDialogSubmitButton(
            onPressed: () {
              final raw = controller.text.trim();
              if (raw.isEmpty) {
                showRequiredFieldMessage('JSON');
                return;
              }
              try {
                final decoded = jsonDecode(raw);
                if (decoded is! Map<String, dynamic>) {
                  showRequiredFieldMessage(
                    'JSON body должен быть объектом верхнего уровня',
                  );
                  return;
                }
                Navigator.of(context).pop(
                  const JsonEncoder.withIndent('  ').convert(decoded),
                );
              } catch (_) {
                showRequiredFieldMessage('JSON содержит ошибку');
              }
            },
            label: 'Сохранить',
          ),
        ],
      ),
    );

    controller.dispose();
    focusNode.dispose();
    return result;
  }

  static Future<ApiResponseDefinition?> showResponseDialog({
    required BuildContext context,
    required ApiResponseDefinition initial,
  }) async {
    final statusController =
        TextEditingController(text: initial.statusCode.toString());
    final descriptionController =
        TextEditingController(text: initial.description);
    final bodyController = TextEditingController(text: initial.bodyExample);
    final bodyFocusNode = FocusNode();

    final response = await showDialog<ApiResponseDefinition>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статус ответа'),
        insetPadding: ApiDocsDialogLayout.insetPadding,
        contentPadding: ApiDocsDialogLayout.contentPadding,
        actionsPadding: ApiDocsDialogLayout.actionsPadding,
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 680,
            maxWidth: 760,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildApiDocsDialogTextField(
                  controller: statusController,
                  label: 'HTTP статус',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                buildApiDocsDialogTextField(
                  controller: descriptionController,
                  label: 'Описание',
                ),
                const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                buildApiDocsJsonEditorField(
                  context: context,
                  controller: bodyController,
                  focusNode: bodyFocusNode,
                  label: 'Пример тела ответа',
                ),
              ],
            ),
          ),
        ),
        actions: [
          buildApiDocsDialogCancelButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          buildApiDocsDialogSubmitButton(
            onPressed: () {
              final statusCode =
                  int.tryParse(statusController.text.trim()) ?? 200;
              Navigator.of(context).pop(
                initial.copyWith(
                  statusCode: statusCode,
                  description: descriptionController.text.trim().isEmpty
                      ? 'Описание ответа'
                      : descriptionController.text.trim(),
                  bodyExample: bodyController.text.trim(),
                ),
              );
            },
            label: 'Сохранить',
          ),
        ],
      ),
    );

    statusController.dispose();
    descriptionController.dispose();
    bodyController.dispose();
    bodyFocusNode.dispose();
    return response;
  }
}
