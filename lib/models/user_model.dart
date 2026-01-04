class User {
  final String id;
  final String email;
  final String accessToken;
  final String refreshToken;
  final DateTime tokenExpiry;

  User({
    required this.id,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiry,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expiry': tokenExpiry.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '0',
      email: json['email'] ?? '',
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenExpiry: DateTime.parse(json['token_expiry']),
    );
  }
}
