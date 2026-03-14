import 'package:flutter/foundation.dart';

import '../models/api_documentation_project.dart';
import '../repositories/api_docs_repository.dart';

class ApiDocsBuilderController extends ChangeNotifier {
  ApiDocsBuilderController({
    required ApiDocsRepository repository,
  }) : _repository = repository;

  final ApiDocsRepository _repository;

  List<ApiDocumentationProject> _projects = const <ApiDocumentationProject>[];
  int _selectedProjectIndex = -1;
  int _selectedRequestIndex = -1;
  String? _selectedGroup;
  bool _isLoading = true;

  List<ApiDocumentationProject> get projects => _projects;
  int get selectedProjectIndex => _selectedProjectIndex;
  int get selectedRequestIndex => _selectedRequestIndex;
  String? get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;

  ApiDocumentationProject? get selectedProject {
    if (_projects.isEmpty ||
        _selectedProjectIndex < 0 ||
        _selectedProjectIndex >= _projects.length) {
      return null;
    }
    return _projects[_selectedProjectIndex];
  }

  Map<String, List<ApiRequestDefinition>> get requestsByGroup {
    final project = selectedProject;
    if (project == null) return const <String, List<ApiRequestDefinition>>{};

    final grouped = <String, List<ApiRequestDefinition>>{};
    for (final request in project.requests) {
      final key = normalizeGroupName(request.group);
      grouped.putIfAbsent(key, () => <ApiRequestDefinition>[]).add(request);
    }
    return grouped;
  }

  List<ApiRequestDefinition> get requestsInSelectedGroup {
    if (_selectedGroup == null) return const <ApiRequestDefinition>[];
    return requestsByGroup[_selectedGroup] ?? const <ApiRequestDefinition>[];
  }

  ApiRequestDefinition? get selectedRequest {
    final requests = requestsInSelectedGroup;
    if (_selectedRequestIndex < 0 || _selectedRequestIndex >= requests.length) {
      return null;
    }
    return requests[_selectedRequestIndex];
  }

  List<String> get availableGroupsForSelectedProject {
    final project = selectedProject;
    if (project == null) return const <String>[];

    final groups = <String>{
      for (final collection in project.collections)
        normalizeGroupName(collection),
      ...requestsByGroup.keys,
    }.toList()
      ..sort();
    return groups;
  }

  String normalizeGroupName(String value) => value.trim();

