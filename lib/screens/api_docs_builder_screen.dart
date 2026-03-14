import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../components/api_docs_builder_screen/api_docs_builder_helpers.dart';
import '../components/api_docs_builder_screen/api_docs_common_widgets.dart';
import '../components/api_docs_builder_screen/api_docs_detail_widgets.dart';
import '../components/api_docs_builder_screen/api_docs_request_browser_tile.dart';
import '../components/api_docs_builder_screen/api_docs_sidebar_widgets.dart';
import '../components/api_docs_builder_screen/dialogs/api_docs_basic_dialogs.dart';
import '../components/api_docs_builder_screen/dialogs/api_docs_field_dialogs.dart';
import '../controllers/api_docs_builder_controller.dart';
import '../models/api_documentation_project.dart';
import '../repositories/api_docs_repository.dart';
import '../services/api_docs_export_service.dart';
import '../utils/logger.dart';
import '../utils/theme.dart';
import '../widgets/toast_widget.dart';

class ApiDocsBuilderScreen extends StatefulWidget {
  const ApiDocsBuilderScreen({super.key});

  @override
  State<ApiDocsBuilderScreen> createState() => _ApiDocsBuilderScreenState();
}

class _ApiDocsBuilderScreenState extends State<ApiDocsBuilderScreen> {
  static const String _ungroupedLabel = 'Без коллекции';
  static const List<String> _methods = <String>[
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
  ];

  static const List<String> _fieldTypes = <String>[
    'string',
    'integer',
    'number',
    'boolean',
    'object',
    'array',
  ];

  static const List<String> _authTypes = <String>[
    'none',
    'bearer',
    'basic',
    'apiKey',
  ];

  static const List<String> _apiKeyLocations = <String>[
    'header',
    'query',
  ];
  static const List<String> _bodyModes = <String>[
    'none',
    'json',
    'form-data',
    'x-www-form-urlencoded',
  ];
  static const List<String> _dictionaryValueTypes = <String>[
    'string',
    'integer',
    'number',
  ];
  static const List<String> _queryFieldTypes = <String>[
    'string',
    'integer',
    'number',
    'boolean',
  ];
  static const List<String> _pathFieldTypes = <String>[
    'string',
    'integer',
    'number',
    'boolean',
  ];

  late final ApiDocsBuilderController _controller;

  List<ApiDocumentationProject> get _projects => _controller.projects;
  int get _selectedProjectIndex => _controller.selectedProjectIndex;
  String? get _selectedGroup => _controller.selectedGroup;
  bool get _isLoading => _controller.isLoading;

  ApiDocumentationProject? get _selectedProject {
    return _controller.selectedProject;
  }

  List<ApiRequestDefinition> get _requestsInSelectedGroup {
    return _controller.requestsInSelectedGroup;
  }

  ApiRequestDefinition? get _selectedRequest {
    return _controller.selectedRequest;
  }

