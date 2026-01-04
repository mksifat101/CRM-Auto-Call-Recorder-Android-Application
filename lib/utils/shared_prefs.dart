import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static Future<void> saveUser({
    required String id,
    required String email,
    required String accessToken,
    required String refreshToken,
    required DateTime tokenExpiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('user_id', id);
    await prefs.setString('user_email', email);
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('token_expiry', tokenExpiry.toIso8601String());
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!isLoggedIn) return null;

    return {
      'id': prefs.getString('user_id') ?? '',
      'email': prefs.getString('user_email') ?? '',
      'access_token': prefs.getString('access_token'),
      'refresh_token': prefs.getString('refresh_token'),
      'token_expiry': prefs.getString('token_expiry'),
    };
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString('token_expiry');

    if (expiryString == null) return true;

    final expiry = DateTime.parse(expiryString);
    return DateTime.now().isAfter(expiry);
  }

  static Future<void> updateAccessToken(
    String newToken, {
    DateTime? newExpiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('access_token', newToken);

    if (newExpiry != null) {
      await prefs.setString('token_expiry', newExpiry.toIso8601String());
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('isLoggedIn');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry');
  }
}
