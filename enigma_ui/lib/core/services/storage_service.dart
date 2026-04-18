import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey    = 'auth_token';
  static const _profileDone = 'profile_done';
  static const _profileData = 'profile_data';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setProfileDone(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileDone, val);
  }

  static Future<bool> isProfileDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileDone) ?? false;
  }

  // Save entire profile map as JSON
  static Future<void> saveProfileData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileData, jsonEncode(data));
  }

  // Read profile map from JSON
  static Future<Map<String, dynamic>> getProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileData);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  // Save score/insights to avoid unnecessary API calls
  static Future<void> saveScoreData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('score_data', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getScoreData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('score_data');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}