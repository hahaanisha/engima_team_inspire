import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String mobile, String pin) async {
    final res = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'pin': pin}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> register(String mobile, String pin) async {
    final res = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'pin': pin}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(ApiConstants.profile),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getScore() async {
    final res = await http.get(
      Uri.parse(ApiConstants.score),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getInsights() async {
    final res = await http.get(
      Uri.parse(ApiConstants.insights),
      headers: await _authHeaders(),
    );
    return jsonDecode(res.body);
  }
}