import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/shared_prefs.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.lyfemaster.com';
  String? _csrfToken;

  AuthService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _loadCSRFToken();
  }

  Future<void> _loadCSRFToken() async {
    // Optional: load from storage or API
    _csrfToken =
        'ZZFSiJs7tZbopfbda9gv8ievM3MbVpYQiVLlzOD8lLooOppkuUhLx8JF3VbOxOzM';
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/signin',
        data: jsonEncode({'email': email, 'password': password}),
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'application/json',
            'X-CSRFTOKEN': _csrfToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final tokenExpiry = DateTime.now().add(const Duration(days: 7));

        final user = User(
          id: data['user_id']?.toString() ?? '0',
          email: email,
          accessToken: data['access'] ?? '',
          refreshToken: data['refresh'] ?? '',
          tokenExpiry: tokenExpiry,
        );

        await SharedPrefs.saveUser(
          id: user.id,
          email: user.email,
          accessToken: user.accessToken,
          refreshToken: user.refreshToken,
          tokenExpiry: tokenExpiry,
        );

        return user;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final accessToken = await SharedPrefs.getAccessToken();
      if (accessToken != null) {
        await _dio.post(
          '/auth/logout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $accessToken',
              'X-CSRFTOKEN': _csrfToken,
            },
          ),
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await SharedPrefs.logout();
    }
  }

  Future<String?> refreshToken() async {
    try {
      final refreshToken = await SharedPrefs.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await _dio.post(
        '/auth/token/refresh',
        data: jsonEncode({'refresh': refreshToken}),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-CSRFTOKEN': _csrfToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'] ?? '';
        final newExpiry = DateTime.now().add(const Duration(days: 7));

        await SharedPrefs.updateAccessToken(
          newAccessToken,
          newExpiry: newExpiry,
        );

        return newAccessToken;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }
    return null;
  }

  Future<String?> getValidAccessToken() async {
    final isExpired = await SharedPrefs.isTokenExpired();
    if (isExpired) return await refreshToken();
    return await SharedPrefs.getAccessToken();
  }

  Future<bool> checkAuthStatus() async => await SharedPrefs.isLoggedIn();

  Future<User?> getCurrentUser() async {
    final userData = await SharedPrefs.getUser();
    if (userData == null) return null;
    return User.fromJson(userData);
  }
}
