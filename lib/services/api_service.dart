import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'https://api.lyfemaster.com';
  String? _authToken;
  String? _csrfToken;

  ApiService() {
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('access_token');
    _csrfToken =
        prefs.getString('csrf_token') ??
        'ZZFSiJs7tZbopfbda9gv8ievM3MbVpYQiVLlzOD8lLooOppkuUhLx8JF3VbOxOzM';
  }

  Future<Map<String, dynamic>?> sendRecordingData({
    required String phoneNumber,
    required String s3Url,
    required int duration,
    required String timestamp,
    required String fileName,
  }) async {
    try {
      print('Sending call recording data to Lyfemaster API...');

      // Load tokens again to ensure they're current
      await _loadTokens();

      if (_authToken == null) {
        print('Authentication token not found. Please login first.');
        return {'success': false, 'error': 'Not authenticated'};
      }

      final url = Uri.parse('$baseUrl/ai-meeting-note');

      // Clean phone number (remove non-numeric characters)
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      // Prepare request body according to your API
      final body = jsonEncode({
        'meeting_platform': 'Phone Call',
        'video_url': s3Url,
        'contact_number': cleanPhoneNumber,
      });

      print('Request URL: $url');
      print('Request Body: $body');
      print('Phone Number: $cleanPhoneNumber');
      print('S3 URL: $s3Url');
      print('Auth Token: ${_authToken?.substring(0, 20)}...');
      print('CSRF Token: ${_csrfToken?.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'X-CSRFTOKEN': _csrfToken ?? '',
        },
        body: body,
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Recording data sent to API successfully');
        print('API Response: $responseData');

        return {
          'success': true,
          'data': responseData,
          'status_code': response.statusCode,
        };
      } else {
        print('Failed to send recording data: ${response.statusCode}');
        print('Error: ${response.body}');

        return {
          'success': false,
          'error': 'API error: ${response.statusCode}',
          'status_code': response.statusCode,
          'response_body': response.body,
        };
      }
    } catch (e, stackTrace) {
      print('Error sending to API: $e');
      print('Stack Trace: $stackTrace');

      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> clearTokens() async {
    _authToken = null;
    _csrfToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('csrf_token');
  }
}
