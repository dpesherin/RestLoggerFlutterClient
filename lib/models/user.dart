class User {
  final String login;
  final String? consumerKey;
  final String? sessionId;

  User({
    required this.login,
    this.consumerKey,
    this.sessionId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      login: json['login'] ?? json['username'] ?? '',
      consumerKey: json['consumerKey']?.toString(),
      sessionId: json['sessionId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'login': login,
      if (consumerKey != null) 'consumerKey': consumerKey,
      if (sessionId != null) 'sessionId': sessionId,
    };
  }
}
