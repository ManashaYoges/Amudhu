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

  static String _stemWord(String word) {
    String w = word.toLowerCase().trim();
    if (w.endsWith('ies') && w.length > 4) return '${w.substring(0, w.length - 3)}y';
    if (w.endsWith('es') && w.length > 4) return w.substring(0, w.length - 2);
    if (w.endsWith('s') && !w.endsWith('ss') && w.length > 3) return w.substring(0, w.length - 1);
    return w;
  }

  static const Map<String, List<String>> _culinarySynonyms = {
    'tomato': ['tomato', 'tomatoes', 'tamatar'],
    'onion': ['onion', 'onions', 'pyaz', 'shallot', 'shallots', 'scallion', 'scallions', 'spring onion'],
    'potato': ['potato', 'potatoes', 'aloo', 'batata'],
    'spinach': ['spinach', 'palak', 'greens', 'keerai', 'saag'],
    'egg': ['egg', 'eggs', 'anda', 'boiled egg', 'egg white', 'omelette'],
    'paneer': ['paneer', 'cottage cheese', 'chenna'],
    'curd': ['curd', 'yogurt', 'yoghurt', 'dahi'],
    'coriander': ['coriander', 'cilantro', 'dhania', 'kothmir', 'herbs', 'parsley'],
    'chilli': ['chilli', 'chili', 'chilies', 'chillies', 'green chilli', 'red chilli', 'mirch', 'mirchi', 'jalapeno', 'capsicum', 'bell pepper', 'peppers'],
    'garlic': ['garlic', 'garlic cloves', 'lahsun'],
    'ginger': ['ginger', 'ginger root', 'adrak'],
    'bread': ['bread', 'bread slices', 'toast', 'loaf', 'pav', 'bun'],
    'rice': ['rice', 'cooked rice', 'steamed rice', 'basmati', 'chawal'],
    'chicken': ['chicken', 'chicken breast', 'chicken pieces', 'poultry', 'murgh'],
    'cheese': ['cheese', 'cheddar', 'mozzarella', 'parmesan', 'processed cheese'],
    'milk': ['milk', 'dairy milk', 'doodh', 'cream'],
    'lemon': ['lemon', 'lime', 'lemon juice', 'nimbu'],
    'pasta': ['pasta', 'macaroni', 'penne', 'spaghetti', 'fusilli', 'noodles'],
    'butter': ['butter', 'ghee', 'makhan'],
    'lentil': ['lentil', 'lentils', 'dal', 'daal', 'toor dal', 'moong dal', 'chana dal'],
    'flour': ['flour', 'atta', 'wheat flour', 'maida', 'all purpose flour', 'besan'],
    'mushroom': ['mushroom', 'mushrooms', 'button mushroom'],
    'carrot': ['carrot', 'carrots', 'gajar'],
    'peas': ['peas', 'green peas', 'matar'],
    'cucumber': ['cucumber', 'kheera', 'kakdi'],
  };

  static bool _isIngredientMatch(String userIng, String recipeIng) {
    final u = userIng.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ').trim();
    final r = recipeIng.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ').trim();
    if (u.isEmpty || r.isEmpty) return false;
    if (u == r || r.contains(u) || u.contains(r)) return true;

    final uTokens = u.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
    final rTokens = r.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();

    for (final ut in uTokens) {
      final sUt = _stemWord(ut);
      for (final rt in rTokens) {
        final sRt = _stemWord(rt);
        if (sUt == sRt || sRt.contains(sUt) || sUt.contains(sRt)) return true;
      }
    }

    for (final ut in uTokens) {
      final sUt = _stemWord(ut);
      for (final entry in _culinarySynonyms.entries) {
        if (entry.key == sUt || entry.value.any((v) => _stemWord(v) == sUt)) {
          for (final rt in rTokens) {
            final sRt = _stemWord(rt);
            if (entry.value.any((v) => _stemWord(v) == sRt || sRt.contains(_stemWord(v)) || _stemWord(v).contains(sRt))) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  /// Match available ingredients against a curated recipe catalog and rank by ingredient match.
  Future<List<Recipe>> _performMockGeneration(
      List<DetectedIngredient> userIngredients) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final userNames =
        userIngredients.map((i) => i.name.trim()).toList();

    final allCatalog = getCatalogRecipes();

    // Score and mark ingredients for each recipe
    final scoredRecipes = allCatalog.map((template) {
      int matched = 0;
      final updatedIngredients = template.ingredients.map((ing) {
        final isMatch = userNames.any((userIng) => _isIngredientMatch(userIng, ing.name));
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
      const Recipe(
        id: 'homestyle_chicken_curry',
        name: 'Homestyle Spiced Chicken Curry',
        emoji: '🍗',
        description: 'Tender chicken pieces simmered in a fragrant onion, tomato, and garlic curry gravy.',
        prepTime: '10 min',
        cookTime: '20 min',
        totalTime: '30 min',
        servings: 3,
        difficulty: 'Medium',
        cuisine: 'Indian',
        isVegetarian: false,
        videoUrl: 'https://www.youtube.com/results?search_query=Homestyle+Chicken+Curry+recipe',
        ingredients: [
          RecipeIngredient(name: 'Chicken', quantity: '350 g cut into pieces'),
          RecipeIngredient(name: 'Onions', quantity: '2 medium finely sliced'),
          RecipeIngredient(name: 'Tomatoes', quantity: '2 ripe pureed'),
          RecipeIngredient(name: 'Ginger', quantity: '1 tbsp minced'),
          RecipeIngredient(name: 'Garlic', quantity: '1 tbsp minced'),
          RecipeIngredient(name: 'Green Chillies', quantity: '2 slit'),
          RecipeIngredient(name: 'Cooking Oil', quantity: '2 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Garam Masala & Turmeric', quantity: '1 tsp each', isFromFridge: false),
          RecipeIngredient(name: 'Salt', quantity: 'To taste', isFromFridge: false),
        ],
        steps: [
          'Heat oil in a heavy-bottomed pot. Add sliced onions and cook until golden brown.',
          'Stir in minced ginger, garlic, and green chillies. Sauté for 1 minute until fragrant.',
          'Add pureed tomatoes, turmeric, garam masala, and salt. Cook until oil separates from the masala.',
          'Add chicken pieces. Sear on high heat for 3 minutes to lock in moisture.',
          'Add 1/2 cup water, cover tightly, and simmer on low-medium flame for 15 minutes until chicken is tender.',
          'Garnish with fresh coriander and serve steaming hot with rice or roti.',
        ],
        nutrition: RecipeNutrition(
          calories: 340,
          protein: 32.0,
          carbs: 8.5,
          fat: 18.0,
          fiber: 2.2,
        ),
      ),
      const Recipe(
        id: 'crispy_pan_seared_chicken',
        name: 'Lemon Garlic Pan-Seared Chicken',
        emoji: '🥩',
        description: 'Juicy, succulent chicken cutlets seared golden with fresh lemon, garlic, and cracked pepper.',
        prepTime: '5 min',
        cookTime: '12 min',
        totalTime: '17 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Continental',
        isVegetarian: false,
        videoUrl: 'https://www.youtube.com/results?search_query=Pan+Seared+Lemon+Garlic+Chicken+Breast+recipe',
        ingredients: [
          RecipeIngredient(name: 'Chicken', quantity: '2 chicken breasts / cutlets'),
          RecipeIngredient(name: 'Garlic', quantity: '4 cloves minced'),
          RecipeIngredient(name: 'Lemon', quantity: '1 whole juiced'),
          RecipeIngredient(name: 'Olive Oil / Butter', quantity: '1.5 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt & Black Pepper', quantity: '1/2 tsp each', isFromFridge: false),
        ],
        steps: [
          'Pat chicken breasts dry with paper towels. Season both sides generously with salt and black pepper.',
          'Heat olive oil or butter in a skillet over medium-high heat until shimmering.',
          'Place chicken in skillet. Sear undisturbed for 5-6 minutes until a golden crust develops.',
          'Flip chicken, add minced garlic and lemon juice around the pan.',
          'Spoon sizzling garlic lemon pan juices over chicken for 4-5 minutes until internal temp reaches 165°F.',
          'Rest for 3 minutes before slicing. Serve with a fresh side salad or steamed vegetables.',
        ],
        nutrition: RecipeNutrition(
          calories: 280,
          protein: 36.0,
          carbs: 2.5,
          fat: 12.0,
          fiber: 0.5,
        ),
      ),
      const Recipe(
        id: 'creamy_alfredo_pasta',
        name: 'Creamy Garlic Alfredo Pasta',
        emoji: '🍝',
        description: 'Al dente pasta tossed in a velvety, rich garlic and cheese sauce with cracked pepper.',
        prepTime: '5 min',
        cookTime: '15 min',
        totalTime: '20 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Italian',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=Creamy+Garlic+Alfredo+Pasta+recipe',
        ingredients: [
          RecipeIngredient(name: 'Pasta', quantity: '200 g (penne, spaghetti, or macaroni)'),
          RecipeIngredient(name: 'Milk / Cream', quantity: '1 cup'),
          RecipeIngredient(name: 'Garlic', quantity: '4 cloves minced'),
          RecipeIngredient(name: 'Cheese', quantity: '50 g grated'),
          RecipeIngredient(name: 'Butter', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt & Black Pepper', quantity: 'To taste', isFromFridge: false),
        ],
        steps: [
          'Boil pasta in salted water until al dente. Reserve 1/4 cup pasta water, then drain.',
          'Melt butter in a skillet over medium heat. Sauté minced garlic for 1 minute until fragrant.',
          'Pour in milk or cream. Bring to a gentle simmer for 3 minutes.',
          'Lower flame and stir in grated cheese until sauce turns smooth and velvety.',
          'Toss in cooked pasta and reserved pasta water. Coat every strand evenly.',
          'Season with black pepper and serve hot.',
        ],
        nutrition: RecipeNutrition(
          calories: 430,
          protein: 15.0,
          carbs: 54.0,
          fat: 18.0,
          fiber: 3.0,
        ),
      ),
      const Recipe(
        id: 'tomato_basil_garlic_pasta',
        name: 'Fresh Tomato & Garlic Herb Pasta',
        emoji: '🍝',
        description: 'Pasta coated in sweet crushed ripe tomatoes, olive oil, minced garlic, and aromatic herbs.',
        prepTime: '5 min',
        cookTime: '15 min',
        totalTime: '20 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Italian',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=Fresh+Tomato+Garlic+Basil+Pasta+recipe',
        ingredients: [
          RecipeIngredient(name: 'Pasta', quantity: '200 g'),
          RecipeIngredient(name: 'Tomatoes', quantity: '4 ripe diced'),
          RecipeIngredient(name: 'Garlic', quantity: '4 cloves minced'),
          RecipeIngredient(name: 'Onions', quantity: '1 small diced'),
          RecipeIngredient(name: 'Olive Oil', quantity: '1.5 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt & Pepper', quantity: 'To taste', isFromFridge: false),
          RecipeIngredient(name: 'Oregano / Herbs', quantity: '1 tsp', isFromFridge: false),
        ],
        steps: [
          'Boil pasta in a pot of salted water until al dente. Drain and set aside.',
          'Heat olive oil in a skillet. Sauté onions and minced garlic until translucent.',
          'Add diced ripe tomatoes, oregano, salt, and black pepper.',
          'Simmer for 8 minutes, crushing tomatoes with a wooden spoon until a jammy sauce forms.',
          'Toss pasta into the sauce and fold gently for 2 minutes to absorb flavors.',
          'Serve warm topped with a sprinkle of cheese or fresh herbs.',
        ],
        nutrition: RecipeNutrition(
          calories: 360,
          protein: 11.5,
          carbs: 62.0,
          fat: 8.5,
          fiber: 4.8,
        ),
      ),
      const Recipe(
        id: 'garlic_cheese_toast',
        name: 'Crispy Garlic & Cheese Toast',
        emoji: '🍞',
        description: 'Crunchy golden bread slices topped with minced garlic butter and bubbling melted cheese.',
        prepTime: '5 min',
        cookTime: '8 min',
        totalTime: '13 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Continental',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=Crispy+Garlic+Cheese+Toast+recipe+skillet',
        ingredients: [
          RecipeIngredient(name: 'Bread', quantity: '4 slices'),
          RecipeIngredient(name: 'Garlic', quantity: '4 cloves finely minced'),
          RecipeIngredient(name: 'Cheese', quantity: '60 g shredded'),
          RecipeIngredient(name: 'Butter', quantity: '2 tbsp softened', isFromFridge: false),
          RecipeIngredient(name: 'Chili Flakes & Oregano', quantity: '1/2 tsp each', isFromFridge: false),
        ],
        steps: [
          'In a small bowl, mix softened butter, minced garlic, and chili flakes together.',
          'Spread the garlic butter generously over one side of each bread slice.',
          'Top evenly with shredded cheese and a pinch of oregano.',
          'Toast on a lidded tawa or skillet on low flame for 4-5 minutes until cheese melts and bottom is golden crisp.',
          'Cut diagonally and serve hot as an irresistible snack.',
        ],
        nutrition: RecipeNutrition(
          calories: 290,
          protein: 9.5,
          carbs: 28.0,
          fat: 16.0,
          fiber: 2.0,
        ),
      ),
      const Recipe(
        id: 'homestyle_bread_upma',
        name: 'Spicy Homestyle Bread Upma',
        emoji: '🍲',
        description: 'Toasted bread cubes tossed with tempered onions, tomatoes, mustard seeds, and curry leaves.',
        prepTime: '5 min',
        cookTime: '10 min',
        totalTime: '15 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Indian',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=Spicy+South+Indian+Bread+Upma+recipe',
        ingredients: [
          RecipeIngredient(name: 'Bread', quantity: '4 slices cut into cubes'),
          RecipeIngredient(name: 'Onions', quantity: '1 medium chopped'),
          RecipeIngredient(name: 'Tomatoes', quantity: '1 large chopped'),
          RecipeIngredient(name: 'Green Chillies', quantity: '2 slit'),
          RecipeIngredient(name: 'Mustard Seeds', quantity: '1/2 tsp', isFromFridge: false),
          RecipeIngredient(name: 'Cooking Oil', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Turmeric & Salt', quantity: '1/2 tsp each', isFromFridge: false),
        ],
        steps: [
          'Cut bread slices into bite-sized 1-inch squares.',
          'Heat oil in a pan. Splutter mustard seeds and curry leaves.',
          'Add chopped onions and green chillies; sauté until soft and light golden.',
          'Add chopped tomatoes, turmeric, and salt. Cook until tomatoes turn mushy.',
          'Toss in bread cubes and sprinkle 1 tablespoon water. Fold gently until bread absorbs the masala.',
          'Cook for 2 minutes on low flame and serve warm with a squeeze of lemon.',
        ],
        nutrition: RecipeNutrition(
          calories: 220,
          protein: 6.5,
          carbs: 36.0,
          fat: 6.0,
          fiber: 3.2,
        ),
      ),
      const Recipe(
        id: 'masala_french_toast',
        name: 'Savory Masala French Toast',
        emoji: '🍳',
        description: 'Thick bread soaked in spiced whisked eggs with chopped onions, coriander, and pan-fried.',
        prepTime: '5 min',
        cookTime: '8 min',
        totalTime: '13 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Indian',
        isVegetarian: false,
        videoUrl: 'https://www.youtube.com/results?search_query=Indian+Savory+Masala+French+Toast+recipe',
        ingredients: [
          RecipeIngredient(name: 'Bread', quantity: '4 slices'),
          RecipeIngredient(name: 'Eggs', quantity: '3 large'),
          RecipeIngredient(name: 'Onions', quantity: '1/2 medium finely chopped'),
          RecipeIngredient(name: 'Tomatoes', quantity: '1/2 medium finely diced'),
          RecipeIngredient(name: 'Green Chillies', quantity: '1 minced'),
          RecipeIngredient(name: 'Coriander / Herbs', quantity: '2 tbsp chopped'),
          RecipeIngredient(name: 'Butter or Oil', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt & Pepper', quantity: 'To taste', isFromFridge: false),
        ],
        steps: [
          'In a wide dish, whisk eggs with salt, pepper, turmeric, chopped onions, tomatoes, green chilli, and coriander.',
          'Heat butter or oil on a flat tawa or skillet over medium heat.',
          'Dip bread slices into the egg mixture, coating both sides well with aromatics.',
          'Place on hot tawa and cook for 2-3 minutes per side until golden brown and cooked through.',
          'Serve hot with mint chutney or ketchup.',
        ],
        nutrition: RecipeNutrition(
          calories: 310,
          protein: 17.5,
          carbs: 30.0,
          fat: 13.5,
          fiber: 2.8,
        ),
      ),
      const Recipe(
        id: 'chicken_egg_fried_rice',
        name: 'Quick Chicken & Egg Fried Rice',
        emoji: '🍚',
        description: 'Fluffy rice stir-fried on high heat with scrambled eggs, chicken bits, onions, and aromatics.',
        prepTime: '8 min',
        cookTime: '10 min',
        totalTime: '18 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Asian',
        isVegetarian: false,
        videoUrl: 'https://www.youtube.com/results?search_query=Chicken+and+Egg+Fried+Rice+quick+recipe',
        ingredients: [
          RecipeIngredient(name: 'Cooked Rice', quantity: '2 cups chilled'),
          RecipeIngredient(name: 'Chicken', quantity: '150 g cooked or diced'),
          RecipeIngredient(name: 'Eggs', quantity: '2 large beaten'),
          RecipeIngredient(name: 'Onions', quantity: '1 small diced'),
          RecipeIngredient(name: 'Garlic', quantity: '3 cloves minced'),
          RecipeIngredient(name: 'Cooking Oil', quantity: '1.5 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Soy Sauce or Salt', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Black Pepper', quantity: '1/2 tsp', isFromFridge: false),
        ],
        steps: [
          'Heat 1/2 tbsp oil in a wok or large pan. Scramble eggs softly and transfer to a plate.',
          'Add remaining oil to wok on high flame. Sauté garlic and onions for 1 minute.',
          'Add diced chicken and stir-fry for 3-4 minutes until cooked through.',
          'Add cold cooked rice. Break up clumps and toss vigorously on high flame.',
          'Drizzle soy sauce or salt and cracked pepper. Fold in scrambled eggs.',
          'Toss for 1 more minute until fragrant and steaming. Serve hot.',
        ],
        nutrition: RecipeNutrition(
          calories: 420,
          protein: 28.0,
          carbs: 48.0,
          fat: 12.0,
          fiber: 2.0,
        ),
      ),
      const Recipe(
        id: 'paneer_butter_masala_quick',
        name: 'Quick Paneer Butter Masala',
        emoji: '🧀',
        description: 'Soft paneer cubes in a silky, mildly sweet and buttery tomato-onion makhani gravy.',
        prepTime: '8 min',
        cookTime: '15 min',
        totalTime: '23 min',
        servings: 2,
        difficulty: 'Medium',
        cuisine: 'Indian',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=Quick+Paneer+Butter+Masala+recipe',
        ingredients: [
          RecipeIngredient(name: 'Paneer', quantity: '200 g cubed'),
          RecipeIngredient(name: 'Tomatoes', quantity: '3 ripe blended'),
          RecipeIngredient(name: 'Onions', quantity: '1 large finely chopped'),
          RecipeIngredient(name: 'Butter', quantity: '1.5 tbsp'),
          RecipeIngredient(name: 'Ginger & Garlic', quantity: '1 tsp each minced'),
          RecipeIngredient(name: 'Curd / Cream', quantity: '2 tbsp'),
          RecipeIngredient(name: 'Garam Masala & Salt', quantity: '1/2 tsp each', isFromFridge: false),
        ],
        steps: [
          'Melt butter in a pan over medium heat. Sauté onions, ginger, and garlic until soft and fragrant.',
          'Pour in blended tomato puree and cook for 6 minutes until gravy thickens.',
          'Add garam masala, chili powder, and salt. Stir in curd or cream for richness.',
          'Gently slide in paneer cubes. Simmer on low flame for 4 minutes to absorb flavors.',
          'Garnish with a swirl of butter and fresh coriander. Serve with roti, naan, or rice.',
        ],
        nutrition: RecipeNutrition(
          calories: 370,
          protein: 18.0,
          carbs: 12.0,
          fat: 28.0,
          fiber: 2.6,
        ),
      ),
      const Recipe(
        id: 'potato_onion_hash',
        name: 'Crispy Spiced Potato & Onion Hash',
        emoji: '🥔',
        description: 'Golden skillet-crisped potato cubes tossed with sweet caramelized onions and herbs.',
        prepTime: '8 min',
        cookTime: '15 min',
        totalTime: '23 min',
        servings: 2,
        difficulty: 'Easy',
        cuisine: 'Continental',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=Crispy+Potato+Onion+Hash+recipe+skillet',
        ingredients: [
          RecipeIngredient(name: 'Potatoes', quantity: '3 medium diced'),
          RecipeIngredient(name: 'Onions', quantity: '1 large sliced'),
          RecipeIngredient(name: 'Cooking Oil / Butter', quantity: '1.5 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt & Pepper', quantity: 'To taste', isFromFridge: false),
          RecipeIngredient(name: 'Paprika / Chili Flakes', quantity: '1/2 tsp', isFromFridge: false),
        ],
        steps: [
          'Dice potatoes into small 1/2-inch cubes. Rinse in cold water and pat dry.',
          'Heat oil in a heavy non-stick skillet over medium heat.',
          'Add potatoes in a single layer. Cook undisturbed for 5 minutes until underside browns.',
          'Stir and add sliced onions, salt, and pepper.',
          'Cook for another 8-10 minutes, tossing periodically until potatoes are fork-tender and crisp.',
          'Sprinkle chili flakes and serve warm as a satisfying side or breakfast skillet.',
        ],
        nutrition: RecipeNutrition(
          calories: 230,
          protein: 4.2,
          carbs: 36.0,
          fat: 8.5,
          fiber: 3.8,
        ),
      ),
      const Recipe(
        id: 'mixed_vegetable_pulao',
        name: 'Wholesome Mixed Vegetable Pulao',
        emoji: '🍚',
        description: 'Fragrant basmati rice gently cooked with tender carrots, green peas, onions, and whole spices.',
        prepTime: '10 min',
        cookTime: '18 min',
        totalTime: '28 min',
        servings: 3,
        difficulty: 'Easy',
        cuisine: 'Indian',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=One+Pot+Veg+Pulao+recipe',
        ingredients: [
          RecipeIngredient(name: 'Basmati Rice', quantity: '1.5 cups rinsed'),
          RecipeIngredient(name: 'Carrots', quantity: '1 medium diced'),
          RecipeIngredient(name: 'Onions', quantity: '1 medium sliced'),
          RecipeIngredient(name: 'Green Peas / Beans', quantity: '1/2 cup'),
          RecipeIngredient(name: 'Ginger & Garlic', quantity: '1 tsp each minced'),
          RecipeIngredient(name: 'Ghee or Cooking Oil', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Cumin & Whole Spices', quantity: '1 tsp', isFromFridge: false),
          RecipeIngredient(name: 'Salt', quantity: 'To taste', isFromFridge: false),
        ],
        steps: [
          'Heat ghee or oil in a pot. Splutter cumin seeds and whole aromatics.',
          'Add sliced onions, ginger, and garlic; sauté until golden.',
          'Add diced carrots and green peas. Sauté for 2 minutes.',
          'Add rinsed basmati rice and gently toast for 1 minute.',
          'Add 2.5 cups water and salt. Bring to a rolling boil, then reduce flame to lowest, cover, and cook for 12 minutes.',
          'Fluff gently with a fork and serve with cool raita.',
        ],
        nutrition: RecipeNutrition(
          calories: 310,
          protein: 6.5,
          carbs: 58.0,
          fat: 6.0,
          fiber: 4.2,
        ),
      ),
      const Recipe(
        id: 'comforting_lentil_soup',
        name: 'Hearty Lentil & Vegetable Soup',
        emoji: '🥣',
        description: 'Nutritious yellow lentils slow-simmered with diced tomatoes, carrots, garlic, and spinach.',
        prepTime: '8 min',
        cookTime: '20 min',
        totalTime: '28 min',
        servings: 3,
        difficulty: 'Easy',
        cuisine: 'Indian',
        isVegetarian: true,
        videoUrl: 'https://www.youtube.com/results?search_query=Healthy+Dal+Soup+with+spinach+and+vegetables+recipe',
        ingredients: [
          RecipeIngredient(name: 'Lentils / Dal', quantity: '1 cup washed'),
          RecipeIngredient(name: 'Tomatoes', quantity: '2 ripe chopped'),
          RecipeIngredient(name: 'Spinach', quantity: '1 cup roughly chopped'),
          RecipeIngredient(name: 'Carrots', quantity: '1 medium diced'),
          RecipeIngredient(name: 'Garlic', quantity: '4 cloves minced'),
          RecipeIngredient(name: 'Cumin Seeds', quantity: '1 tsp', isFromFridge: false),
          RecipeIngredient(name: 'Olive Oil / Ghee', quantity: '1 tbsp', isFromFridge: false),
          RecipeIngredient(name: 'Turmeric & Salt', quantity: '1/2 tsp each', isFromFridge: false),
        ],
        steps: [
          'Heat oil or ghee in a soup pot. Splutter cumin seeds and sauté minced garlic.',
          'Add washed lentils, diced carrots, chopped tomatoes, turmeric, and 4 cups of water.',
          'Bring to a boil, then cover and simmer on medium flame for 15 minutes until lentils soften.',
          'Mash lightly with a whisk or immersion blender for creamy body.',
          'Stir in fresh chopped spinach and simmer for 2 more minutes until vibrant green.',
          'Season with salt, black pepper, and a squeeze of fresh lemon juice before serving.',
        ],
        nutrition: RecipeNutrition(
          calories: 240,
          protein: 14.0,
          carbs: 38.0,
          fat: 4.5,
          fiber: 9.0,
        ),
      ),
    ];
  }
}
