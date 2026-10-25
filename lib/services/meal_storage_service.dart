import 'package:flutter/foundation.dart';
import '../models/food_analysis_result.dart';
import 'api_client.dart';
import 'auth_service.dart';

class MealStorageService extends ChangeNotifier {
  MealStorageService._();
  static final MealStorageService instance = MealStorageService._();
  final List<FoodAnalysisResult> _savedMeals = [];
  final Map<String, String> _mealIds = {};
  List<FoodAnalysisResult> get savedMeals => List.unmodifiable(_savedMeals);

  String _key(FoodAnalysisResult meal) => '${meal.timestamp.toIso8601String()}|${meal.mealName}';

  String? getMealId(FoodAnalysisResult meal) => _mealIds[_key(meal)];

  /// Returns meals logged today
  List<FoodAnalysisResult> getTodayMeals() {
    final now = DateTime.now();
    return _savedMeals.where((m) {
      return m.timestamp.year == now.year &&
          m.timestamp.month == now.month &&
          m.timestamp.day == now.day;
    }).toList();
  }

  /// Calculates total calories consumed today
  int get todayCalories {
    final today = getTodayMeals();
    return today.fold<int>(0, (sum, m) => sum + m.total.calories);
  }

  /// Total protein consumed today in grams
  double get todayProtein {
    final today = getTodayMeals();
    return today.fold<double>(0.0, (sum, m) => sum + m.total.protein);
  }

  /// Total carbs consumed today in grams
  double get todayCarbs {
    final today = getTodayMeals();
    return today.fold<double>(0.0, (sum, m) => sum + m.total.carbs);
  }

  /// Total fat consumed today in grams
  double get todayFat {
    final today = getTodayMeals();
    return today.fold<double>(0.0, (sum, m) => sum + m.total.fat);
  }

  Future<void> loadMeals() async {
    if (!AuthService.instance.isAuthenticated) {
      notifyListeners();
      return;
    }
    try {
      final response = await ApiClient.instance.get('/api/meals');
      final records = response['meals'] as List<dynamic>? ?? [];
      _savedMeals.clear();
      _mealIds.clear();
      for (final record in records.whereType<Map<String, dynamic>>()) {
        final meal = FoodAnalysisResult.fromJson(record);
        _savedMeals.add(meal);
        final id = record['id'] as String?;
        if (id != null) _mealIds[_key(meal)] = id;
      }
      notifyListeners();
    } catch (_) {
      notifyListeners();
    }
  }

  Future<bool> saveMeal(FoodAnalysisResult result) async {
    if (isMealSaved(result)) return false;
    if (AuthService.instance.isAuthenticated) {
      try {
        final payload = result.toJson()..remove('imagePath');
        final response = await ApiClient.instance.post('/api/meals', body: payload);
        final savedMeal = response['meal'] as Map<String, dynamic>?;
        final id = savedMeal?['id'] as String?;
        if (id != null) _mealIds[_key(result)] = id;
      } catch (_) {}
    }
    _savedMeals.insert(0, result);
    notifyListeners();
    return true;
  }

  bool isMealSaved(FoodAnalysisResult result) => _savedMeals.any((meal) =>
    meal.timestamp == result.timestamp && meal.mealName == result.mealName);

  Future<void> updateMeal(String id, FoodAnalysisResult result) async {
    final payload = result.toJson()..remove('imagePath');
    await ApiClient.instance.patch('/api/meals/$id', body: payload);
    final previousEntries = _mealIds.entries.where((entry) => entry.value == id).toList();
    final previousKey = previousEntries.isEmpty ? null : previousEntries.first.key;
    if (previousKey != null) {
      final index = _savedMeals.indexWhere((meal) => _key(meal) == previousKey);
      if (index >= 0) _savedMeals[index] = result;
      _mealIds.remove(previousKey);
    }
    _mealIds[_key(result)] = id;
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    if (AuthService.instance.isAuthenticated) {
      try {
        await ApiClient.instance.delete('/api/meals/$id');
      } catch (_) {}
    }
    final matchingEntries = _mealIds.entries.where((entry) => entry.value == id).toList();
    final key = matchingEntries.isEmpty ? null : matchingEntries.first.key;
    if (key != null) {
      _savedMeals.removeWhere((meal) => _key(meal) == key);
      _mealIds.remove(key);
    } else {
      // If no key found, delete by index or id if stored
      _savedMeals.removeWhere((meal) => _mealIds[_key(meal)] == id);
    }
    notifyListeners();
  }

  void deleteMealByObject(FoodAnalysisResult meal) {
    final id = getMealId(meal);
    if (id != null) {
      deleteMeal(id);
    } else {
      _savedMeals.removeWhere((m) => _key(m) == _key(meal));
      notifyListeners();
    }
  }

  void clear() {
    _savedMeals.clear();
    _mealIds.clear();
    notifyListeners();
  }
}
