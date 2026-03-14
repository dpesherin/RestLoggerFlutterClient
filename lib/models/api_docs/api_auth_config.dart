class ApiAuthConfig {
  final String type;
  final String headerName;
  final String scheme;
  final String token;
  final String username;
  final String password;
  final String apiKey;
  final String apiKeyLocation;
  final String apiKeyName;

  const ApiAuthConfig({
    required this.type,
    required this.headerName,
    required this.scheme,
    required this.token,
    required this.username,
    required this.password,
    required this.apiKey,
    required this.apiKeyLocation,
    required this.apiKeyName,
  });

  ApiAuthConfig copyWith({
    String? type,
    String? headerName,
    String? scheme,
    String? token,
    String? username,
    String? password,
    String? apiKey,
    String? apiKeyLocation,
    String? apiKeyName,
  }) {
    return ApiAuthConfig(
      type: type ?? this.type,
      headerName: headerName ?? this.headerName,
      scheme: scheme ?? this.scheme,
      token: token ?? this.token,
      username: username ?? this.username,
      password: password ?? this.password,
      apiKey: apiKey ?? this.apiKey,
      apiKeyLocation: apiKeyLocation ?? this.apiKeyLocation,
      apiKeyName: apiKeyName ?? this.apiKeyName,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'headerName': headerName,
        'scheme': scheme,
        'token': token,
        'username': username,
        'password': password,
        'apiKey': apiKey,
        'apiKeyLocation': apiKeyLocation,
        'apiKeyName': apiKeyName,
      };

  factory ApiAuthConfig.fromJson(Map<String, dynamic> json) {
    return ApiAuthConfig(
      type: json['type']?.toString() ?? 'none',
      headerName: json['headerName']?.toString() ?? 'Authorization',
      scheme: json['scheme']?.toString() ?? 'Bearer',
      token: json['token']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      apiKey: json['apiKey']?.toString() ?? '',
      apiKeyLocation: json['apiKeyLocation']?.toString() ?? 'header',
      apiKeyName: json['apiKeyName']?.toString() ?? 'X-API-Key',
    );
  }

  static const empty = ApiAuthConfig(
    type: 'none',
    headerName: 'Authorization',
    scheme: 'Bearer',
    token: '',
    username: '',
    password: '',
    apiKey: '',
    apiKeyLocation: 'header',
    apiKeyName: 'X-API-Key',
  );
}
