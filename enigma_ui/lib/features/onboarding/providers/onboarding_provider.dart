import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class OnboardingProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  String fullName = '';
  String gender   = 'Male';
  int    age      = 25;
  double heightCm = 170;
  double weightKg = 65;
  int    dailySteps = 6000;
  String sittingTime = '4';
  String exerciseFrequency = '3';
  double sleepDuration = 7;
  List<String> medicalConditions = ['None'];
  List<String> familyHistory = ['None'];
  int    restingHeartRate = 72;
  String smoking  = 'No';
  String alcohol  = 'None';
  String stressLevel = 'Low';
  double lat = 0, long = 0;

  Map<String, dynamic> _toMap() => {
    'full_name': fullName,
    'gender': gender,
    'age': age,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'daily_steps': dailySteps,
    'step_length': 0.75,
    'sitting_time': sittingTime,
    'exercise_frequency': exerciseFrequency,
    'sleep_duration': sleepDuration,
    'medical_conditions': medicalConditions,
    'family_history': familyHistory,
    'resting_heart_rate': restingHeartRate,
    'smoking': smoking,
    'alcohol': alcohol,
    'stress_level': stressLevel,
    'lat': lat,
    'long': long,
  };

  Future<bool> submit() async {
    loading = true; error = null; notifyListeners();
    try {
      final data = _toMap();
      await ApiService.saveProfile(data);
      // ← Save locally so HomeProvider can read it
      await StorageService.saveProfileData(data);
      await StorageService.setProfileDone(true);
      loading = false; notifyListeners();
      return true;
    } catch (e) {
      error = 'Failed to save profile. Try again.';
      loading = false; notifyListeners();
      return false;
    }
  }
}