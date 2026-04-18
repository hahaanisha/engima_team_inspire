import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class HomeProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  // Score
  int healthScore = 0;
  String category = '';
  Map<String, dynamic> breakdown = {};

  // Insights
  List<String> insights = [];
  Map<String, dynamic> risks = {};

  // Profile fields (shown in UI + editable)
  String fullName = '';
  String gender = '';
  int age = 0;
  double heightCm = 0;
  double weightKg = 0;
  int dailySteps = 0;
  double sleepDuration = 0;
  int restingHeartRate = 0;
  String stressLevel = '';
  String smoking = '';
  String alcohol = '';
  List<String> medicalConditions = [];
  List<String> familyHistory = [];

  double get bmi {
    if (heightCm == 0 || weightKg == 0) return 0;
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  String get bmiCategory {
    if (bmi == 0) return '';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25)   return 'Normal';
    if (bmi < 30)   return 'Overweight';
    return 'Obese';
  }

  // Called on screen load — uses cache, no API call
  Future<void> init() async {
    loading = true; notifyListeners();
    await _loadProfileFromStorage();
    await _loadScoreFromStorage();
    loading = false; notifyListeners();
  }

  // Called only when user taps refresh — hits API
  Future<void> forceRefresh() async {
    loading = true; error = null; notifyListeners();
    try {
      await _loadProfileFromStorage();
      final scoreRes   = await ApiService.getScore();
      final insightRes = await ApiService.getInsights();

      healthScore = scoreRes['health_score'] ?? 0;
      category    = scoreRes['category'] ?? '';
      breakdown   = Map<String, dynamic>.from(scoreRes['breakdown'] ?? {});
      insights    = List<String>.from(insightRes['insights'] ?? []);
      risks       = Map<String, dynamic>.from(insightRes['risks'] ?? {});

      // Cache it
      await StorageService.saveScoreData({
        'health_score': healthScore,
        'category': category,
        'breakdown': breakdown,
        'insights': insights,
        'risks': risks,
      });
    } catch (e) {
      error = 'Failed to refresh. Check your connection.';
    }
    loading = false; notifyListeners();
  }

  Future<void> _loadProfileFromStorage() async {
    final data = await StorageService.getProfileData();
    if (data.isEmpty) return;
    fullName         = data['full_name'] ?? '';
    gender           = data['gender'] ?? '';
    age              = (data['age'] ?? 0) as int;
    heightCm         = (data['height_cm'] ?? 0).toDouble();
    weightKg         = (data['weight_kg'] ?? 0).toDouble();
    dailySteps       = (data['daily_steps'] ?? 0) as int;
    sleepDuration    = (data['sleep_duration'] ?? 0).toDouble();
    restingHeartRate = (data['resting_heart_rate'] ?? 0) as int;
    stressLevel      = data['stress_level'] ?? '';
    smoking          = data['smoking'] ?? '';
    alcohol          = data['alcohol'] ?? '';
    medicalConditions = List<String>.from(data['medical_conditions'] ?? []);
    familyHistory    = List<String>.from(data['family_history'] ?? []);
  }

  Future<void> _loadScoreFromStorage() async {
    final cached = await StorageService.getScoreData();
    if (cached == null) {
      // First time — fetch from API and cache
      await forceRefresh();
      return;
    }
    healthScore = cached['health_score'] ?? 0;
    category    = cached['category'] ?? '';
    breakdown   = Map<String, dynamic>.from(cached['breakdown'] ?? {});
    insights    = List<String>.from(cached['insights'] ?? []);
    risks       = Map<String, dynamic>.from(cached['risks'] ?? {});
  }

  // Called from profile edit page to update locally
  Future<void> updateProfile({
    double? heightCm,
    double? weightKg,
    int? dailySteps,
    double? sleepDuration,
    int? restingHeartRate,
    String? stressLevel,
    String? smoking,
    String? alcohol,
  }) async {
    if (heightCm != null) this.heightCm = heightCm;
    if (weightKg != null) this.weightKg = weightKg;
    if (dailySteps != null) this.dailySteps = dailySteps;
    if (sleepDuration != null) this.sleepDuration = sleepDuration;
    if (restingHeartRate != null) this.restingHeartRate = restingHeartRate;
    if (stressLevel != null) this.stressLevel = stressLevel;
    if (smoking != null) this.smoking = smoking;
    if (alcohol != null) this.alcohol = alcohol;

    // Persist changes locally
    final existing = await StorageService.getProfileData();
    existing['height_cm']          = this.heightCm;
    existing['weight_kg']          = this.weightKg;
    existing['daily_steps']        = this.dailySteps;
    existing['sleep_duration']     = this.sleepDuration;
    existing['resting_heart_rate'] = this.restingHeartRate;
    existing['stress_level']       = this.stressLevel;
    existing['smoking']            = this.smoking;
    existing['alcohol']            = this.alcohol;
    await StorageService.saveProfileData(existing);

    notifyListeners();
  }
}