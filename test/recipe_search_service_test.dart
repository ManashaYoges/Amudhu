import 'package:flutter_test/flutter_test.dart';
import 'package:amudu/models/fridge_recipe_models.dart';
import 'package:amudu/services/recipe_search_service.dart';

void main() {
  group('RecipeSearchService Unit Tests', () {
    late RecipeSearchService service;

    setUp(() {
      service = RecipeSearchService();
      RecipeSearchService.useMockApi = true;
    });

    test('Searching with empty query throws RecipeSearchException', () async {
      expect(
        () => service.search('   '),
        throwsA(isA<RecipeSearchException>()),
      );
    });

    test('Searching for "bread" returns matching recipes and cooking tutorials', () async {
      final result = await service.search('bread');

      expect(result.query, equals('bread'));
      expect(result.recipes.isNotEmpty, isTrue);
      expect(
        result.recipes.any((r) =>
            r.name.toLowerCase().contains('bread') ||
            r.ingredients.any((i) => i.name.toLowerCase().contains('bread'))),
        isTrue,
      );
      expect(result.videos.isNotEmpty, isTrue);
      expect(result.availableCuisines.contains('All'), isTrue);
      expect(result.relatedRecommendations.isNotEmpty, isTrue);
    });

    test('Searching for "paneer" returns vegetarian recipes', () async {
      final result = await service.search('paneer');

      expect(result.recipes.isNotEmpty, isTrue);
      expect(result.recipes.every((r) => r.isVegetarian), isTrue);
      expect(
        result.recipes.any((r) => r.name.toLowerCase().contains('paneer')),
        isTrue,
      );
    });

    test('Searching for "pasta" returns Italian cuisine options', () async {
      final result = await service.search('pasta');

      expect(result.recipes.isNotEmpty, isTrue);
      expect(result.availableCuisines.contains('Italian'), isTrue);
    });

    test('Gibberish query returns clean empty result', () async {
      final result = await service.search('xyz999qwerty');

      expect(result.recipes.isEmpty, isTrue);
      expect(result.videos.isEmpty, isTrue);
    });

    test('Favorite recipes toggle, save, check, and remove operations', () async {
      const testRecipe = Recipe(
        id: 'test_fav_recipe_001',
        name: 'Crispy Garlic Toast',
        emoji: '🍞',
        description: 'Golden toast with garlic butter.',
        prepTime: '5 min',
        cookTime: '5 min',
        totalTime: '10 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Italian',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Bread', quantity: '2 slices'),
          RecipeIngredient(name: 'Butter', quantity: '1 tbsp'),
          RecipeIngredient(name: 'Garlic', quantity: '2 cloves'),
        ],
        steps: ['Mix garlic butter', 'Toast until crisp'],
        nutrition: RecipeNutrition(calories: 210, protein: 5.0, carbs: 24.0, fat: 10.0),
      );

      // Initially not favorite
      expect(service.isFavorite(testRecipe.id), isFalse);

      // Save to favorite
      await service.saveFavorite(testRecipe);
      expect(service.isFavorite(testRecipe.id), isTrue);

      final favorites = await service.getFavorites();
      expect(favorites.any((r) => r.id == testRecipe.id), isTrue);

      // Remove from favorite
      await service.removeFavorite(testRecipe.id);
      expect(service.isFavorite(testRecipe.id), isFalse);
    });

    test('Recipe and CookingVideo JSON round-trip serialization', () {
      final json = {
        'id': 'rec_json_1',
        'name': 'Penne Arrabiata',
        'emoji': '🍝',
        'description': 'Spicy tomato pasta with garlic and herbs.',
        'prepTime': '8 min',
        'cookTime': '12 min',
        'totalTime': '20 min',
        'servings': 2,
        'difficulty': 'Easy',
        'cuisine': 'Italian',
        'isVegetarian': true,
        'ingredients': [
          {'name': 'Penne', 'quantity': '200g', 'isFromFridge': false},
          {'name': 'Tomatoes', 'quantity': '3 ripe', 'isFromFridge': true},
        ],
        'steps': ['Boil pasta', 'Simmer sauce', 'Combine'],
        'nutrition': {
          'calories': 380,
          'protein': 12.0,
          'carbs': 60.0,
          'fat': 8.0,
          'fiber': 4.0,
        },
      };

      final recipe = Recipe.fromJson(json);
      expect(recipe.id, 'rec_json_1');
      expect(recipe.name, 'Penne Arrabiata');
      expect(recipe.isVegetarian, isTrue);
      expect(recipe.ingredients.length, 2);
      expect(recipe.nutrition.calories, 380);

      final serialized = recipe.toJson();
      expect(serialized['id'], 'rec_json_1');
      expect(serialized['name'], 'Penne Arrabiata');

      final videoJson = {
        'id': 'vid_test_1',
        'title': 'How to Cook Penne Arrabiata',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'channelName': 'Chef Mario',
        'duration': '10:15 min',
        'videoUrl': 'https://youtube.com/watch?v=123',
      };

      final video = CookingVideo.fromJson(videoJson);
      expect(video.id, 'vid_test_1');
      expect(video.title, 'How to Cook Penne Arrabiata');
      expect(video.channelName, 'Chef Mario');

      final videoSerialized = video.toJson();
      expect(videoSerialized['videoUrl'], 'https://youtube.com/watch?v=123');
    });
  });
}
