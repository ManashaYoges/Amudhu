import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/fridge_recipe_models.dart';
import 'api_client.dart';

/// Exception thrown when recipe generation fails.
class RecipeGenerationException implements Exception {
  final String message;
  final dynamic originalError;

  const RecipeGenerationException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Service that matches available fridge ingredients to recipes or invokes AI generation.
class RecipeGenerationService {
  /// Toggle for demo mode versus live AI recipe generation API.
  static bool useMockGeneration = false;

  /// Active backend URL synced with ApiClient
  static String get activeBackendUrl => ApiClient.baseUrl;

  /// Generates a list of recipes based on available ingredients.
  Future<List<Recipe>> generateRecipes(
      List<DetectedIngredient> ingredients) async {
    if (ingredients.isEmpty) {
      throw const RecipeGenerationException(
        "Please provide at least one ingredient to generate recipes.",
      );
    }

    if (useMockGeneration) {
      return _performMockGeneration(ingredients);
    }

    try {
      return await _performBackendGeneration(ingredients);
    } catch (e) {
      // Fallback to local catalog matching if backend is unreachable
      return _performMockGeneration(ingredients);
    }
  }

  /// Live AI Backend Integration Point for recipe generation.
  Future<List<Recipe>> _performBackendGeneration(
      List<DetectedIngredient> ingredients) async {
    try {
      final endpoint = Uri.parse('$activeBackendUrl/api/generate-recipes');
      final payload = jsonEncode({
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
      });

      final response = await http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(utf8.decode(response.bodyBytes));
        final dynamic rawList = body['recipes'] ?? body;

        if (rawList is List) {
          final recipes = rawList
              .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
              .toList();

          if (recipes.isNotEmpty) {
            return recipes;
          }
        }
      }

      // If backend returns empty or non-200, fallback to catalog matching
      return _performMockGeneration(ingredients);
    } on SocketException catch (e) {
      throw RecipeGenerationException(
        "Cannot connect to the backend server at $activeBackendUrl.",
        e,
      );
    } on TimeoutException catch (e) {
      throw RecipeGenerationException(
        "Recipe generation timed out. Please try again.",
        e,
      );
    } catch (e) {
      if (e is RecipeGenerationException) rethrow;
      throw RecipeGenerationException(
        "We couldn't generate recipes right now. Please try again.",
        e,
      );
    }
  }

  /// Match available ingredients against a curated recipe catalog and rank by ingredient match.
  Future<List<Recipe>> _performMockGeneration(
      List<DetectedIngredient> userIngredients) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final normalizedUser =
        userIngredients.map((i) => i.name.trim().toLowerCase()).toList();

    final allCatalog = getCatalogRecipes();

    // Score and mark ingredients for each recipe
    final scoredRecipes = allCatalog.map((template) {
      int matched = 0;
      final updatedIngredients = template.ingredients.map((ing) {
        final ingName = ing.name.toLowerCase();
        final isMatch = normalizedUser.any((userIng) =>
            ingName.contains(userIng) || userIng.contains(ingName));
        if (isMatch) matched++;
        return ing.copyWith(isFromFridge: isMatch);
      }).toList();

      return Recipe(
        id: template.id,
        name: template.name,
        emoji: template.emoji,
        description: template.description,
        prepTime: template.prepTime,
        cookTime: template.cookTime,
        totalTime: template.totalTime,
        servings: template.servings,
        difficulty: template.difficulty,
        cuisine: template.cuisine,
        isVegetarian: template.isVegetarian,
        ingredients: updatedIngredients,
        steps: template.steps,
        nutrition: template.nutrition,
        matchedCount: matched,
        totalIngredientsCount: template.ingredients.length,
        videoUrl: template.videoUrl,
      );
    }).toList();

    // Sort descending by number of matched fridge ingredients
    scoredRecipes.sort((a, b) {
      final cmp = b.matchedCount.compareTo(a.matchedCount);
      if (cmp != 0) return cmp;
      return b.matchPercentage.compareTo(a.matchPercentage);
    });

