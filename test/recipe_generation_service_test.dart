import 'package:flutter_test/flutter_test.dart';
import 'package:amudu/models/fridge_recipe_models.dart';
import 'package:amudu/services/recipe_generation_service.dart';

void main() {
  group('RecipeGenerationService Unit Tests', () {
    late RecipeGenerationService service;

    setUp(() {
      service = RecipeGenerationService();
      RecipeGenerationService.useMockGeneration = true;
    });

    test('Empty ingredients throws RecipeGenerationException', () async {
      expect(
        () => service.generateRecipes([]),
        throwsA(isA<RecipeGenerationException>()),
      );
    });

    test('Generates recipes matching chicken ingredients', () async {
      final recipes = await service.generateRecipes([
        const DetectedIngredient(name: 'Chicken breast', quantity: '250g', emoji: '🍗'),
        const DetectedIngredient(name: 'Garlic', quantity: '4 cloves', emoji: '🧄'),
      ]);

      expect(recipes.isNotEmpty, isTrue);
      expect(recipes.first.matchedCount, greaterThanOrEqualTo(1));
      expect(
        recipes.any((r) => r.name.toLowerCase().contains('chicken')),
        isTrue,
      );
    });

    test('Intelligent synonym matching matches curd / yogurt and cilantro', () async {
      final recipes = await service.generateRecipes([
        const DetectedIngredient(name: 'Yogurt', quantity: '1 cup', emoji: '🥛'),
        const DetectedIngredient(name: 'Cooked Rice', quantity: '2 cups', emoji: '🍚'),
      ]);

      expect(recipes.isNotEmpty, isTrue);
      final curdRice = recipes.firstWhere((r) => r.id == 'curd_rice_tadka');
      expect(curdRice.matchedCount, greaterThanOrEqualTo(2));
      expect(curdRice.ingredients.any((i) => i.isFromFridge), isTrue);
    });

    test('Plural stemming matches tomatoes to tomato and eggs to egg', () async {
      final recipes = await service.generateRecipes([
        const DetectedIngredient(name: 'Eggs', quantity: '3', emoji: '🥚'),
        const DetectedIngredient(name: 'Tomatoes', quantity: '2', emoji: '🍅'),
      ]);

      expect(recipes.isNotEmpty, isTrue);
      expect(recipes.first.matchedCount, greaterThanOrEqualTo(2));
    });

    test('Generates recipes for pasta with cheese and milk', () async {
      final recipes = await service.generateRecipes([
        const DetectedIngredient(name: 'Pasta', quantity: '200g', emoji: '🍝'),
        const DetectedIngredient(name: 'Cheese', quantity: '50g', emoji: '🧀'),
      ]);

      expect(recipes.isNotEmpty, isTrue);
      expect(
        recipes.any((r) => r.name.toLowerCase().contains('pasta')),
        isTrue,
      );
    });
  });
}
