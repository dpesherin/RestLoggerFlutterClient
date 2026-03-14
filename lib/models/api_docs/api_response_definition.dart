import 'api_docs_parsing.dart';

class ApiResponseDefinition {
  final String id;
  final int statusCode;
  final String description;
  final String bodyExample;

  const ApiResponseDefinition({
    required this.id,
    required this.statusCode,
    required this.description,
    required this.bodyExample,
  });

  ApiResponseDefinition copyWith({
    String? id,
    int? statusCode,
    String? description,
    String? bodyExample,
  }) {
    return ApiResponseDefinition(
      id: id ?? this.id,
      statusCode: statusCode ?? this.statusCode,
      description: description ?? this.description,
      bodyExample: bodyExample ?? this.bodyExample,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'statusCode': statusCode,
        'description': description,
        'bodyExample': bodyExample,
      };

  factory ApiResponseDefinition.fromJson(Map<String, dynamic> json) {
    return ApiResponseDefinition(
      id: json['id']?.toString() ?? '',
      statusCode: parseIntValue<int>(json['statusCode']) ?? 200,
      description: json['description']?.toString() ?? 'Успешный ответ',
      bodyExample: json['bodyExample']?.toString() ?? '',
    );
  }
}
