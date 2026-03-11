class JsonHelper {
  static String formatContent(String content) {
    try {
      if (content.trim().startsWith('{') || content.trim().startsWith('[')) {
        final json = content.trim();
        if (json.startsWith('{') && json.endsWith('}') ||
            json.startsWith('[') && json.endsWith(']')) {
          return json;
        }
      }
    } catch (e) {}
    return content;
  }

  static bool isJson(String content) {
    try {
      final trimmed = content.trim();
      return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'));
    } catch (e) {
      return false;
    }
  }
}
