import 'package:flutter/material.dart';

import '../../../models/api_documentation_project.dart';
import '../../../utils/theme.dart';
import '../api_docs_builder_helpers.dart';
import 'api_docs_dialog_controls.dart';

class ApiDocsPathParamDialogResult {
  final ApiParameterDefinition parameter;
  final String path;

  const ApiDocsPathParamDialogResult({
    required this.parameter,
    required this.path,
  });
}

class ApiDocsFieldDialogs {
  static Future<ApiParameterDefinition?> showParameterDialog({
    required BuildContext context,
    required String Function(String) nextId,
    required void Function(String) showRequiredFieldMessage,
    required List<String> fieldTypes,
    required List<String> dictionaryValueTypes,
    ApiParameterDefinition? initial,
    bool forceRequired = false,
    List<String> availableTypes = const <String>[],
    bool allowArray = true,
    required Future<ApiDictionaryEntry?> Function({
      ApiDictionaryEntry? initial,
    }) showDictionaryEntryDialog,
  }) async {
    final current = initial ??
        ApiParameterDefinition(
          id: nextId('param'),
          name: '',
          description: '',
          type: 'string',
          required: forceRequired,
          isArray: false,
          arrayItemType: 'string',
          arrayItemDescription: '',
          arrayItemExample: '',
          example: '',
          isDictionary: false,
          dictionaryEntries: const <ApiDictionaryEntry>[],
        );

    return _showFieldDialog<ApiParameterDefinition>(
      context: context,
      title: forceRequired ? 'Path parameter' : 'Параметр запроса',
      initialName: current.name,
      initialDescription: current.description,
      initialType: current.type,
      initialRequired: forceRequired ? true : current.required,
      initialIsArray: current.isArray,
      initialExample: current.example,
      initialArrayItemType: current.arrayItemType,
      initialArrayItemDescription: current.arrayItemDescription,
      initialArrayItemExample: current.arrayItemExample,
      initialIsDictionary: current.isDictionary,
      initialDictionaryEntries: current.dictionaryEntries,
      availableTypes: availableTypes.isEmpty ? fieldTypes : availableTypes,
      dictionaryValueTypes: dictionaryValueTypes,
      allowArray: allowArray,
      forceRequired: forceRequired,
      showRequiredFieldMessage: showRequiredFieldMessage,
      showDictionaryEntryDialog: showDictionaryEntryDialog,
      onSubmit: ({
        required name,
        required description,
        required type,
        required isRequired,
        required isArray,
        required example,
        required arrayItemType,
        required arrayItemDescription,
        required arrayItemExample,
        required isDictionary,
        required dictionaryEntries,
      }) {
        return current.copyWith(
          name: name,
          description: description,
          type: type,
          required: forceRequired ? true : isRequired,
          isArray: isArray,
          arrayItemType: arrayItemType,
          arrayItemDescription: arrayItemDescription,
          arrayItemExample: arrayItemExample,
          example: example,
          isDictionary: isDictionary,
          dictionaryEntries: dictionaryEntries,
        );
      },
    );
  }

