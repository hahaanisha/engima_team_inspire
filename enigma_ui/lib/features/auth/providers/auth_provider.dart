import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  Future<String?> login(String mobile, String pin) async {
    loading = true; error = null; notifyListeners();
    try {
      final res = await ApiService.login(mobile, pin);
      if (res['token'] != null) {
        await StorageService.saveToken(res['token']);
        loading = false; notifyListeners();
        return res['token'];
      }
      error = res['message'] ?? 'Login failed';
    } catch (e) {
      error = 'Network error. Check your connection.';
    }
    loading = false; notifyListeners();
    return null;
  }

  Future<String?> register(String mobile, String pin) async {
    loading = true; error = null; notifyListeners();
    try {
      final res = await ApiService.register(mobile, pin);
      if (res['token'] != null) {
        await StorageService.saveToken(res['token']);
        loading = false; notifyListeners();
        return res['token'];
      }
      error = res['message'] ?? 'Registration failed';
    } catch (e) {
      error = 'Network error. Check your connection.';
    }
    loading = false; notifyListeners();
    return null;
  }
}