class ApiKeyValueEntry {
  final String key;
  final String value;
  final bool enabled;

  const ApiKeyValueEntry({
    required this.key,
    required this.value,
    this.enabled = true,
  });

  ApiKeyValueEntry copyWith({
    String? key,
    String? value,
    bool? enabled,
  }) {
    return ApiKeyValueEntry(
      key: key ?? this.key,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'enabled': enabled,
      };

  factory ApiKeyValueEntry.fromJson(Map<String, dynamic> json) {
    return ApiKeyValueEntry(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      enabled: json['enabled'] != false,
    );
  }
}
