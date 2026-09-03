import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:4000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:4000/api';
    } catch (_) {}
    return 'http://localhost:4000/api';
  }

  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> initBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('server_base_url');
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
    } else {
      _baseUrl = defaultBaseUrl;
    }
  }

  static Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = url;
    await prefs.setString('server_base_url', url);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await setToken(body['token']);
        return {'success': true, 'user': body['user']};
      }
      return {'success': false, 'error': body['error'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'error': 'Cannot connect to server at $_baseUrl: $e'};
    }
  }

  // Fetch Current User
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/me'), headers: await _headers());
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['user'];
      }
    } catch (_) {}
    return null;
  }

  // Fetch Dashboard Growth Analytics
  static Future<Map<String, dynamic>?> getDashboardAnalytics(String period) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/analytics/dashboard?period=$period'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  // Members API
  static Future<List<dynamic>> getMembers({String? status, String? search}) async {
    try {
      String query = '';
      if (status != null && status != 'ALL') query += 'status=$status&';
      if (search != null && search.isNotEmpty) query += 'search=$search&';

      final res = await http.get(
        Uri.parse('$_baseUrl/members?$query'),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> addMember(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/members'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateFollowUpStage(int memberId, String stage) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/members/$memberId/follow-up'),
        headers: await _headers(),
        body: jsonEncode({'follow_up_stage': stage}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Attendance API
  static Future<List<dynamic>> getAttendances() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/attendance'), headers: await _headers());
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getServiceTypes() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/attendance/service-types'), headers: await _headers());
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> recordAttendance(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/attendance'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // Financials API
  static Future<List<dynamic>> getOfferings() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/financials'), headers: await _headers());
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> recordOffering(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/financials'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
