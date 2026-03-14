import 'api_auth_config.dart';
import 'api_docs_parsing.dart';
import 'api_request_definition.dart';

class ApiDocumentationProject {
  final String id;
  final String name;
  final String description;
  final String baseUrl;
  final ApiAuthConfig authConfig;
  final List<String> collections;
  final List<ApiRequestDefinition> requests;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ApiDocumentationProject({
    required this.id,
    required this.name,
    required this.description,
    required this.baseUrl,
    required this.authConfig,
    required this.collections,
    required this.requests,
    required this.createdAt,
    required this.updatedAt,
  });

  ApiDocumentationProject copyWith({
    String? id,
    String? name,
    String? description,
    String? baseUrl,
    ApiAuthConfig? authConfig,
    List<String>? collections,
    List<ApiRequestDefinition>? requests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiDocumentationProject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      baseUrl: baseUrl ?? this.baseUrl,
      authConfig: authConfig ?? this.authConfig,
      collections: collections ?? this.collections,
      requests: requests ?? this.requests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'baseUrl': baseUrl,
        'authConfig': authConfig.toJson(),
        'collections': collections,
        'requests': requests.map((request) => request.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ApiDocumentationProject.fromJson(Map<String, dynamic> json) {
    return ApiDocumentationProject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      baseUrl: json['baseUrl']?.toString() ?? '',
      authConfig: json['authConfig'] is Map<String, dynamic>
          ? ApiAuthConfig.fromJson(json['authConfig'] as Map<String, dynamic>)
          : ApiAuthConfig.empty,
      collections: listOfString(json['collections']),
      requests: listOf<ApiRequestDefinition>(
        json['requests'],
        (item) => ApiRequestDefinition.fromJson(item),
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static ApiDocumentationProject createEmpty() {
    final now = DateTime.now();
    return ApiDocumentationProject(
      id: now.microsecondsSinceEpoch.toString(),
      name: 'Новый проект',
      description: '',
      baseUrl: '',
      authConfig: ApiAuthConfig.empty,
      collections: const [],
      requests: const [],
      createdAt: now,
      updatedAt: now,
    );
  }
}
