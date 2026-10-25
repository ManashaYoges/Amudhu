import 'package:flutter_test/flutter_test.dart';
import 'package:amudu/models/food_analysis_result.dart';
import 'package:amudu/services/meal_storage_service.dart';

void main() {
  group('MealStorageService Unit Tests', () {
    late MealStorageService service;

    final testMeal1 = FoodAnalysisResult(
      mealName: 'Avocado Toast with Poached Egg',
      timestamp: DateTime.now(),
      foods: const [
        FoodItem(name: 'Whole grain bread', quantity: '1 slice', estimatedGrams: 70, calories: 180, protein: 6, carbs: 32, fat: 2, fiber: 3),
        FoodItem(name: 'Avocado', quantity: '0.5 whole', estimatedGrams: 50, calories: 80, protein: 1, carbs: 4, fat: 7, fiber: 3),
        FoodItem(name: 'Egg', quantity: '1 egg', estimatedGrams: 50, calories: 75, protein: 6, carbs: 1, fat: 5, fiber: 0),
      ],
      total: const NutritionSummary(calories: 335, protein: 13.0, carbs: 37.0, fat: 14.0, fiber: 6.0, sugar: 2.0),
      balance: const MealBalance(
        score: 85,
        status: 'Balanced',
        description: 'Great mix of healthy fats, protein, and complex carbs.',
        tip: 'Consider adding some greens.',
        amudhuNote: 'Solid balanced meal.',
      ),
      vitaminsAndMinerals: const ['Vitamin E', 'Folate', 'Choline'],
    );

    final testMeal2 = FoodAnalysisResult(
      mealName: 'Vegetable Biryani',
      timestamp: DateTime.now(),
      foods: const [
        FoodItem(name: 'Basmati rice', quantity: '1 cup', estimatedGrams: 150, calories: 240, protein: 4, carbs: 50, fat: 1, fiber: 1),
        FoodItem(name: 'Mixed vegetables', quantity: '0.5 cup', estimatedGrams: 80, calories: 60, protein: 2, carbs: 12, fat: 0.5, fiber: 3),
      ],
      total: const NutritionSummary(calories: 300, protein: 6.0, carbs: 62.0, fat: 1.5, fiber: 4.0, sugar: 3.0),
      balance: const MealBalance(
        score: 75,
        status: 'Good',
        description: 'Flavorful dish, good fiber.',
        tip: 'Add a boiled egg or paneer for extra protein.',
        amudhuNote: 'Good carb energy source.',
      ),
      vitaminsAndMinerals: const ['Vitamin A', 'Vitamin C'],
    );

    setUp(() {
      service = MealStorageService.instance;
      service.clear();
    });

    tearDown(() {
      service.clear();
    });

    test('Initial savedMeals is empty', () {
      expect(service.savedMeals.isEmpty, isTrue);
      expect(service.todayCalories, equals(0));
      expect(service.todayProtein, equals(0.0));
    });

    test('saveMeal stores meal, calculates today calories, and notifies listeners', () async {
      bool notified = false;
      service.addListener(() => notified = true);

      final saved = await service.saveMeal(testMeal1);
      expect(saved, isTrue);
      expect(notified, isTrue);
      expect(service.savedMeals.length, equals(1));
      expect(service.isMealSaved(testMeal1), isTrue);
      expect(service.todayCalories, equals(335));
      expect(service.todayProtein, equals(13.0));
      expect(service.todayCarbs, equals(37.0));
      expect(service.todayFat, equals(14.0));
    });

    test('Multiple meals aggregate today nutrition metrics accurately', () async {
      await service.saveMeal(testMeal1);
      await service.saveMeal(testMeal2);

      expect(service.savedMeals.length, equals(2));
      expect(service.todayCalories, equals(335 + 300));
      expect(service.todayProtein, equals(13.0 + 6.0));
      expect(service.todayCarbs, equals(37.0 + 62.0));
      expect(service.todayFat, equals(14.0 + 1.5));
    });

    test('deleteMealByObject removes meal and updates metrics', () async {
      await service.saveMeal(testMeal1);
      await service.saveMeal(testMeal2);
      expect(service.savedMeals.length, equals(2));

      service.deleteMealByObject(testMeal1);
      expect(service.savedMeals.length, equals(1));
      expect(service.savedMeals.first.mealName, equals(testMeal2.mealName));
      expect(service.todayCalories, equals(300));
    });

    test('clear removes all saved meals', () async {
      await service.saveMeal(testMeal1);
      await service.saveMeal(testMeal2);

      service.clear();
      expect(service.savedMeals.isEmpty, isTrue);
      expect(service.todayCalories, equals(0));
    });
  });
}