  @override
  void initState() {
    super.initState();
    _controller =
        ApiDocsBuilderController(repository: const ApiDocsRepository())
          ..addListener(_handleControllerChanged);
    _controller.loadProjects().catchError((error, stack) {
      logger.error(
        'Не удалось загрузить конструктор API документации',
        error,
        stack is StackTrace ? stack : null,
      );
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  List<String> get _availableGroupsForSelectedProject {
    return _controller.availableGroupsForSelectedProject;
  }

  String _normalizeGroupName(String value) {
    return _controller.normalizeGroupName(value);
  }

  String _displayGroupName(String value) {
    return displayApiDocsGroupName(
      value,
      normalizeGroupName: _normalizeGroupName,
      ungroupedLabel: _ungroupedLabel,
    );
  }

  void _selectProject(int index) {
    _controller.selectProject(index);
  }

  void _selectGroup(String group) {
    _controller.selectGroup(group);
  }

  void _openRequest(ApiRequestDefinition request) {
    _controller.openRequest(request);
  }

  void _backToGroups() {
    _controller.backToGroups();
  }

  void _backToRequests() {
    _controller.backToRequests();
  }

  Future<void> _createProject() async {
    final created = await _showProjectDialog(
      initial: ApiDocumentationProject.createEmpty(),
      isNew: true,
    );
    if (created == null) return;

    await _controller.createProject(created);
  }

  Future<void> _editProject() async {
    final project = _selectedProject;
    if (project == null) return;

    final updated = await _showProjectDialog(initial: project);
    if (updated == null) return;

    await _controller.updateSelectedProject(updated);
  }

  Future<void> _deleteProject() async {
    final project = _selectedProject;
    if (project == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить проект?'),
        content: Text('Проект "${project.name}" будет удалён безвозвратно.'),
        actions: [
          _buildDialogCancelButton(
            onPressed: () => Navigator.of(context).pop(false),
          ),
          _buildDialogSubmitButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            isDanger: true,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _controller.deleteSelectedProject();
  }

  Future<void> _createCollection() async {
    final project = _selectedProject;
    if (project == null) return;

    final collection = await _showCollectionDialog();
    if (collection == null) return;

    final normalized = _normalizeGroupName(collection);
    if (normalized.isEmpty) return;
    if (_availableGroupsForSelectedProject.contains(normalized)) {
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Коллекция "$normalized" уже существует',
        type: ToastType.warning,
      );
      return;
    }

    await _controller.createCollection(normalized);
  }

  Future<void> _deleteCollection(String group) async {
    final project = _selectedProject;
    final normalized = _normalizeGroupName(group);
    if (project == null || normalized.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить коллекцию?'),
        content: Text(
          'Коллекция "${_displayGroupName(normalized)}" будет удалена. '
          'Запросы из неё останутся и перейдут в "Без коллекции".',
        ),
        actions: [
          _buildDialogCancelButton(
            onPressed: () => Navigator.of(context).pop(false),
          ),
          _buildDialogSubmitButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            isDanger: true,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _controller.deleteCollection(normalized);
  }

  Future<void> _createRequest() async {
    final project = _selectedProject;
    if (project == null) return;

    final created = await _showRequestDialog(
      initial: _emptyRequest(
        project.requests.length,
        group: _selectedGroup,
      ),
      isNew: true,
      existingGroups: _availableGroupsForSelectedProject,
    );
    if (created == null) return;

    await _controller.createRequest(created);
  }

  Future<void> _editRequest() async {
    final project = _selectedProject;
    final request = _selectedRequest;
    if (project == null || request == null) return;

    final updated = await _showRequestDialog(
      initial: request,
      existingGroups: _availableGroupsForSelectedProject,
    );
    if (updated == null) return;

    await _controller.updateRequest(updated);
  }

  Future<void> _deleteRequest() async {
    final request = _selectedRequest;
    if (request == null) return;
    await _deleteRequestById(request.id);
  }

  Future<void> _deleteRequestById(String requestId) async {
    final project = _selectedProject;
    if (project == null) return;

    final request = project.requests.cast<ApiRequestDefinition?>().firstWhere(
          (item) => item?.id == requestId,
          orElse: () => null,
        );
    if (request == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запрос?'),
        content: Text('Запрос "${request.name}" будет удалён безвозвратно.'),
        actions: [
          _buildDialogCancelButton(
            onPressed: () => Navigator.of(context).pop(false),
          ),
          _buildDialogSubmitButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            isDanger: true,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _controller.deleteRequestById(requestId);
  }

  Future<void> _editProjectAuth() async {
    final project = _selectedProject;
    if (project == null) return;
    final updated = await _showAuthDialog(project.authConfig);
    if (updated == null) return;
    await _controller.updateSelectedProject(
      project.copyWith(authConfig: updated, updatedAt: DateTime.now()),
    );
  }

  Future<void> _editRequestAuth() async {
    final project = _selectedProject;
    final request = _selectedRequest;
    if (project == null || request == null) return;

    final updated = await _showAuthDialog(request.authConfig);
    if (updated == null) return;

    await _controller.updateSelectedRequest(
      request.copyWith(authConfig: updated),
    );
  }

  Future<void> _setUseProjectAuth(bool value) async {
    final project = _selectedProject;
    final request = _selectedRequest;
    if (project == null || request == null) return;

    await _controller.updateSelectedRequest(
      request.copyWith(useProjectAuth: value),
    );
  }

  Future<void> _addHeader() async {
    final request = _selectedRequest;
    if (request == null) return;
    final entry = await _showHeaderDialog();
    if (entry == null) return;
    await _updateSelectedRequest(
      request.copyWith(headers: <ApiKeyValueEntry>[...request.headers, entry]),
    );
  }

  Future<void> _editHeader(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    final entry = await _showHeaderDialog(initial: request.headers[index]);
    if (entry == null) return;

    final headers = <ApiKeyValueEntry>[...request.headers];
    headers[index] = entry;
    await _updateSelectedRequest(request.copyWith(headers: headers));
  }

  Future<void> _removeHeader(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    await _updateSelectedRequest(
      request.copyWith(
        headers: <ApiKeyValueEntry>[
          for (var i = 0; i < request.headers.length; i++)
            if (i != index) request.headers[i],
        ],
      ),
    );
  }

  Future<void> _addQueryParam() async {
    final request = _selectedRequest;
    if (request == null) return;
    final entry = await _showParameterDialog(
      availableTypes: _queryFieldTypes,
      allowArray: false,
    );
    if (entry == null) return;
    await _updateSelectedRequest(
      request.copyWith(
        queryParams: <ApiParameterDefinition>[...request.queryParams, entry],
      ),
    );
  }

  Future<void> _editQueryParam(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    final updated = await _showParameterDialog(
      initial: request.queryParams[index],
      availableTypes: _queryFieldTypes,
      allowArray: false,
    );
    if (updated == null) return;
    final items = <ApiParameterDefinition>[...request.queryParams];
    items[index] = updated;
    await _updateSelectedRequest(request.copyWith(queryParams: items));
  }

  Future<void> _removeQueryParam(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    await _updateSelectedRequest(
      request.copyWith(
        queryParams: <ApiParameterDefinition>[
          for (var i = 0; i < request.queryParams.length; i++)
            if (i != index) request.queryParams[i],
        ],
      ),
    );
  }

  Future<void> _addPathParam() async {
    final request = _selectedRequest;
    if (request == null) return;
    final result = await _showPathParameterDialog(
      requestPath: request.path,
      existingParamNames:
          request.pathParams.map((param) => param.name).toList(),
    );
    if (result == null) return;
    await _updateSelectedRequest(
      request.copyWith(
        path: result.path,
        pathParams: <ApiParameterDefinition>[
          ...request.pathParams,
          result.parameter,
        ],
      ),
    );
  }

  Future<void> _editPathParam(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    final updated = await _showPathParameterDialog(
      initial: request.pathParams[index],
      requestPath: request.path,
      existingParamNames: [
        for (var i = 0; i < request.pathParams.length; i++)
          if (i != index) request.pathParams[i].name,
      ],
    );
    if (updated == null) return;
    final items = <ApiParameterDefinition>[...request.pathParams];
    items[index] = updated.parameter.copyWith(required: true);
    await _updateSelectedRequest(
      request.copyWith(
        path: updated.path,
        pathParams: items,
      ),
    );
  }

  Future<void> _removePathParam(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    final removedParam = request.pathParams[index];
    await _updateSelectedRequest(
      request.copyWith(
        path: _removePathPlaceholder(request.path, removedParam.name),
        pathParams: <ApiParameterDefinition>[
          for (var i = 0; i < request.pathParams.length; i++)
            if (i != index) request.pathParams[i],
        ],
      ),
    );
  }

  Future<void> _addBodyField() async {
    final request = _selectedRequest;
    if (request == null) return;
    final entry = await _showBodyFieldDialog(bodyMode: request.bodyMode);
    if (entry == null) return;
    await _updateSelectedRequest(
      request.copyWith(
        bodyFields: <ApiBodyFieldDefinition>[...request.bodyFields, entry],
      ),
    );
  }

  Future<void> _editBodyField(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    final updated = await _showBodyFieldDialog(
      initial: request.bodyFields[index],
      bodyMode: request.bodyMode,
    );
    if (updated == null) return;
    final items = <ApiBodyFieldDefinition>[...request.bodyFields];
    items[index] = updated;
    await _updateSelectedRequest(request.copyWith(bodyFields: items));
  }

  Future<void> _removeBodyField(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    await _updateSelectedRequest(
      request.copyWith(
        bodyFields: <ApiBodyFieldDefinition>[
          for (var i = 0; i < request.bodyFields.length; i++)
            if (i != index) request.bodyFields[i],
        ],
      ),
    );
  }

  Future<void> _addResponse() async {
    final request = _selectedRequest;
    if (request == null) return;
    final response = await _showResponseDialog();
    if (response == null) return;
    await _updateSelectedRequest(
      request.copyWith(
        responses: <ApiResponseDefinition>[...request.responses, response],
      ),
    );
  }

  Future<void> _editResponse(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    final response =
        await _showResponseDialog(initial: request.responses[index]);
    if (response == null) return;
    final items = <ApiResponseDefinition>[...request.responses];
    items[index] = response;
    await _updateSelectedRequest(request.copyWith(responses: items));
  }

  Future<void> _removeResponse(int index) async {
    final request = _selectedRequest;
    if (request == null) return;
    await _updateSelectedRequest(
      request.copyWith(
        responses: <ApiResponseDefinition>[
          for (var i = 0; i < request.responses.length; i++)
            if (i != index) request.responses[i],
        ],
      ),
    );
  }

  Future<void> _setBodyMode(String mode) async {
    final request = _selectedRequest;
    if (request == null) return;
    if (request.bodyMode == mode) return;

    final switchesJsonBoundary =
        (request.bodyMode == 'json') != (mode == 'json');
    final hasBodyContent =
        request.bodyFields.isNotEmpty || request.requestBody.trim().isNotEmpty;

    if (switchesJsonBoundary && hasBodyContent) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Сменить формат тела?'),
          content: Text(
            mode == 'json'
                ? 'Текущие поля ${_bodyModeLabel(request.bodyMode)} будут очищены. '
                    'JSON-описание нужно будет задать заново.'
                : 'Текущий JSON body будет очищен. '
                    'Поля для режима "${_bodyModeLabel(mode)}" нужно будет заполнить заново.',
          ),
          actions: [
            _buildDialogCancelButton(
              onPressed: () => Navigator.of(context).pop(false),
            ),
            _buildDialogSubmitButton(
              onPressed: () => Navigator.of(context).pop(true),
              label: 'Продолжить',
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await _updateSelectedRequest(
        request.copyWith(
          bodyMode: mode,
          bodyFields: const <ApiBodyFieldDefinition>[],
          requestBody: '',
        ),
      );
      return;
    }

    await _updateSelectedRequest(request.copyWith(bodyMode: mode));
  }

  Future<void> _editJsonTemplate() async {
    final request = _selectedRequest;
    if (request == null || request.bodyMode != 'json') return;

    final template = await _showJsonTemplateDialog(
      initialValue: request.requestBody,
    );
    if (template == null) return;

    final decoded = jsonDecode(template);
    if (decoded is! Map<String, dynamic>) {
      _showRequiredFieldMessage(
          'JSON body должен быть объектом верхнего уровня');
      return;
    }

    await _updateSelectedRequest(
      request.copyWith(
        requestBody: const JsonEncoder.withIndent('  ').convert(decoded),
        bodyFields: buildApiDocsBodyFieldsFromJsonObject(
          decoded,
          nextId: _nextId,
        ),
      ),
    );
  }

  Future<void> _updateSelectedRequest(ApiRequestDefinition request) async {
    await _controller.updateSelectedRequest(request);
  }

  Future<void> _exportPostmanCollection() async {
    final project = _selectedProject;
    if (project == null) return;

    try {
      final location = await getSaveLocation(
        suggestedName: '${_slug(project.name)}_postman_collection.json',
        acceptedTypeGroups: <XTypeGroup>[
          const XTypeGroup(label: 'JSON', extensions: <String>['json']),
        ],
      );
      if (location == null) return;

      final file = XFile.fromData(
        utf8.encode(ApiDocsExportService.buildPostmanCollection(project)),
        mimeType: 'application/json',
        name: '${_slug(project.name)}_postman_collection.json',
      );
      await file.saveTo(location.path);
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Postman Collection сохранена',
        type: ToastType.success,
      );
    } catch (e, stack) {
      logger.error('Не удалось экспортировать Postman Collection', e, stack);
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Не удалось сохранить файл: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _exportOpenApiJson() async {
    final project = _selectedProject;
    if (project == null) return;
    try {
      final location = await getSaveLocation(
        suggestedName: '${_slug(project.name)}_openapi.json',
        acceptedTypeGroups: <XTypeGroup>[
          const XTypeGroup(label: 'JSON', extensions: <String>['json']),
        ],
      );
      if (location == null) return;

      final file = XFile.fromData(
        utf8.encode(ApiDocsExportService.buildOpenApiDocument(project)),
        mimeType: 'application/json',
        name: '${_slug(project.name)}_openapi.json',
      );
      await file.saveTo(location.path);
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'OpenAPI JSON сохранён',
        type: ToastType.success,
      );
    } catch (e, stack) {
      logger.error('Не удалось экспортировать OpenAPI JSON', e, stack);
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Не удалось сохранить файл: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _exportInternalProject() async {
    final project = _selectedProject;
    if (project == null) return;

    try {
      final location = await getSaveLocation(
        suggestedName: '${_slug(project.name)}_logger_api_project.json',
        acceptedTypeGroups: <XTypeGroup>[
          const XTypeGroup(label: 'JSON', extensions: <String>['json']),
        ],
      );
      if (location == null) return;

      final file = XFile.fromData(
        utf8.encode(encodeApiDocumentationProject(project)),
        mimeType: 'application/json',
        name: '${_slug(project.name)}_logger_api_project.json',
      );
      await file.saveTo(location.path);
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Проект экспортирован',
        type: ToastType.success,
      );
    } catch (e, stack) {
      logger.error('Не удалось экспортировать проект API', e, stack);
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Не удалось сохранить файл: $e',
        type: ToastType.error,
      );
    }
  }

  Future<void> _importInternalProject() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[
          const XTypeGroup(label: 'JSON', extensions: <String>['json']),
        ],
      );
      if (file == null) return;

      final content = await file.readAsString();
      final projects = decodeApiDocumentationProjects(content);
      if (projects.isEmpty) {
        if (!mounted) return;
        ToastWidget.show(
          context,
          message: 'В файле не найдено проектов',
          type: ToastType.warning,
        );
        return;
      }

      for (final project in projects) {
        await _controller.createProject(
          project.copyWith(
            id: _nextId('project'),
            updatedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
      }

      if (!mounted) return;
      ToastWidget.show(
        context,
        message: projects.length == 1
            ? 'Проект импортирован'
            : 'Импортировано проектов: ${projects.length}',
        type: ToastType.success,
      );
    } catch (e, stack) {
      logger.error('Не удалось импортировать проект API', e, stack);
      if (!mounted) return;
      ToastWidget.show(
        context,
        message: 'Не удалось импортировать файл: $e',
        type: ToastType.error,
      );
    }
  }

  Future<ApiDocumentationProject?> _showProjectDialog({
    required ApiDocumentationProject initial,
    bool isNew = false,
  }) async {
    return ApiDocsBasicDialogs.showProjectDialog(
      context: context,
      initial: initial,
      nextId: _nextId,
      showRequiredFieldMessage: _showRequiredFieldMessage,
      isNew: isNew,
    );
  }

  Future<ApiRequestDefinition?> _showRequestDialog({
    required ApiRequestDefinition initial,
    bool isNew = false,
    List<String> existingGroups = const <String>[],
  }) async {
    return ApiDocsBasicDialogs.showRequestDialog(
      context: context,
      initial: initial,
      existingGroups: existingGroups,
      methods: _methods,
      bodyModes: _bodyModes,
      ungroupedLabel: _ungroupedLabel,
      normalizeGroupName: _normalizeGroupName,
      bodyModeLabel: _bodyModeLabel,
      nextId: _nextId,
      showRequiredFieldMessage: _showRequiredFieldMessage,
      isNew: isNew,
    );
  }

  Future<String?> _showCollectionDialog({String initialValue = ''}) async {
    return ApiDocsBasicDialogs.showCollectionDialog(
      context: context,
      normalizeGroupName: _normalizeGroupName,
      showRequiredFieldMessage: _showRequiredFieldMessage,
      initialValue: initialValue,
    );
  }

  Future<ApiAuthConfig?> _showAuthDialog(ApiAuthConfig initial) async {
    return ApiDocsBasicDialogs.showAuthDialog(
      context: context,
      initial: initial,
      authTypes: _authTypes,
      apiKeyLocations: _apiKeyLocations,
    );
  }

  Future<ApiKeyValueEntry?> _showHeaderDialog({
    ApiKeyValueEntry? initial,
  }) async {
    return ApiDocsBasicDialogs.showHeaderDialog(
      context: context,
      showRequiredFieldMessage: _showRequiredFieldMessage,
      initial: initial,
    );
  }

  Future<ApiParameterDefinition?> _showParameterDialog({
    ApiParameterDefinition? initial,
    bool forceRequired = false,
    List<String> availableTypes = _fieldTypes,
    bool allowArray = true,
  }) async {
    return ApiDocsFieldDialogs.showParameterDialog(
      context: context,
      nextId: _nextId,
      showRequiredFieldMessage: _showRequiredFieldMessage,
      fieldTypes: _fieldTypes,
      dictionaryValueTypes: _dictionaryValueTypes,
      initial: initial,
      forceRequired: forceRequired,
      availableTypes: availableTypes,
      allowArray: allowArray,
      showDictionaryEntryDialog: _showDictionaryEntryDialog,
    );
  }

  Future<ApiDocsPathParamDialogResult?> _showPathParameterDialog({
    ApiParameterDefinition? initial,
    required String requestPath,
    required List<String> existingParamNames,
  }) async {
    return ApiDocsFieldDialogs.showPathParameterDialog(
      context: context,
      nextId: _nextId,
      showRequiredFieldMessage: _showRequiredFieldMessage,
      showDictionaryEntryDialog: _showDictionaryEntryDialog,
      pathFieldTypes: _pathFieldTypes,
      dictionaryValueTypes: _dictionaryValueTypes,
      initial: initial,
      requestPath: requestPath,
      existingParamNames: existingParamNames,
    );
  }

  Future<ApiBodyFieldDefinition?> _showBodyFieldDialog({
    ApiBodyFieldDefinition? initial,
    required String bodyMode,
  }) async {
    return ApiDocsFieldDialogs.showBodyFieldDialog(
      context: context,
      nextId: _nextId,
      showRequiredFieldMessage: _showRequiredFieldMessage,
      showDictionaryEntryDialog: _showDictionaryEntryDialog,
      fieldTypes: _fieldTypes,
      pathFieldTypes: _pathFieldTypes,
      dictionaryValueTypes: _dictionaryValueTypes,
      fieldBadgeColor: _fieldBadgeColor,
      initial: initial,
      bodyMode: bodyMode,
    );
  }

  Future<ApiDictionaryEntry?> _showDictionaryEntryDialog({
    ApiDictionaryEntry? initial,
  }) async {
    return ApiDocsBasicDialogs.showDictionaryEntryDialog(
      context: context,
      showRequiredFieldMessage: _showRequiredFieldMessage,
      initial: initial,
    );
  }

  Future<String?> _showJsonTemplateDialog({
    required String initialValue,
  }) async {
    return ApiDocsBasicDialogs.showJsonTemplateDialog(
      context: context,
      initialValue: initialValue,
      showRequiredFieldMessage: _showRequiredFieldMessage,
    );
  }

  Future<ApiResponseDefinition?> _showResponseDialog({
    ApiResponseDefinition? initial,
  }) async {
    return ApiDocsBasicDialogs.showResponseDialog(
      context: context,
      initial: initial ?? _emptyResponse(),
    );
  }

  ApiRequestDefinition _emptyRequest(int index, {String? group}) {
    return createEmptyApiDocsRequest(
      index,
      nextId: _nextId,
      normalizeGroupName: _normalizeGroupName,
      group: group,
    );
  }

  ApiResponseDefinition _emptyResponse() {
    return createEmptyApiDocsResponse(
      nextId: _nextId,
    );
  }

  String _nextId(String suffix) =>
      '${DateTime.now().microsecondsSinceEpoch}_$suffix';

  void _showRequiredFieldMessage(String label) {
    if (!mounted) return;
    ToastWidget.show(
      context,
      message: '$label обязательно',
      type: ToastType.warning,
    );
  }

  String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return slug.isEmpty ? 'api_project' : slug;
  }

  Widget _buildHeaderActionButton({
    required String tooltip,
    required IconData icon,
    required Color accentColor,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isEnabled ? 0.12 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: isEnabled ? 0.45 : 0.16),
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            color:
                isEnabled ? accentColor : accentColor.withValues(alpha: 0.42),
            disabledColor: accentColor.withValues(alpha: 0.42),
            splashRadius: 22,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasProject = _selectedProject != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Конструктор API документации'),
        actions: [
          _buildHeaderActionButton(
            tooltip: 'Импорт проекта Logger API JSON',
            onPressed: _importInternalProject,
            icon: Icons.file_download_done_outlined,
            accentColor: const Color(0xFF2FA67A),
          ),
          _buildHeaderActionButton(
            tooltip: 'Экспорт проекта Logger API JSON',
            onPressed: hasProject ? _exportInternalProject : null,
            icon: Icons.ios_share_outlined,
            accentColor: const Color(0xFF4E89F5),
          ),
          _buildHeaderActionButton(
            tooltip: 'Экспорт выбранного проекта в Postman',
            onPressed: hasProject ? _exportPostmanCollection : null,
            icon: Icons.inventory_2_outlined,
            accentColor: const Color(0xFFFF8A3D),
          ),
          _buildHeaderActionButton(
            tooltip: 'Экспорт выбранного проекта в OpenAPI JSON',
            onPressed: hasProject ? _exportOpenApiJson : null,
            icon: Icons.schema_outlined,
            accentColor: const Color(0xFF57B7E3),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const sidebarWidth = 340.0;
          const contentGap = 16.0;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.08),
                        Colors.transparent,
                        context.appPanelAlt.withValues(alpha: 0.24),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: sidebarWidth,
                      child: _buildSidebar(),
                    ),
                    const SizedBox(width: contentGap),
                    Expanded(
                      child: _buildWorkspace(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar() {
    final project = _selectedProject;
    final groups = _availableGroupsForSelectedProject;

    return Container(
      decoration: context.panelDecoration(radius: 30).copyWith(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.appPanel.withValues(alpha: 0.92),
                context.appPanelAlt.withValues(alpha: 0.86),
              ],
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Проекты API',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  project?.name ?? 'Выберите проект',
                  style: TextStyle(
                    color: context.appTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ApiDocsSidebarIconAction(
                      tooltip: 'Новый проект',
                      icon: Icons.add_circle_outline,
                      onTap: _createProject,
                    ),
                    ApiDocsSidebarIconAction(
                      tooltip: 'Редактировать проект',
                      icon: Icons.edit_outlined,
                      onTap: project == null ? null : _editProject,
                    ),
                    ApiDocsSidebarIconAction(
                      tooltip: 'Удалить проект',
                      icon: Icons.delete_outline,
                      onTap: project == null ? null : _deleteProject,
                      isDanger: true,
                    ),
                    ApiDocsSidebarIconAction(
                      tooltip: 'Новый запрос',
                      icon: Icons.bolt_outlined,
                      onTap: project == null ? null : _createRequest,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: context.appBorder.withValues(alpha: 0.4),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebarSectionTitle('Проекты'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < _projects.length; i++)
                        ApiDocsProjectTile(
                          project: _projects[i],
                          selected: i == _selectedProjectIndex,
                          onTap: () => _selectProject(i),
                        ),
                    ],
                  ),
                  if (project != null) ...[
                    const SizedBox(height: 18),
                    _buildSidebarSectionTitle(
                      'Коллекции',
                      onAdd: _createCollection,
                      addTooltip: 'Создать коллекцию',
                    ),
                    const SizedBox(height: 10),
                    if (groups.isEmpty)
                      const ApiDocsEmptySidebarNote(
                        label: 'Создайте коллекцию или добавьте первый запрос.',
                      )
                    else
                      Column(
                        children: [
                          for (final group in groups)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ApiDocsCollectionListTile(
                                label: _displayGroupName(group),
                                selected: _selectedGroup == group,
                                onTap: () => _selectGroup(group),
                                onDelete: _normalizeGroupName(group).isEmpty
                                    ? null
                                    : () => _deleteCollection(group),
                              ),
                            ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionTitle(
    String title, {
    VoidCallback? onAdd,
    String? addTooltip,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: context.appTextMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ),
        if (onAdd != null)
          IconButton(
            tooltip: addTooltip,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
      ],
    );
  }

  Widget _buildWorkspace() {
    final project = _selectedProject;
    final requestsInGroup = _requestsInSelectedGroup;
    final request = _selectedRequest;

    if (project == null) {
      return ApiDocsWorkspaceEmptyState(
        title: 'Выберите проект',
        subtitle:
            'Слева находится список проектов. После выбора появятся коллекции и запросы.',
        actionLabel: 'Новый проект',
        onAction: _createProject,
      );
    }

    if (_selectedGroup == null) {
      return ApiDocsWorkspaceEmptyState(
        title: project.name,
        subtitle:
            'Выберите коллекцию в левой колонке, чтобы открыть список запросов.',
        actionLabel: 'Новый запрос',
        onAction: _createRequest,
      );
    }

    if (request == null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRequestsHeader(project, _selectedGroup!),
            const SizedBox(height: 16),
            if (requestsInGroup.isEmpty)
              ApiDocsWorkspaceEmptyState(
                title: 'Коллекция пуста',
                subtitle:
                    'Добавьте первый запрос в коллекцию "${_displayGroupName(_selectedGroup!)}".',
                actionLabel: 'Добавить запрос',
                onAction: _createRequest,
              )
            else
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final item in requestsInGroup)
                    SizedBox(
                      width: 280,
                      height: 176,
                      child: ApiDocsRequestBrowserTile(
                        request: item,
                        groupLabel: _displayGroupName(item.group),
                        onOpen: () => _openRequest(item),
                        onDelete: () => _deleteRequestById(item.id),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 88),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestViewHeader(),
          const SizedBox(height: 16),
          _buildHeroCard(project, request),
          const SizedBox(height: 16),
          _buildAuthSection(project, request),
          const SizedBox(height: 16),
          _buildHeadersSection(request),
          const SizedBox(height: 16),
          _buildPathParamsSection(request),
          const SizedBox(height: 16),
          _buildParameterSection(
            title: 'Query params',
            subtitle: 'Параметры строки запроса',
            items: request.queryParams,
            onAdd: _addQueryParam,
            onEdit: _editQueryParam,
            onDelete: _removeQueryParam,
          ),
          const SizedBox(height: 16),
          _buildBodyFieldsSection(request),
          const SizedBox(height: 16),
          _buildResponsesSection(request),
          const SizedBox(height: 88),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    ApiDocumentationProject project,
    ApiRequestDefinition request,
  ) {
    return Container(
      decoration: context.panelDecoration(radius: 30).copyWith(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.appPanel.withValues(alpha: 0.96),
                context.appPanelAlt.withValues(alpha: 0.94),
              ],
            ),
          ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApiDocsMethodBadge(method: request.method, large: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${project.baseUrl}${request.path}',
                      style: TextStyle(
                        color: context.appTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (request.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        request.description,
                        style: TextStyle(
                          color: context.appTextPrimary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _editRequest,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Основное'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _editProject,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Проект'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ApiDocsHeroInfoChip(
                label: 'Группа: ${_displayGroupName(request.group)}',
              ),
              ApiDocsHeroInfoChip(
                label: request.useProjectAuth ? 'Auth проекта' : 'Auth запроса',
              ),
              ApiDocsHeroInfoChip(
                  label:
                      'Base URL: ${project.baseUrl.isEmpty ? '-' : project.baseUrl}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsHeader(
    ApiDocumentationProject project,
    String group,
  ) {
    return Container(
      decoration: context.panelDecoration(radius: 28).copyWith(
            color: context.appPanel.withValues(alpha: 0.82),
          ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Назад к коллекциям',
            onPressed: _backToGroups,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayGroupName(group),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Запросы коллекции ${_displayGroupName(group)} проекта ${project.name}',
                  style: TextStyle(color: context.appTextMuted),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: _createRequest,
            icon: const Icon(Icons.add),
            label: const Text('Запрос'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestViewHeader() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Назад к запросам коллекции',
          onPressed: _backToRequests,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 8),
        Text(
          'Просмотр запроса',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Удалить запрос',
          onPressed: _deleteRequest,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  Widget _buildAuthSection(
    ApiDocumentationProject project,
    ApiRequestDefinition request,
  ) {
    final activeAuth =
        request.useProjectAuth ? project.authConfig : request.authConfig;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auth-блоки',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.useProjectAuth
                            ? 'Запрос использует авторизацию проекта'
                            : 'Запрос использует собственную авторизацию',
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _editProjectAuth,
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Auth проекта'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _editRequestAuth,
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text('Auth запроса'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Использовать auth проекта'),
              value: request.useProjectAuth,
              onChanged: _setUseProjectAuth,
            ),
            ApiDocsAuthPreview(config: activeAuth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadersSection(ApiRequestDefinition request) {
    return ApiDocsSectionCard(
      title: 'Headers',
      subtitle: 'Заголовки запроса',
      onAdd: _addHeader,
      child: request.headers.isEmpty
          ? const Text('Заголовки ещё не добавлены.')
          : Column(
              children: [
                for (var i = 0; i < request.headers.length; i++)
                  ApiDocsKeyValueTile(
                    entry: request.headers[i],
                    onEdit: () => _editHeader(i),
                    onDelete: () => _removeHeader(i),
                  ),
              ],
            ),
    );
  }

  Widget _buildParameterSection({
    required String title,
    required String subtitle,
    required List<ApiParameterDefinition> items,
    required VoidCallback onAdd,
    required ValueChanged<int> onEdit,
    required ValueChanged<int> onDelete,
  }) {
    return ApiDocsSectionCard(
      title: title,
      subtitle: subtitle,
      onAdd: onAdd,
      child: items.isEmpty
          ? const Text('Поля ещё не добавлены.')
          : Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  ApiDocsFieldDefinitionTile(
                    name: items[i].name,
                    type: items[i].type,
                    description: items[i].description,
                    required: items[i].required,
                    isArray: items[i].isArray,
                    example: items[i].example,
                    arrayItemType: items[i].arrayItemType,
                    arrayItemDescription: items[i].arrayItemDescription,
                    arrayItemExample: items[i].arrayItemExample,
                    isDictionary: items[i].isDictionary,
                    dictionaryEntries: items[i].dictionaryEntries,
                    children: const <ApiBodyFieldDefinition>[],
                    onEdit: () => onEdit(i),
                    onDelete: () => onDelete(i),
                  ),
              ],
            ),
    );
  }

  Widget _buildPathParamsSection(ApiRequestDefinition request) {
    return ApiDocsSectionCard(
      title: 'Path params',
      subtitle: 'Параметры, которые подставляются в конкретные сегменты URL',
      onAdd: _addPathParam,
      child: request.pathParams.isEmpty
          ? const Text('Параметры пути ещё не добавлены.')
          : Column(
              children: [
                for (var i = 0; i < request.pathParams.length; i++)
                  ApiDocsPathParamTile(
                    requestPath: request.path,
                    name: request.pathParams[i].name,
                    type: request.pathParams[i].type,
                    description: request.pathParams[i].description,
                    example: request.pathParams[i].example,
                    isDictionary: request.pathParams[i].isDictionary,
                    dictionaryEntries: request.pathParams[i].dictionaryEntries,
                    onEdit: () => _editPathParam(i),
                    onDelete: () => _removePathParam(i),
                  ),
              ],
            ),
    );
  }

  Widget _buildBodyFieldsSection(ApiRequestDefinition request) {
    return ApiDocsSectionCard(
      title: 'Тело запроса',
      subtitle: 'Поля и формат тела запроса для экспорта в Postman/OpenAPI',
      onAdd: request.bodyMode == 'none' ? null : _addBodyField,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: request.bodyMode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Тип тела запроса',
              border: OutlineInputBorder(),
            ),
            items: _bodyModes
                .map(
                  (mode) => DropdownMenuItem<String>(
                    value: mode,
                    child: Text(_bodyModeLabel(mode)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              _setBodyMode(value);
            },
          ),
          const SizedBox(height: 16),
          Text(
            _bodyModeHelpText(request.bodyMode),
            style: TextStyle(color: context.appTextMuted),
          ),
          const SizedBox(height: 16),
          if (request.bodyMode == 'json') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'JSON шаблон',
                          style: TextStyle(
                            color: context.appTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _editJsonTemplate,
                        icon: const Icon(Icons.data_object_outlined),
                        label: Text(
                          request.requestBody.trim().isEmpty
                              ? 'Указать JSON'
                              : 'Обновить JSON',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _jsonPreviewBlock(
                    request.requestBody.trim().isEmpty
                        ? '{\n  \n}'
                        : request.requestBody,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (request.bodyMode == 'none')
            const Text('Для этого запроса тело отключено.')
          else if (request.bodyFields.isEmpty)
            Text(
              'Поля тела ещё не добавлены для режима "${_bodyModeLabel(request.bodyMode)}".',
            )
          else
            Column(
              children: [
                for (var i = 0; i < request.bodyFields.length; i++)
                  ApiDocsFieldDefinitionTile(
                    name: request.bodyFields[i].name,
                    type: request.bodyFields[i].type,
                    description: request.bodyFields[i].description,
                    required: request.bodyFields[i].required,
                    isArray: request.bodyFields[i].isArray,
                    example: request.bodyFields[i].example,
                    arrayItemType: request.bodyFields[i].arrayItemType,
                    arrayItemDescription:
                        request.bodyFields[i].arrayItemDescription,
                    arrayItemExample: request.bodyFields[i].arrayItemExample,
                    isDictionary: request.bodyFields[i].isDictionary,
                    dictionaryEntries: request.bodyFields[i].dictionaryEntries,
                    children: request.bodyFields[i].children,
                    onEdit: () => _editBodyField(i),
                    onDelete: () => _removeBodyField(i),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildResponsesSection(ApiRequestDefinition request) {
    return ApiDocsSectionCard(
      title: 'Статусы ответов',
      subtitle: 'HTTP-коды и примеры ответов',
      onAdd: _addResponse,
      child: request.responses.isEmpty
          ? const Text('Ответы ещё не добавлены.')
          : Column(
              children: [
                for (var i = 0; i < request.responses.length; i++)
                  ApiDocsResponseTile(
                    response: request.responses[i],
                    onEdit: () => _editResponse(i),
                    onDelete: () => _removeResponse(i),
                  ),
              ],
            ),
    );
  }

  Widget _jsonPreviewBlock(String source) {
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

  Widget _buildDialogCancelButton({
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

  Widget _buildDialogSubmitButton({
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

  String _removePathPlaceholder(String path, String paramName) {
    return removeApiDocsPathPlaceholder(path, paramName);
  }

  String _bodyModeLabel(String mode) {
    return apiDocsBodyModeLabel(mode);
  }

  String _bodyModeHelpText(String mode) {
    return apiDocsBodyModeHelpText(mode);
  }

  Color _fieldBadgeColor(String value) {
    return apiDocsFieldBadgeColor(value);
  }
}
