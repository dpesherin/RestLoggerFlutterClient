import 'api_dictionary_entry.dart';
import 'api_docs_parsing.dart';

class ApiBodyFieldDefinition {
  final String id;
  final String name;
  final String description;
  final String type;
  final bool required;
  final bool isArray;
  final String arrayItemType;
  final String arrayItemDescription;
  final String arrayItemExample;
  final String example;
  final bool isDictionary;
  final List<ApiDictionaryEntry> dictionaryEntries;
  final List<ApiBodyFieldDefinition> children;

  const ApiBodyFieldDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.required,
    required this.isArray,
    required this.arrayItemType,
    required this.arrayItemDescription,
    required this.arrayItemExample,
    required this.example,
    required this.isDictionary,
    required this.dictionaryEntries,
    required this.children,
  });

  ApiBodyFieldDefinition copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    bool? required,
    bool? isArray,
    String? arrayItemType,
    String? arrayItemDescription,
    String? arrayItemExample,
    String? example,
    bool? isDictionary,
    List<ApiDictionaryEntry>? dictionaryEntries,
    List<ApiBodyFieldDefinition>? children,
  }) {
    return ApiBodyFieldDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      required: required ?? this.required,
      isArray: isArray ?? this.isArray,
      arrayItemType: arrayItemType ?? this.arrayItemType,
      arrayItemDescription: arrayItemDescription ?? this.arrayItemDescription,
      arrayItemExample: arrayItemExample ?? this.arrayItemExample,
      example: example ?? this.example,
      isDictionary: isDictionary ?? this.isDictionary,
      dictionaryEntries: dictionaryEntries ?? this.dictionaryEntries,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type,
        'required': required,
        'isArray': isArray,
        'arrayItemType': arrayItemType,
        'arrayItemDescription': arrayItemDescription,
        'arrayItemExample': arrayItemExample,
        'example': example,
        'isDictionary': isDictionary,
        'dictionaryEntries':
            dictionaryEntries.map((entry) => entry.toJson()).toList(),
        'children': children.map((entry) => entry.toJson()).toList(),
      };

  factory ApiBodyFieldDefinition.fromJson(Map<String, dynamic> json) {
    return ApiBodyFieldDefinition(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'string',
      required: json['required'] == true,
      isArray: json['isArray'] == true,
      arrayItemType: json['arrayItemType']?.toString() ?? 'string',
      arrayItemDescription: json['arrayItemDescription']?.toString() ?? '',
      arrayItemExample: json['arrayItemExample']?.toString() ?? '',
      example: json['example']?.toString() ?? '',
      isDictionary: json['isDictionary'] == true,
      dictionaryEntries: listOf<ApiDictionaryEntry>(
        json['dictionaryEntries'],
        (item) => ApiDictionaryEntry.fromJson(item),
      ),
      children: listOf<ApiBodyFieldDefinition>(
        json['children'],
        (item) => ApiBodyFieldDefinition.fromJson(item),
      ),
    );
  }
}