    final filtered =
        scoredRecipes.where((r) => r.matchedCount > 0).take(5).toList();
    if (filtered.isNotEmpty) return filtered;

    return scoredRecipes.take(3).toList();
  }

  // --- Curated Recipe Catalog ---

  static List<Recipe> getCatalogRecipes() {
    return [
      const Recipe(
        id: 'spinach_omelette',
        name: 'Spinach & Herb Omelette',
        emoji: '🍳',
        description:
            'A quick, fluffy protein-rich omelette packed with tender sautéed spinach and fresh aromatics.',
        prepTime: '5 min',
        cookTime: '8 min',
        totalTime: '13 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Continental',
        isVegetarian: false,
        videoUrl: 'https://www.youtube.com/results?search_query=Spinach+Omelette+recipe',
        ingredients: [
          RecipeIngredient(name: 'Eggs', quantity: '3 large'),
          RecipeIngredient(name: 'Spinach', quantity: '1 cup finely chopped'),
          RecipeIngredient(name: 'Onions', quantity: '1/2 medium diced'),
          RecipeIngredient(name: 'Green Chillies', quantity: '1 minced'),
          RecipeIngredient(name: 'Olive Oil / Butter', quantity: '1 tsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt & Black Pepper', quantity: 'To taste', isFromFridge: false),
        ],
        steps: [
          'Wash spinach thoroughly and chop into fine ribbons. Finely dice the onion.',
          'In a mixing bowl, crack the eggs and whisk vigorously until frothy with salt and pepper.',
          'Heat olive oil in a skillet over medium flame. Sauté onions and green chilli for 2 minutes.',
          'Add chopped spinach and sauté for 1 minute until wilted.',
          'Pour the whisked eggs evenly over the skillet.',
          'Cook on low-medium flame until edges set. Gently fold in half and cook for 1 more minute.',
          'Slide onto a warm plate and serve hot.',
        ],
        nutrition: RecipeNutrition(
          calories: 275,
          protein: 21.0,
          carbs: 4.5,
          fat: 19.0,
          fiber: 2.8,
        ),
      ),
      const Recipe(
        id: 'tomato_egg_bhurji',
        name: 'Spiced Tomato Egg Bhurji',
        emoji: '🥘',
        description:
            'Classic Indian-style scrambled eggs tossed with juicy tomatoes, onions, and warming spices.',
        prepTime: '7 min',
        cookTime: '10 min',
        totalTime: '17 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Indian',
        isVegetarian: false,
        videoUrl: 'https://www.youtube.com/results?search_query=Egg+Bhurji+recipe',
        ingredients: [
          RecipeIngredient(name: 'Eggs', quantity: '4 eggs'),
          RecipeIngredient(name: 'Tomatoes', quantity: '2 ripe chopped'),
          RecipeIngredient(name: 'Onions', quantity: '1 large diced'),
          RecipeIngredient(name: 'Green Chillies', quantity: '2 slit'),
          RecipeIngredient(name: 'Cooking Oil', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Turmeric & Cumin Powder', quantity: '1/2 tsp each', isFromFridge: false),
          RecipeIngredient(name: 'Salt', quantity: 'To taste', isFromFridge: false),
        ],
        steps: [
          'Heat oil in a pan over medium heat. Add cumin seeds and let them splutter.',
          'Add chopped onions and green chilli. Sauté until light golden brown.',
          'Add diced tomatoes, turmeric, and salt. Cook until tomatoes soften.',
          'Crack eggs directly into the pan and stir gently on medium-low flame.',
          'Scramble continuously until the eggs integrate softly with the masala.',
          'Garnish with coriander leaves and serve hot with toast or roti.',
        ],
        nutrition: RecipeNutrition(
          calories: 290,
          protein: 24.5,
          carbs: 7.8,
          fat: 18.2,
          fiber: 2.4,
        ),
      ),
      const Recipe(
        id: 'palak_paneer_quick',
        name: 'Quick Palak Paneer Stir-Fry',
        emoji: '🧀',
        description:
            'Wholesome paneer cubes gently tossed with garlicky sautéed spinach and mild spices.',
        prepTime: '8 min',
        cookTime: '12 min',
        totalTime: '20 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Indian',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=Quick+Palak+Paneer+Stir+Fry',
        ingredients: [
          RecipeIngredient(name: 'Paneer', quantity: '200 g cubed'),
          RecipeIngredient(name: 'Spinach', quantity: '1 large bunch (200g)'),
          RecipeIngredient(name: 'Onions', quantity: '1 medium sliced'),
          RecipeIngredient(name: 'Tomatoes', quantity: '1 small diced'),
          RecipeIngredient(name: 'Garlic', quantity: '4 cloves minced'),
          RecipeIngredient(name: 'Ghee or Cooking Oil', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Garam Masala', quantity: '1/2 tsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt', quantity: 'To taste', isFromFridge: false),
        ],
        steps: [
          'Roughly chop spinach. Soak paneer cubes in warm water for 5 minutes for softness.',
          'Heat ghee in a pan. Sauté minced garlic until fragrant and golden.',
          'Add sliced onions and cook until soft. Add diced tomato and cook for 2 minutes.',
          'Toss in the spinach and cook until wilted and vibrant green.',
          'Add paneer cubes, garam masala, and salt. Gently toss to coat paneer.',
          'Cover and simmer on low for 3 minutes to allow flavors to meld.',
          'Serve warm as a high-protein main or side dish.',
        ],
        nutrition: RecipeNutrition(
          calories: 340,
          protein: 19.8,
          carbs: 8.5,
          fat: 25.0,
          fiber: 4.2,
        ),
      ),
      const Recipe(
        id: 'tomato_egg_toast',
        name: 'Savory Tomato & Egg Toast',
        emoji: '🍞',
        description:
            'Crispy toasted bread topped with savory spiced scrambled egg and roasted tomato slices.',
        prepTime: '5 min',
        cookTime: '7 min',
        totalTime: '12 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Continental',
        isVegetarian: false,
        videoUrl: 'https://www.youtube.com/results?search_query=Tomato+Egg+Toast+breakfast',
        ingredients: [
          RecipeIngredient(name: 'Bread', quantity: '4 slices'),
          RecipeIngredient(name: 'Eggs', quantity: '2 large'),
          RecipeIngredient(name: 'Tomatoes', quantity: '1 large sliced'),
          RecipeIngredient(name: 'Cheese', quantity: '2 slices'),
          RecipeIngredient(name: 'Butter', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt & Pepper', quantity: 'To taste', isFromFridge: false),
        ],
        steps: [
          'Toast the bread slices in a toaster or lightly butter and toast on a skillet.',
          'In a small pan, melt butter. Sauté sliced tomatoes for 1 minute on each side.',
          'Whisk eggs with a pinch of salt. Scramble softly in the pan.',
          'Layer scrambled eggs and warm tomato slices over the crispy toast.',
          'Top with cheese slice, cover for 30 seconds to melt, and enjoy warm.',
        ],
        nutrition: RecipeNutrition(
          calories: 320,
          protein: 16.5,
          carbs: 32.0,
          fat: 14.0,
          fiber: 2.2,
        ),
      ),
      const Recipe(
        id: 'warm_spinach_egg_bowl',
        name: 'Warm Spinach & Boiled Egg Bowl',
        emoji: '🥗',
        description:
            'A nutrient-dense warm bowl featuring steamed spinach, soft-boiled eggs, and charred tomatoes.',
        prepTime: '6 min',
        cookTime: '8 min',
        totalTime: '14 min',
        servings: 1,
        difficulty: 'Easy',
        cuisine: 'Continental',
        isVegetarian: false,
        videoUrl: 'https://www.youtube.com/results?search_query=Spinach+Boiled+Egg+Salad',
        ingredients: [
          RecipeIngredient(name: 'Eggs', quantity: '2 eggs'),
          RecipeIngredient(name: 'Spinach', quantity: '2 cups fresh'),
          RecipeIngredient(name: 'Tomatoes', quantity: '1 ripe wedged'),
          RecipeIngredient(name: 'Onions', quantity: '1/4 thinly sliced'),
          RecipeIngredient(name: 'Lemon Juice', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Olive Oil', quantity: '1 tsp', isFromFridge: false),
        ],
        steps: [
          'Boil eggs for 7 minutes for jammy yolks. Cool in cold water and peel.',
          'Quickly flash-steam or sauté spinach in a pan with a splash of water for 90 seconds.',
          'Arrange warm wilted spinach at the base of your serving bowl.',
          'Halve the boiled eggs and arrange over spinach with tomato wedges and sliced onion.',
          'Drizzle with olive oil, fresh lemon juice, salt, and black pepper.',
        ],
        nutrition: RecipeNutrition(
          calories: 220,
          protein: 16.0,
          carbs: 6.2,
          fat: 14.5,
          fiber: 3.6,
        ),
      ),
      const Recipe(
        id: 'garlic_spinach_paneer_bhurji',
        name: 'Garlic Paneer & Greens Scramble',
        emoji: '🧄',
        description:
            'Crumbled paneer and shredded greens sautéed with aromatic garlic, onions, and turmeric.',
        prepTime: '6 min',
        cookTime: '9 min',
        totalTime: '15 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Indian',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=Garlic+Paneer+Bhurji',
        ingredients: [
          RecipeIngredient(name: 'Paneer', quantity: '180 g crumbled'),
          RecipeIngredient(name: 'Spinach', quantity: '1 cup finely shredded'),
          RecipeIngredient(name: 'Onions', quantity: '1 medium chopped'),
          RecipeIngredient(name: 'Garlic', quantity: '5 cloves finely chopped'),
          RecipeIngredient(name: 'Tomatoes', quantity: '1 medium chopped'),
          RecipeIngredient(name: 'Cooking Oil / Butter', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Turmeric & Salt', quantity: '1/2 tsp each', isFromFridge: false),
        ],
        steps: [
          'Crumble fresh paneer into pea-sized bits.',
          'Heat butter in a skillet. Add chopped garlic and sauté on low heat until golden.',
          'Add chopped onions and fry for 3 minutes until soft.',
          'Add tomato and spinach; cook for 2 minutes until juices release.',
          'Fold in crumbled paneer with salt and turmeric. Cook on medium heat for 2 minutes.',
          'Remove from heat immediately to keep paneer tender. Serve warm.',
        ],
        nutrition: RecipeNutrition(
          calories: 310,
          protein: 18.2,
          carbs: 7.0,
          fat: 23.5,
          fiber: 3.1,
        ),
      ),
      const Recipe(
        id: 'curd_rice_tadka',
        name: 'Comforting Curd Rice with Tadka',
        emoji: '🍚',
        description:
            'Creamy South Indian curd rice tempered with mustard seeds, green chillies, and ginger.',
        prepTime: '5 min',
        cookTime: '5 min',
        totalTime: '10 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'South Indian',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=South+Indian+Curd+Rice+recipe',
        ingredients: [
          RecipeIngredient(name: 'Curd / Yogurt', quantity: '1.5 cups fresh'),
          RecipeIngredient(name: 'Cooked Rice', quantity: '2 cups soft cooked'),
          RecipeIngredient(name: 'Green Chillies', quantity: '2 slit'),
          RecipeIngredient(name: 'Ginger', quantity: '1 tsp minced'),
          RecipeIngredient(name: 'Cooking Oil', quantity: '1 tsp', isFromFridge: false),
          RecipeIngredient(name: 'Mustard Seeds', quantity: '1/2 tsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt', quantity: 'To taste', isFromFridge: false),
        ],
        steps: [
          'Gently mash warm cooked rice in a mixing bowl with a spoon.',
          'Add curd and 1/4 cup water or milk with salt. Mix until creamy.',
          'Heat oil in a small tadka pan. Add mustard seeds and let them splutter.',
          'Add green chillies and minced ginger; sauté for 30 seconds.',
          'Pour hot tadka over the curd rice and fold gently. Serve cool.',
        ],
        nutrition: RecipeNutrition(
          calories: 260,
          protein: 7.5,
          carbs: 42.0,
          fat: 7.0,
          fiber: 1.2,
        ),
      ),
    ];
  }
}