  Future<void> loadProjects() async {
    try {
      final projects = await _repository.loadProjects();
      _projects = projects;
      _selectedProjectIndex = -1;
      _selectedRequestIndex = -1;
      _selectedGroup = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectProject(int index) {
    _selectedProjectIndex = index;
    _selectedGroup = null;
    _selectedRequestIndex = -1;
    notifyListeners();
  }

  void selectGroup(String group) {
    _selectedGroup = group;
    _selectedRequestIndex = -1;
    notifyListeners();
  }

  void openRequest(ApiRequestDefinition request) {
    final index =
        requestsInSelectedGroup.indexWhere((item) => item.id == request.id);
    if (index < 0) return;
    _selectedRequestIndex = index;
    notifyListeners();
  }

  void backToGroups() {
    _selectedGroup = null;
    _selectedRequestIndex = -1;
    notifyListeners();
  }

  void backToRequests() {
    _selectedRequestIndex = -1;
    notifyListeners();
  }

  Future<void> createProject(ApiDocumentationProject project) async {
    final projects = <ApiDocumentationProject>[..._projects, project];
    await _saveProjects(projects);
    _selectedProjectIndex = projects.length - 1;
    _selectedGroup = null;
    _selectedRequestIndex = -1;
    notifyListeners();
  }

  Future<void> updateSelectedProject(ApiDocumentationProject project) async {
    if (selectedProject == null) return;
    final projects = <ApiDocumentationProject>[..._projects];
    projects[_selectedProjectIndex] = project.copyWith(
      collections: _mergeCollections(project),
      updatedAt: DateTime.now(),
    );
    await _saveProjects(projects);
  }

  Future<void> deleteSelectedProject() async {
    if (selectedProject == null) return;
    final projects = <ApiDocumentationProject>[
      for (var i = 0; i < _projects.length; i++)
        if (i != _selectedProjectIndex) _projects[i],
    ];
    await _saveProjects(projects);
  }

  Future<void> createCollection(String collection) async {
    final project = selectedProject;
    if (project == null) return;

    final normalized = normalizeGroupName(collection);
    if (normalized.isEmpty) return;

    await updateSelectedProject(
      project.copyWith(
        collections: <String>[...project.collections, normalized],
        updatedAt: DateTime.now(),
      ),
    );

    _selectedGroup = normalized;
    _selectedRequestIndex = -1;
    notifyListeners();
  }

  Future<void> deleteCollection(String group) async {
    final project = selectedProject;
    final normalized = normalizeGroupName(group);
    if (project == null || normalized.isEmpty) return;

    final updatedRequests = project.requests
        .map(
          (request) => normalizeGroupName(request.group) == normalized
              ? request.copyWith(group: '')
              : request,
        )
        .toList();

    await updateSelectedProject(
      project.copyWith(
        collections: [
          for (final collection in project.collections)
            if (normalizeGroupName(collection) != normalized) collection,
        ],
        requests: updatedRequests,
        updatedAt: DateTime.now(),
      ),
    );

    _selectedGroup = '';
    _selectedRequestIndex = -1;
    notifyListeners();
  }

  Future<void> createRequest(ApiRequestDefinition request) async {
    final project = selectedProject;
    if (project == null) return;

    await updateSelectedProject(
      project.copyWith(
        requests: <ApiRequestDefinition>[...project.requests, request],
        updatedAt: DateTime.now(),
      ),
    );

    _selectedGroup = request.group;
    _selectedRequestIndex =
        requestsInSelectedGroup.indexWhere((item) => item.id == request.id);
    notifyListeners();
  }

  Future<void> updateRequest(ApiRequestDefinition request) async {
    final project = selectedProject;
    final current = selectedRequest;
    if (project == null || current == null) return;

    final requests = <ApiRequestDefinition>[...project.requests];
    final index = requests.indexWhere((item) => item.id == current.id);
    if (index < 0) return;

    requests[index] = request;
    await updateSelectedProject(
      project.copyWith(requests: requests, updatedAt: DateTime.now()),
    );

    _selectedGroup = request.group;
    _selectedRequestIndex =
        requestsInSelectedGroup.indexWhere((item) => item.id == request.id);
    notifyListeners();
  }

  Future<void> deleteRequestById(String requestId) async {
    final project = selectedProject;
    if (project == null) return;

    final requests = <ApiRequestDefinition>[
      for (final request in project.requests)
        if (request.id != requestId) request,
    ];

    await updateSelectedProject(
      project.copyWith(requests: requests, updatedAt: DateTime.now()),
    );

    if (selectedRequest?.id == requestId || requestsInSelectedGroup.isEmpty) {
      _selectedRequestIndex = -1;
      notifyListeners();
    }
  }

  Future<void> updateSelectedRequest(ApiRequestDefinition request) async {
    final project = selectedProject;
    if (project == null) return;

    final requests = <ApiRequestDefinition>[...project.requests];
    final index = requests.indexWhere((item) => item.id == request.id);
    if (index < 0) return;

    requests[index] = request;
    await updateSelectedProject(
      project.copyWith(requests: requests, updatedAt: DateTime.now()),
    );
  }

  Future<void> _saveProjects(List<ApiDocumentationProject> projects) async {
    _projects = projects;
    if (_selectedProjectIndex >= projects.length) {
      _selectedProjectIndex = projects.isEmpty ? -1 : projects.length - 1;
    }

    final groups = availableGroupsForSelectedProject;
    if (_selectedGroup != null && !groups.contains(_selectedGroup)) {
      _selectedGroup = null;
      _selectedRequestIndex = -1;
    }

    final requestsLength = requestsInSelectedGroup.length;
    if (_selectedRequestIndex >= requestsLength) {
      _selectedRequestIndex = requestsLength == 0 ? -1 : requestsLength - 1;
    }

    notifyListeners();
    await _repository.saveProjects(projects);
  }

  List<String> _mergeCollections(ApiDocumentationProject project) {
    final merged = <String>{
      for (final collection in project.collections)
        normalizeGroupName(collection),
      for (final request in project.requests) normalizeGroupName(request.group),
    }.toList()
      ..sort();
    return merged;
  }
}
