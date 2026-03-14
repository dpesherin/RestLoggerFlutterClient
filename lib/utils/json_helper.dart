class JsonHelper {
  static String formatContent(String content) {
    final json = content.trim();
    if (json.startsWith('{') && json.endsWith('}') ||
        json.startsWith('[') && json.endsWith(']')) {
      return json;
    }
    return content;
  }

  static bool isJson(String content) {
    final trimmed = content.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'));
  }
}
