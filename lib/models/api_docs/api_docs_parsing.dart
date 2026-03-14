T? parseIntValue<T extends num>(dynamic value) {
  if (value is int) return value as T;
  if (value is num) return value.toInt() as T;
  return int.tryParse(value?.toString() ?? '') as T?;
}

List<T> listOf<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) return <T>[];
  return value
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

List<String> listOfString(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.trim().isNotEmpty)
      .toList();
}
