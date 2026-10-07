import '../models/food_analysis_result.dart';

/// Storage service for saving analyzed meals locally.
/// Preserves meal logs with date/time, meal name, detected foods, calories, and macros.
class MealStorageService {
  MealStorageService._();
  static final MealStorageService instance = MealStorageService._();

  final List<FoodAnalysisResult> _savedMeals = [];

  /// Returns an unmodifiable list of saved meals.
  List<FoodAnalysisResult> get savedMeals => List.unmodifiable(_savedMeals);

  /// Saves a meal to the local history.
  Future<bool> saveMeal(FoodAnalysisResult result) async {
    // Avoid duplicate saves of the same meal instance
    if (_savedMeals.any((m) =>
        m.timestamp == result.timestamp && m.mealName == result.mealName)) {
      return false;
    }
    _savedMeals.insert(0, result);
    return true;
  }

  /// Checks if a meal has already been saved.
  bool isMealSaved(FoodAnalysisResult result) {
    return _savedMeals.any((m) =>
        m.timestamp == result.timestamp && m.mealName == result.mealName);
  }

  /// Clears saved meals (e.g. on log out).
  void clear() {
    _savedMeals.clear();
  }
}
