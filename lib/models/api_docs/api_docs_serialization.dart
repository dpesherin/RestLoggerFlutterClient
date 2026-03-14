import 'dart:convert';

import 'api_documentation_project_model.dart';

String encodeApiDocumentationProject(ApiDocumentationProject project) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(project.toJson());
}

String encodeApiDocumentationProjects(List<ApiDocumentationProject> projects) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(projects.map((project) => project.toJson()).toList());
}

ApiDocumentationProject decodeApiDocumentationProject(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw const FormatException('Ожидался JSON-объект проекта.');
  }
  return ApiDocumentationProject.fromJson(Map<String, dynamic>.from(decoded));
}

List<ApiDocumentationProject> decodeApiDocumentationProjects(String source) {
  final decoded = jsonDecode(source);
  if (decoded is Map) {
    return [
      ApiDocumentationProject.fromJson(Map<String, dynamic>.from(decoded)),
    ];
  }
  if (decoded is! List) {
    throw const FormatException('Ожидался JSON-объект проекта или список.');
  }
  return decoded
      .whereType<Map>()
      .map(
        (item) => ApiDocumentationProject.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}
