import '../models/food_analysis_result.dart';
import 'api_client.dart';
import 'auth_service.dart';

class MealStorageService {
  MealStorageService._();
  static final MealStorageService instance = MealStorageService._();
  final List<FoodAnalysisResult> _savedMeals = [];
  final Map<String, String> _mealIds = {};
  List<FoodAnalysisResult> get savedMeals => List.unmodifiable(_savedMeals);

  String _key(FoodAnalysisResult meal) => '${meal.timestamp.toIso8601String()}|${meal.mealName}';

  Future<void> loadMeals() async {
    if (!AuthService.instance.isAuthenticated) return;
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
  }

  Future<bool> saveMeal(FoodAnalysisResult result) async {
    if (isMealSaved(result)) return false;
    if (AuthService.instance.isAuthenticated) {
      final payload = result.toJson()..remove('imagePath');
      final response = await ApiClient.instance.post('/api/meals', body: payload);
      final savedMeal = response['meal'] as Map<String, dynamic>?;
      final id = savedMeal?['id'] as String?;
      if (id != null) _mealIds[_key(result)] = id;
    }
    _savedMeals.insert(0, result);
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
  }

  Future<void> deleteMeal(String id) async {
    await ApiClient.instance.delete('/api/meals/$id');
    final matchingEntries = _mealIds.entries.where((entry) => entry.value == id).toList();
    final key = matchingEntries.isEmpty ? null : matchingEntries.first.key;
    if (key != null) {
      _savedMeals.removeWhere((meal) => _key(meal) == key);
      _mealIds.remove(key);
    }
  }

  void clear() { _savedMeals.clear(); _mealIds.clear(); }
}