  static Future<ApiDocsPathParamDialogResult?> showPathParameterDialog({
    required BuildContext context,
    required String Function(String) nextId,
    required void Function(String) showRequiredFieldMessage,
    required Future<ApiDictionaryEntry?> Function({
      ApiDictionaryEntry? initial,
    }) showDictionaryEntryDialog,
    required List<String> pathFieldTypes,
    required List<String> dictionaryValueTypes,
    ApiParameterDefinition? initial,
    required String requestPath,
    required List<String> existingParamNames,
  }) async {
    final current = initial ??
        ApiParameterDefinition(
          id: nextId('param'),
          name: '',
          description: '',
          type: 'string',
          required: true,
          isArray: false,
          arrayItemType: 'string',
          arrayItemDescription: '',
          arrayItemExample: '',
          example: '',
          isDictionary: false,
          dictionaryEntries: const <ApiDictionaryEntry>[],
        );

    final nameController = TextEditingController(text: current.name);
    final descriptionController =
        TextEditingController(text: current.description);
    final exampleController = TextEditingController(text: current.example);
    final dictionaryEntries = <ApiDictionaryEntry>[
      ...current.dictionaryEntries
    ];
    var selectedType = pathFieldTypes.contains(current.type)
        ? current.type
        : pathFieldTypes.first;
    var isDictionary = current.isDictionary;
    final existingPlaceholder =
        current.name.isEmpty ? null : '{${current.name}}';
    var insertionMode =
        existingPlaceholder != null && requestPath.contains(existingPlaceholder)
            ? 'keep'
            : 'append';

    final result = await showDialog<ApiDocsPathParamDialogResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final previewName = nameController.text.trim().isEmpty
              ? 'param'
              : nameController.text.trim();
          final previewPlaceholder = '{$previewName}';
          final insertionOptions = buildApiDocsPathInsertionOptions(
            requestPath: requestPath,
            hasExistingPlacement: existingPlaceholder != null &&
                requestPath.contains(existingPlaceholder),
          );
          if (!insertionOptions.any((option) => option.$1 == insertionMode)) {
            insertionMode = insertionOptions.first.$1;
          }

          return AlertDialog(
            title: const Text('Path parameter'),
            insetPadding: ApiDocsDialogLayout.insetPadding,
            contentPadding: ApiDocsDialogLayout.contentPadding,
            actionsPadding: ApiDocsDialogLayout.actionsPadding,
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 700,
                maxWidth: 780,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildApiDocsDialogTextField(
                      controller: nameController,
                      label: 'Имя параметра',
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: descriptionController,
                      label: 'Описание параметра',
                      maxLines: 3,
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Тип',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          (isDictionary ? dictionaryValueTypes : pathFieldTypes)
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedType = value);
                      },
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Справочник'),
                        value: isDictionary,
                        onChanged: (value) => setState(() {
                          isDictionary = value;
                          if (value &&
                              !dictionaryValueTypes.contains(selectedType)) {
                            selectedType = dictionaryValueTypes.first;
                          }
                        }),
                      ),
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    DropdownButtonFormField<String>(
                      initialValue: insertionMode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Место вставки в URL',
                        border: OutlineInputBorder(),
                      ),
                      items: insertionOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.$1,
                              child: Text(option.$2),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => insertionMode = value);
                      },
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    if (!isDictionary)
                      buildApiDocsDialogTextField(
                        controller: exampleController,
                        label: 'Пример значения',
                      ),
                    if (isDictionary) ...[
                      const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                      Text(
                        'Справочник значений',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (dictionaryEntries.isEmpty)
                        const Text('Добавьте значения справочника.')
                      else
                        Column(
                          children: [
                            for (var i = 0; i < dictionaryEntries.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  tileColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  title: Text(dictionaryEntries[i].value),
                                  subtitle:
                                      Text(dictionaryEntries[i].description),
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          final updated =
                                              await showDictionaryEntryDialog(
                                            initial: dictionaryEntries[i],
                                          );
                                          if (updated == null) return;
                                          setState(() {
                                            dictionaryEntries[i] = updated;
                                          });
                                        },
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        onPressed: () => setState(() {
                                          dictionaryEntries.removeAt(i);
                                        }),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final entry = await showDictionaryEntryDialog();
                            if (entry == null) return;
                            setState(() {
                              dictionaryEntries.add(entry);
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить значение'),
                        ),
                      ),
                    ],
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    Container(
                      padding: const EdgeInsets.all(14),
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
                            'Предпросмотр URL-шаблона',
                            style: TextStyle(
                              color: context.appTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            previewApiDocsPathWithInsertion(
                              requestPath: requestPath,
                              oldParamName: initial?.name,
                              newPlaceholder: previewPlaceholder,
                              insertionMode: insertionMode,
                            ),
                            style: TextStyle(
                              color: context.appTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                  if (name.isEmpty) {
                    showRequiredFieldMessage('Имя параметра');
                    return;
                  }
                  if (existingParamNames.contains(name)) {
                    showRequiredFieldMessage(
                      'Path param с таким именем уже существует',
                    );
                    return;
                  }
                  if (isDictionary && dictionaryEntries.isEmpty) {
                    showRequiredFieldMessage(
                      'Добавьте хотя бы одно значение справочника',
                    );
                    return;
                  }

                  Navigator.of(context).pop(
                    ApiDocsPathParamDialogResult(
                      parameter: current.copyWith(
                        name: name,
                        description: descriptionController.text.trim(),
                        type: selectedType,
                        required: true,
                        isArray: false,
                        arrayItemType: 'string',
                        arrayItemDescription: '',
                        arrayItemExample: '',
                        example:
                            isDictionary ? '' : exampleController.text.trim(),
                        isDictionary: isDictionary,
                        dictionaryEntries: isDictionary
                            ? List<ApiDictionaryEntry>.from(dictionaryEntries)
                            : const <ApiDictionaryEntry>[],
                      ),
                      path: previewApiDocsPathWithInsertion(
                        requestPath: requestPath,
                        oldParamName: initial?.name,
                        newPlaceholder: '{$name}',
                        insertionMode: insertionMode,
                      ),
                    ),
                  );
                },
                label: 'Сохранить',
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
    exampleController.dispose();
    return result;
  }

  static Future<ApiBodyFieldDefinition?> showBodyFieldDialog({
    required BuildContext context,
    required String Function(String) nextId,
    required void Function(String) showRequiredFieldMessage,
    required Future<ApiDictionaryEntry?> Function({
      ApiDictionaryEntry? initial,
    }) showDictionaryEntryDialog,
    required List<String> fieldTypes,
    required List<String> pathFieldTypes,
    required List<String> dictionaryValueTypes,
    required Color Function(String) fieldBadgeColor,
    ApiBodyFieldDefinition? initial,
    required String bodyMode,
  }) async {
    final current = initial ??
        ApiBodyFieldDefinition(
          id: nextId('body'),
          name: '',
          description: '',
          type: 'string',
          required: false,
          isArray: false,
          arrayItemType: 'string',
          arrayItemDescription: '',
          arrayItemExample: '',
          example: '',
          isDictionary: false,
          dictionaryEntries: const <ApiDictionaryEntry>[],
          children: const <ApiBodyFieldDefinition>[],
        );

    final isJsonMode = bodyMode == 'json';
    final availableTypes =
        isJsonMode ? fieldTypes : <String>[...pathFieldTypes, 'array'];
    final allowArray = bodyMode != 'none';

    final nameController = TextEditingController(text: current.name);
    final descriptionController =
        TextEditingController(text: current.description);
    final exampleController = TextEditingController(text: current.example);
    final arrayItemDescriptionController =
        TextEditingController(text: current.arrayItemDescription);
    final arrayItemExampleController =
        TextEditingController(text: current.arrayItemExample);
    var selectedType = allowArray && current.isArray
        ? 'array'
        : (availableTypes.contains(current.type)
            ? current.type
            : availableTypes.first);
    var required = current.required;
    var arrayItemType =
        current.arrayItemType.isEmpty ? 'string' : current.arrayItemType;
    var isDictionary = current.isDictionary &&
        !(allowArray && current.isArray) &&
        current.type != 'object' &&
        dictionaryValueTypes.contains(current.type);
    final dictionaryEntries = <ApiDictionaryEntry>[
      ...current.dictionaryEntries
    ];
    final children = <ApiBodyFieldDefinition>[...current.children];

    final arrayItemTypes =
        availableTypes.where((type) => type != 'array').toList();
    if (!arrayItemTypes.contains(arrayItemType)) {
      arrayItemType = arrayItemTypes.first;
    }

    bool isArray() => allowArray && selectedType == 'array';

    bool supportsDictionary() =>
        !isArray() &&
        selectedType != 'object' &&
        selectedType != 'array' &&
        dictionaryValueTypes.contains(selectedType);

    bool showsExample() =>
        !isArray() && selectedType != 'object' && !isDictionary;

    bool showsNestedChildren() =>
        isJsonMode &&
        (selectedType == 'object' || (isArray() && arrayItemType == 'object'));

    final result = await showDialog<ApiBodyFieldDefinition>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isJsonMode ? 'Поле JSON body' : 'Поле тела запроса',
          ),
          insetPadding: ApiDocsDialogLayout.insetPadding,
          contentPadding: ApiDocsDialogLayout.contentPadding,
          actionsPadding: ApiDocsDialogLayout.actionsPadding,
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 720,
              maxWidth: 820,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildApiDocsDialogTextField(
                      controller: nameController,
                      label: 'Имя поля',
                    ),
                    const SizedBox(
                        height: ApiDocsDialogLayout.fieldSpacing + 2),
                    buildApiDocsDialogTextField(
                      controller: descriptionController,
                      label: 'Описание поля',
                      maxLines: 3,
                    ),
                    const SizedBox(
                        height: ApiDocsDialogLayout.fieldSpacing + 2),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Тип',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          (isDictionary ? dictionaryValueTypes : availableTypes)
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedType = value;
                          if (value == 'object' || value == 'array') {
                            isDictionary = false;
                          }
                          if (!supportsDictionary()) {
                            isDictionary = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(
                        height: ApiDocsDialogLayout.fieldSpacing + 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          if (supportsDictionary())
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Справочник'),
                              value: isDictionary,
                              onChanged: (value) => setState(() {
                                isDictionary = value;
                                if (value &&
                                    !dictionaryValueTypes
                                        .contains(selectedType)) {
                                  selectedType = dictionaryValueTypes.first;
                                }
                              }),
                            ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Обязательное поле'),
                            value: required,
                            onChanged: (value) =>
                                setState(() => required = value),
                          ),
                        ],
                      ),
                    ),
                    if (isArray()) ...[
                      const SizedBox(
                          height: ApiDocsDialogLayout.fieldSpacing + 4),
                      DropdownButtonFormField<String>(
                        initialValue: arrayItemType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Тип элемента списка',
                          border: OutlineInputBorder(),
                        ),
                        items: arrayItemTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            arrayItemType = value;
                            if (value == 'object') {
                              isDictionary = false;
                            }
                          });
                        },
                      ),
                      if (arrayItemType != 'object') ...[
                        const SizedBox(
                          height: ApiDocsDialogLayout.fieldSpacing + 2,
                        ),
                        buildApiDocsDialogTextField(
                          controller: arrayItemDescriptionController,
                          label: 'Описание элемента',
                          maxLines: 3,
                        ),
                        const SizedBox(
                          height: ApiDocsDialogLayout.fieldSpacing + 2,
                        ),
                        buildApiDocsDialogTextField(
                          controller: arrayItemExampleController,
                          label: 'Пример элемента',
                          maxLines: 2,
                        ),
                      ],
                    ],
                    if (showsExample()) ...[
                      const SizedBox(
                          height: ApiDocsDialogLayout.fieldSpacing + 2),
                      buildApiDocsDialogTextField(
                        controller: exampleController,
                        label: 'Пример значения',
                        maxLines: 2,
                      ),
                    ],
                    if (isDictionary) ...[
                      const SizedBox(
                          height: ApiDocsDialogLayout.fieldSpacing + 4),
                      Text(
                        'Справочник значений',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (dictionaryEntries.isEmpty)
                        const Text('Добавьте значения справочника.')
                      else
                        Column(
                          children: [
                            for (var i = 0; i < dictionaryEntries.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  tileColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  title: Text(dictionaryEntries[i].value),
                                  subtitle:
                                      Text(dictionaryEntries[i].description),
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          final updated =
                                              await showDictionaryEntryDialog(
                                            initial: dictionaryEntries[i],
                                          );
                                          if (updated == null) return;
                                          setState(() =>
                                              dictionaryEntries[i] = updated);
                                        },
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        onPressed: () => setState(() =>
                                            dictionaryEntries.removeAt(i)),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final entry = await showDictionaryEntryDialog();
                            if (entry == null) return;
                            setState(() => dictionaryEntries.add(entry));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить значение'),
                        ),
                      ),
                    ],
                    if (showsNestedChildren()) ...[
                      const SizedBox(height: 24),
                      Text(
                        selectedType == 'object'
                            ? 'Поля объекта'
                            : 'Поля объекта в элементе массива',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (children.isEmpty)
                        Text(
                          selectedType == 'object'
                              ? 'Вложенные поля ещё не добавлены.'
                              : 'Поля объекта внутри элемента массива ещё не добавлены.',
                        )
                      else
                        Column(
                          children: [
                            for (var i = 0; i < children.length; i++)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 10, 14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: context.appBorder
                                        .withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                children[i].name,
                                                style: TextStyle(
                                                  color: context.appTextPrimary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              if (children[i].isArray) ...[
                                                const ApiDocsDialogFieldBadge(
                                                  label: 'array',
                                                  color: Color(0xFF0F8D9D),
                                                ),
                                                Text(
                                                  'of',
                                                  style: TextStyle(
                                                    color: context.appTextMuted,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                ApiDocsDialogFieldBadge(
                                                  label:
                                                      children[i].arrayItemType,
                                                  color: fieldBadgeColor(
                                                    children[i].arrayItemType,
                                                  ),
                                                ),
                                              ] else
                                                ApiDocsDialogFieldBadge(
                                                  label: children[i].type,
                                                  color: fieldBadgeColor(
                                                    children[i].type,
                                                  ),
                                                ),
                                              if (children[i].required)
                                                const ApiDocsDialogFieldBadge(
                                                  label: 'required',
                                                  color: Color(0xFFB84C62),
                                                ),
                                              if (children[i].isDictionary)
                                                const ApiDocsDialogFieldBadge(
                                                  label: 'dict',
                                                  color: Color(0xFFE4A646),
                                                ),
                                            ],
                                          ),
                                          if (children[i]
                                              .description
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              children[i].description,
                                              style: TextStyle(
                                                color: context.appTextMuted,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                          if (children[i].isDictionary &&
                                              children[i]
                                                  .dictionaryEntries
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: context.appPanelAlt
                                                    .withValues(alpha: 0.28),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: context.appBorder
                                                      .withValues(alpha: 0.24),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Справочник значений',
                                                    style: TextStyle(
                                                      color:
                                                          context.appTextMuted,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  for (var j = 0;
                                                      j <
                                                          children[i]
                                                              .dictionaryEntries
                                                              .length;
                                                      j++) ...[
                                                    Text.rich(
                                                      TextSpan(
                                                        children: [
                                                          TextSpan(
                                                            text: children[i]
                                                                .dictionaryEntries[
                                                                    j]
                                                                .value,
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                  0xFFE4A646),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                ' - ${children[i].dictionaryEntries[j].description}',
                                                            style: TextStyle(
                                                              color: context
                                                                  .appTextPrimary
                                                                  .withValues(
                                                                alpha: 0.92,
                                                              ),
                                                              fontSize: 14,
                                                              height: 1.35,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (j !=
                                                        children[i]
                                                                .dictionaryEntries
                                                                .length -
                                                            1)
                                                      const SizedBox(height: 6),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            final updated =
                                                await showBodyFieldDialog(
                                              context: context,
                                              initial: children[i],
                                              bodyMode: 'json',
                                              nextId: nextId,
                                              showRequiredFieldMessage:
                                                  showRequiredFieldMessage,
                                              showDictionaryEntryDialog:
                                                  showDictionaryEntryDialog,
                                              fieldTypes: fieldTypes,
                                              pathFieldTypes: pathFieldTypes,
                                              dictionaryValueTypes:
                                                  dictionaryValueTypes,
                                              fieldBadgeColor: fieldBadgeColor,
                                            );
                                            if (updated == null) return;
                                            setState(
                                                () => children[i] = updated);
                                          },
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          onPressed: () => setState(
                                            () => children.removeAt(i),
                                          ),
                                          icon:
                                              const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            final child = await showBodyFieldDialog(
                              context: context,
                              bodyMode: 'json',
                              nextId: nextId,
                              showRequiredFieldMessage:
                                  showRequiredFieldMessage,
                              showDictionaryEntryDialog:
                                  showDictionaryEntryDialog,
                              fieldTypes: fieldTypes,
                              pathFieldTypes: pathFieldTypes,
                              dictionaryValueTypes: dictionaryValueTypes,
                              fieldBadgeColor: fieldBadgeColor,
                            );
                            if (child == null) return;
                            setState(() => children.add(child));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить вложенное поле'),
                        ),
                      ),
                    ],
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  showRequiredFieldMessage('Имя поля');
                  return;
                }
                if (isDictionary && dictionaryEntries.isEmpty) {
                  showRequiredFieldMessage(
                    'Добавьте хотя бы одно значение справочника',
                  );
                  return;
                }
                if (showsNestedChildren() && children.isEmpty) {
                  showRequiredFieldMessage(
                    selectedType == 'object'
                        ? 'Добавьте хотя бы одно вложенное поле объекта'
                        : 'Добавьте хотя бы одно поле для объекта в массиве',
                  );
                  return;
                }

                Navigator.of(context).pop(
                  current.copyWith(
                    name: name,
                    description: descriptionController.text.trim(),
                    type: selectedType,
                    required: required,
                    isArray: isArray(),
                    arrayItemType: isArray() ? arrayItemType : 'string',
                    arrayItemDescription: isArray() && arrayItemType != 'object'
                        ? arrayItemDescriptionController.text.trim()
                        : '',
                    arrayItemExample: isArray() && arrayItemType != 'object'
                        ? arrayItemExampleController.text.trim()
                        : '',
                    example:
                        showsExample() ? exampleController.text.trim() : '',
                    isDictionary: isDictionary,
                    dictionaryEntries: isDictionary
                        ? List<ApiDictionaryEntry>.from(dictionaryEntries)
                        : const <ApiDictionaryEntry>[],
                    children: showsNestedChildren()
                        ? List<ApiBodyFieldDefinition>.from(children)
                        : const <ApiBodyFieldDefinition>[],
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
    exampleController.dispose();
    arrayItemDescriptionController.dispose();
    arrayItemExampleController.dispose();
    return result;
  }

  static Future<T?> _showFieldDialog<T>({
    required BuildContext context,
    required String title,
    required String initialName,
    required String initialDescription,
    required String initialType,
    required bool initialRequired,
    required bool initialIsArray,
    required String initialExample,
    required String initialArrayItemType,
    required String initialArrayItemDescription,
    required String initialArrayItemExample,
    required bool initialIsDictionary,
    required List<ApiDictionaryEntry> initialDictionaryEntries,
    required List<String> availableTypes,
    required List<String> dictionaryValueTypes,
    required bool allowArray,
    required void Function(String) showRequiredFieldMessage,
    required Future<ApiDictionaryEntry?> Function({
      ApiDictionaryEntry? initial,
    }) showDictionaryEntryDialog,
    bool forceRequired = false,
    required T Function({
      required String name,
      required String description,
      required String type,
      required bool isRequired,
      required bool isArray,
      required String example,
      required String arrayItemType,
      required String arrayItemDescription,
      required String arrayItemExample,
      required bool isDictionary,
      required List<ApiDictionaryEntry> dictionaryEntries,
    }) onSubmit,
  }) async {
    final nameController = TextEditingController(text: initialName);
    final descriptionController =
        TextEditingController(text: initialDescription);
    final exampleController = TextEditingController(text: initialExample);
    final arrayItemDescriptionController =
        TextEditingController(text: initialArrayItemDescription);
    final arrayItemExampleController =
        TextEditingController(text: initialArrayItemExample);
    var selectedType = allowArray && initialIsArray ? 'array' : initialType;
    var required = initialRequired;
    var arrayItemType = initialArrayItemType;
    var isDictionary = initialIsDictionary && !(allowArray && initialIsArray);
    final dictionaryEntries = <ApiDictionaryEntry>[...initialDictionaryEntries];

    if (!availableTypes.contains(selectedType)) {
      selectedType = availableTypes.first;
    }
    if (!allowArray && selectedType == 'array') {
      selectedType = availableTypes.first;
    }
    if (isDictionary && !dictionaryValueTypes.contains(selectedType)) {
      selectedType = dictionaryValueTypes.first;
    }
    final arrayItemTypes =
        availableTypes.where((type) => type != 'array').toList();
    if (!arrayItemTypes.contains(arrayItemType)) {
      arrayItemType = arrayItemTypes.first;
    }
    bool isArray() => allowArray && selectedType == 'array';

    final result = await showDialog<T>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
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
                    controller: nameController,
                    label: 'Имя поля',
                  ),
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                  buildApiDocsDialogTextField(
                    controller: descriptionController,
                    label: 'Описание поля',
                    maxLines: 3,
                  ),
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Тип',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        (isDictionary ? dictionaryValueTypes : availableTypes)
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedType = value;
                        if (value == 'array') {
                          isDictionary = false;
                        }
                      });
                    },
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
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Справочник'),
                          value: isDictionary,
                          onChanged: (value) => setState(() {
                            isDictionary = value;
                            if (value &&
                                !dictionaryValueTypes.contains(selectedType)) {
                              selectedType = dictionaryValueTypes.first;
                            }
                          }),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Обязательное поле'),
                          value: forceRequired ? true : required,
                          onChanged: forceRequired
                              ? null
                              : (value) => setState(() => required = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                  if (!isDictionary && !isArray())
                    buildApiDocsDialogTextField(
                      controller: exampleController,
                      label: 'Пример значения',
                      maxLines: 2,
                    ),
                  if (isDictionary) ...[
                    Text(
                      'Справочник значений',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (dictionaryEntries.isEmpty)
                      const Text('Добавьте значения справочника.')
                    else
                      Column(
                        children: [
                          for (var i = 0; i < dictionaryEntries.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                tileColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                title: Text(dictionaryEntries[i].value),
                                subtitle:
                                    Text(dictionaryEntries[i].description),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        final updated =
                                            await showDictionaryEntryDialog(
                                          initial: dictionaryEntries[i],
                                        );
                                        if (updated == null) return;
                                        setState(() {
                                          dictionaryEntries[i] = updated;
                                        });
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() {
                                        dictionaryEntries.removeAt(i);
                                      }),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          final entry = await showDictionaryEntryDialog();
                          if (entry == null) return;
                          setState(() {
                            dictionaryEntries.add(entry);
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить значение'),
                      ),
                    ),
                  ],
                  if (isArray()) ...[
                    const SizedBox(height: 22),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Описание элемента списка',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    DropdownButtonFormField<String>(
                      initialValue: arrayItemType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Тип элемента списка',
                        border: OutlineInputBorder(),
                      ),
                      items: arrayItemTypes
                          .map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => arrayItemType = value);
                      },
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: arrayItemDescriptionController,
                      label: 'Описание элемента',
                      maxLines: 3,
                    ),
                    const SizedBox(height: ApiDocsDialogLayout.fieldSpacing),
                    buildApiDocsDialogTextField(
                      controller: arrayItemExampleController,
                      label: 'Пример элемента',
                      maxLines: 2,
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
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  showRequiredFieldMessage('Имя поля');
                  return;
                }
                if (isDictionary && dictionaryEntries.isEmpty) {
                  showRequiredFieldMessage(
                    'Добавьте хотя бы одно значение справочника',
                  );
                  return;
                }
                Navigator.of(context).pop(
                  onSubmit(
                    name: name,
                    description: descriptionController.text.trim(),
                    type: selectedType,
                    isRequired: forceRequired ? true : required,
                    isArray: isArray(),
                    example: isDictionary || isArray()
                        ? ''
                        : exampleController.text.trim(),
                    arrayItemType: isArray() ? arrayItemType : 'string',
                    arrayItemDescription: isArray()
                        ? arrayItemDescriptionController.text.trim()
                        : '',
                    arrayItemExample:
                        isArray() ? arrayItemExampleController.text.trim() : '',
                    isDictionary: isDictionary,
                    dictionaryEntries: isDictionary
                        ? List<ApiDictionaryEntry>.from(dictionaryEntries)
                        : const <ApiDictionaryEntry>[],
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
    exampleController.dispose();
    arrayItemDescriptionController.dispose();
    arrayItemExampleController.dispose();
    return result;
  }
}
