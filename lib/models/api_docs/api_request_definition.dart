import 'api_auth_config.dart';
import 'api_body_field_definition.dart';
import 'api_docs_parsing.dart';
import 'api_key_value_entry.dart';
import 'api_parameter_definition.dart';
import 'api_response_definition.dart';

class ApiRequestDefinition {
  final String id;
  final String group;
  final String name;
  final String description;
  final String method;
  final String path;
  final String bodyMode;
  final List<ApiKeyValueEntry> headers;
  final List<ApiParameterDefinition> queryParams;
  final List<ApiParameterDefinition> pathParams;
  final List<ApiBodyFieldDefinition> bodyFields;
  final String requestBody;
  final List<ApiResponseDefinition> responses;
  final bool useProjectAuth;
  final ApiAuthConfig authConfig;

  const ApiRequestDefinition({
    required this.id,
    required this.group,
    required this.name,
    required this.description,
    required this.method,
    required this.path,
    required this.bodyMode,
    required this.headers,
    required this.queryParams,
    required this.pathParams,
    required this.bodyFields,
    required this.requestBody,
    required this.responses,
    required this.useProjectAuth,
    required this.authConfig,
  });

  ApiRequestDefinition copyWith({
    String? id,
    String? group,
    String? name,
    String? description,
    String? method,
    String? path,
    String? bodyMode,
    List<ApiKeyValueEntry>? headers,
    List<ApiParameterDefinition>? queryParams,
    List<ApiParameterDefinition>? pathParams,
    List<ApiBodyFieldDefinition>? bodyFields,
    String? requestBody,
    List<ApiResponseDefinition>? responses,
    bool? useProjectAuth,
    ApiAuthConfig? authConfig,
  }) {
    return ApiRequestDefinition(
      id: id ?? this.id,
      group: group ?? this.group,
      name: name ?? this.name,
      description: description ?? this.description,
      method: method ?? this.method,
      path: path ?? this.path,
      bodyMode: bodyMode ?? this.bodyMode,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      pathParams: pathParams ?? this.pathParams,
      bodyFields: bodyFields ?? this.bodyFields,
      requestBody: requestBody ?? this.requestBody,
      responses: responses ?? this.responses,
      useProjectAuth: useProjectAuth ?? this.useProjectAuth,
      authConfig: authConfig ?? this.authConfig,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group': group,
        'name': name,
        'description': description,
        'method': method,
        'path': path,
        'bodyMode': bodyMode,
        'headers': headers.map((entry) => entry.toJson()).toList(),
        'queryParams': queryParams.map((entry) => entry.toJson()).toList(),
        'pathParams': pathParams.map((entry) => entry.toJson()).toList(),
        'bodyFields': bodyFields.map((entry) => entry.toJson()).toList(),
        'requestBody': requestBody,
        'responses': responses.map((entry) => entry.toJson()).toList(),
        'useProjectAuth': useProjectAuth,
        'authConfig': authConfig.toJson(),
      };

  factory ApiRequestDefinition.fromJson(Map<String, dynamic> json) {
    final legacySuccessResponse = json['successResponse']?.toString() ?? '';
    final bodyFields = listOf<ApiBodyFieldDefinition>(
      json['bodyFields'],
      (item) => ApiBodyFieldDefinition.fromJson(item),
    );
    final requestBody = json['requestBody']?.toString() ?? '';

    return ApiRequestDefinition(
      id: json['id']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      method: json['method']?.toString().toUpperCase() ?? 'GET',
      path: json['path']?.toString() ?? '',
      bodyMode: _resolveBodyMode(
        json['bodyMode']?.toString(),
        hasBodyFields: bodyFields.isNotEmpty,
        hasLegacyRequestBody: requestBody.isNotEmpty,
      ),
      headers: listOf<ApiKeyValueEntry>(
        json['headers'],
        (item) => ApiKeyValueEntry.fromJson(item),
      ),
      queryParams: listOf<ApiParameterDefinition>(
        json['queryParams'],
        (item) => ApiParameterDefinition.fromJson(item),
      ),
      pathParams: listOf<ApiParameterDefinition>(
        json['pathParams'],
        (item) => ApiParameterDefinition.fromJson(item),
      ),
      bodyFields: bodyFields,
      requestBody: requestBody,
      responses: responsesFrom(json['responses'], legacySuccessResponse),
      useProjectAuth: json['useProjectAuth'] != false,
      authConfig: json['authConfig'] is Map<String, dynamic>
          ? ApiAuthConfig.fromJson(json['authConfig'] as Map<String, dynamic>)
          : ApiAuthConfig.empty,
    );
  }
}

String _resolveBodyMode(
  String? value, {
  required bool hasBodyFields,
  required bool hasLegacyRequestBody,
}) {
  switch (value) {
    case 'none':
    case 'json':
    case 'form-data':
    case 'x-www-form-urlencoded':
      return value!;
    default:
      return hasBodyFields || hasLegacyRequestBody ? 'json' : 'none';
  }
}

List<ApiResponseDefinition> responsesFrom(
  dynamic value,
  String legacySuccessResponse,
) {
  final responses = listOf<ApiResponseDefinition>(
    value,
    (item) => ApiResponseDefinition.fromJson(item),
  );

  if (responses.isNotEmpty) return responses;

  return [
    ApiResponseDefinition(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      statusCode: 200,
      description: 'Успешный ответ',
      bodyExample: legacySuccessResponse,
    ),
  ];
}
