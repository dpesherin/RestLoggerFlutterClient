class ApiDictionaryEntry {
  final String value;
  final String description;

  const ApiDictionaryEntry({
    required this.value,
    required this.description,
  });

  ApiDictionaryEntry copyWith({
    String? value,
    String? description,
  }) {
    return ApiDictionaryEntry(
      value: value ?? this.value,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'description': description,
      };

  factory ApiDictionaryEntry.fromJson(Map<String, dynamic> json) {
    return ApiDictionaryEntry(
      value: json['value']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
