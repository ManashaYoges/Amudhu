// ignore_for_file: avoid_print

import 'package:amudu/models/food_analysis_result.dart';
import 'package:amudu/services/nutrition_database_service.dart';

void assertTrue(bool condition, String message) {
  if (!condition) {
    throw Exception('FAILED: $message');
  }
}

void assertEqual(dynamic actual, dynamic expected, String message) {
  if (actual != expected) {
    throw Exception('FAILED: $message (Expected: $expected, Got: $actual)');
  }
}

void main() {
  print('====================================================');
  print('DART FOOD RECOGNITION & NUTRITION PIPELINE TEST RUN');
  print('====================================================\n');

  final db = NutritionDatabaseService.instance;

  // Test 1: Cooked Rice portion calculation
  print('Running Test 1: Cooked White Rice portion scaling...');
  final rice = db.calculateFoodItem(
    name: 'Cooked white rice',
    grams: 180,
    confidence: 0.94,
  );
  assertEqual(rice.name, 'Cooked white rice', 'Rice name');
  assertEqual(rice.calories, 234, 'Rice calories: 130 * 1.8 = 234');
  assertEqual(rice.protein, 4.9, 'Rice protein: 2.7 * 1.8 = 4.9');
  assertEqual(rice.carbs, 50.8, 'Rice carbs: 28.2 * 1.8 = 50.8');
  assertEqual(rice.portionIsEstimated, true, 'Portion is marked estimated');
  print('  ✓ Test 1 Passed\n');

  // Test 2: Idli, Sambar, Chutney meal
  print('Running Test 2: Idli, Sambar, Chutney meal assembly...');
  final idli = db.calculateFoodItem(name: 'Steamed Idli', grams: 120, confidence: 0.95);
  final sambar = db.calculateFoodItem(name: 'Vegetable sambar', grams: 100, confidence: 0.88);
  final chutney = db.calculateFoodItem(name: 'Coconut chutney', grams: 30, confidence: 0.90);

  final total = FoodAnalysisResult.calculateTotal([idli, sambar, chutney]);
  assertEqual(total.calories, 166 + 78 + 63, 'Total calories = 307');
  assertTrue(total.protein >= 7.0, 'Protein >= 7.0g');
  assertTrue(total.carbs >= 40.0, 'Carbs >= 40g');
  print('  ✓ Test 2 Passed\n');

  // Test 3: Structured JSON deserialization
  print('Running Test 3: FoodAnalysisResult from structured JSON...');
  final testJson = {
    "mealName": "Rice, dal and poriyal",
    "foods": [
      {
        "name": "Cooked white rice",
        "confidence": 0.91,
        "estimatedGrams": 180,
        "portionIsEstimated": true,
        "alternatives": ["Brown rice"],
        "notes": null,
        "calories": 234,
        "protein": 4.9,
        "carbs": 50.8,
        "fat": 0.5,
        "fiber": 0.7,
        "sugar": 0.2
      },
      {
        "name": "Cooked lentil dal",
        "confidence": 0.78,
        "estimatedGrams": 120,
        "portionIsEstimated": true,
        "alternatives": ["Another lentil preparation"],
        "notes": "Exact preparation is uncertain",
        "calories": 139,
        "protein": 8.8,
        "carbs": 21.8,
        "fat": 1.8,
        "fiber": 5.0,
        "sugar": 1.0
      }
    ],
    "nutrition": {
      "calories": 373,
      "protein": 13.7,
      "carbs": 72.6,
      "fat": 2.3,
      "fiber": 5.7,
      "sugar": 1.2
    },
    "analysisSource": "real_ai",
    "isEstimate": true,
    "uncertaintyNotes": "Good visibility"
  };

  final parsedResult = FoodAnalysisResult.fromJson(testJson);
  assertEqual(parsedResult.mealName, 'Rice, dal and poriyal', 'Meal name parsed');
  assertEqual(parsedResult.foods.length, 2, '2 foods parsed');
  assertEqual(parsedResult.foods[0].confidence, 0.91, 'Confidence parsed');
  assertEqual(parsedResult.foods[1].notes, 'Exact preparation is uncertain', 'Notes parsed');
  assertEqual(parsedResult.total.calories, 373, 'Calories parsed from nutrition key');
  assertEqual(parsedResult.analysisSource, 'real_ai', 'Source is real_ai');
  assertEqual(parsedResult.isEstimate, true, 'isEstimate is true');
  print('  ✓ Test 3 Passed\n');

  // Test 4: Dynamic User Recalculation
  print('Running Test 4: User edit portion recalculation...');
  final editedFoods = [
    parsedResult.foods[0].copyWith(estimatedGrams: 250), // Increased rice portion
    parsedResult.foods[1],
  ];

  final recalculatedResult = db.recalculateMeal(
    original: parsedResult,
    updatedFoods: editedFoods,
  );

  assertEqual(recalculatedResult.analysisSource, 'user_edited', 'Source marked user_edited');
  assertEqual(recalculatedResult.foods[0].calories, 325, 'Updated rice: 130 * 2.5 = 325');
  assertEqual(recalculatedResult.total.calories, 325 + 139, 'Sum = 464');
  print('  ✓ Test 4 Passed\n');

  print('====================================================');
  print('ALL DART VERIFICATION TESTS PASSED SUCCESSFULLY!');
  print('====================================================');
}
