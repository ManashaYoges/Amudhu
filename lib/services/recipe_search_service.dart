import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/fridge_recipe_models.dart';

/// Exception thrown when recipe or video search fails.
class RecipeSearchException implements Exception {
  final String message;
  final dynamic originalError;

  const RecipeSearchException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Service that searches for written recipes across cuisines and cooking videos.
class RecipeSearchService {
  /// Toggle to switch between mock/demonstration provider and live recipe API backend.
  static const bool useMockApi = true;

  /// External or backend Recipe Search API endpoint.
  /// Configure this with your team's endpoint (e.g., Spoonacular, TheMealDB proxy, or custom backend).
  /// Note: Do NOT expose private API keys in client code; keep them secured on your backend server.
  static const String backendApiUrl = 'https://api.amudhu.example.com/v1/recipes/search';

  /// In-memory session cache to avoid redundant network queries for the same query.
  static final Map<String, RecipeSearchResult> _cache = {};

  /// Searches recipes and related videos for an ingredient or dish name.
  Future<RecipeSearchResult> search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      throw const RecipeSearchException("Please enter a recipe name or ingredient to search.");
    }

    // Check cache
    if (_cache.containsKey(cleanQuery)) {
      return _cache[cleanQuery]!;
    }

    RecipeSearchResult result;
    if (useMockApi) {
      result = await _performMockSearch(cleanQuery);
    } else {
      result = await _performBackendSearch(cleanQuery);
    }

    _cache[cleanQuery] = result;
    return result;
  }

  /// Intelligent multi-cuisine mock provider with comprehensive culinary knowledge.
  Future<RecipeSearchResult> _performMockSearch(String query) async {
    // Simulate API network latency (1.0s)
    await Future.delayed(const Duration(milliseconds: 1000));

    final allCatalog = _getFullCatalog();

    // 1. Filter recipes matching the query by name, ingredient, or cuisine
    final matched = allCatalog.where((r) {
      final nameMatches = r.name.toLowerCase().contains(query);
      final cuisineMatches = r.cuisine.toLowerCase().contains(query);
      final ingredientMatches = r.ingredients.any(
        (i) => i.name.toLowerCase().contains(query),
      );
      final descMatches = r.description.toLowerCase().contains(query);
      return nameMatches || cuisineMatches || ingredientMatches || descMatches;
    }).toList();

    List<Recipe> finalRecipes = [];
    if (matched.isNotEmpty) {
      finalRecipes = matched;
    } else {
      // If query is an obscure non-food string or gibberish like "xyzabc" or numbers, return empty
      final isGibberish = RegExp(r'[0-9]').hasMatch(query) ||
          query.startsWith('xyz') ||
          query.startsWith('qwe') ||
          query.startsWith('asdf') ||
          query.length > 15 ||
          !RegExp(r'[aeiouy]').hasMatch(query);

      if (isGibberish) {
        return RecipeSearchResult(
          query: query,
          recipes: [],
          videos: [],
          availableCuisines: ['All'],
          relatedRecommendations: [],
        );
      }

      // Dynamic fallback generator: if user types an arbitrary edible query like "tofu" or "salmon"
      finalRecipes = _generateDynamicRecipesForQuery(query);
    }

    // 2. Extract available cuisines
    final cuisinesSet = <String>{'All'};
    for (final r in finalRecipes) {
      cuisinesSet.add(r.cuisine);
    }

    // 3. Generate related cooking videos
    final videos = _generateCookingVideosForQuery(query, finalRecipes);

    // 4. Generate related recommendations
    final recommendations = _generateRecommendations(query);

    return RecipeSearchResult(
      query: query,
      recipes: finalRecipes,
      videos: videos,
      availableCuisines: cuisinesSet.toList(),
      relatedRecommendations: recommendations,
    );
  }

  /// Live API Integration Point.
  Future<RecipeSearchResult> _performBackendSearch(String query) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final uri = Uri.parse('$backendApiUrl?q=${Uri.encodeComponent(query)}');
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(body);

        final recipesList = (json['recipes'] as List<dynamic>?)
                ?.map((e) => Recipe.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        final videosList = (json['videos'] as List<dynamic>?)
                ?.map((e) => CookingVideo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        final cuisinesList = (json['cuisines'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            ['All'];

        final recsList = (json['recommendations'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        return RecipeSearchResult(
          query: query,
          recipes: recipesList,
          videos: videosList,
          availableCuisines: cuisinesList,
          relatedRecommendations: recsList,
        );
      } else {
        throw const RecipeSearchException("We couldn't load recipes right now. Please try again.");
      }
    } on SocketException catch (e) {
      throw RecipeSearchException("Please check your internet connection and try again.", e);
    } on TimeoutException catch (e) {
      throw RecipeSearchException("Search timed out. Please check your connection and try again.", e);
    } catch (e) {
      if (e is RecipeSearchException) rethrow;
      throw RecipeSearchException("We couldn't load recipes right now. Please try again.", e);
    } finally {
      client.close();
    }
  }

  // --- Dynamic Video Generator ---

  static List<CookingVideo> _generateCookingVideosForQuery(String query, List<Recipe> recipes) {
    final capQuery = query[0].toUpperCase() + query.substring(1);
    const baseYouTubeSearch = 'https://www.youtube.com/results?search_query=';

    final videos = <CookingVideo>[
      CookingVideo(
        id: 'vid_1_${query.hashCode}',
        title: 'Easy $capQuery Recipe for Beginners (Step-by-Step)',
        thumbnailUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
        channelName: 'Chef Special Recipes',
        duration: '7:45 min',
        videoUrl: '$baseYouTubeSearch${Uri.encodeComponent('Easy $capQuery Recipe')}',
      ),
      CookingVideo(
        id: 'vid_2_${query.hashCode}',
        title: '10 Quick $capQuery Snacks You Can Make in 10 Minutes',
        thumbnailUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&q=80',
        channelName: 'Tasty Home Cooking',
        duration: '11:20 min',
        videoUrl: '$baseYouTubeSearch${Uri.encodeComponent('Quick $capQuery Snacks 10 minutes')}',
      ),
      CookingVideo(
        id: 'vid_3_${query.hashCode}',
        title: 'Restaurant Style $capQuery Masterclass',
        thumbnailUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500&q=80',
        channelName: 'Master Flavor Kitchen',
        duration: '14:15 min',
        videoUrl: '$baseYouTubeSearch${Uri.encodeComponent('Restaurant style $capQuery')}',
      ),
      CookingVideo(
        id: 'vid_4_${query.hashCode}',
        title: 'Authentic Traditional $capQuery (Secrets Revealed)',
        thumbnailUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=500&q=80',
        channelName: 'Grandma’s Kitchen',
        duration: '9:30 min',
        videoUrl: '$baseYouTubeSearch${Uri.encodeComponent('Authentic $capQuery traditional')}',
      ),
    ];

    // If we matched specific recipes like Biryani, customize video titles
    if (query.contains('biryani')) {
      return const [
        CookingVideo(
          id: 'vid_biryani_1',
          title: 'Authentic Hyderabadi Chicken Dum Biryani Recipe',
          thumbnailUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80',
          channelName: 'Royal Dawat',
          duration: '18:10 min',
          videoUrl: '${baseYouTubeSearch}Hyderabadi+Chicken+Dum+Biryani',
        ),
        CookingVideo(
          id: 'vid_biryani_2',
          title: 'Quick Pressure Cooker Biryani for Beginners',
          thumbnailUrl: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=500&q=80',
          channelName: 'Simple Kitchen',
          duration: '10:45 min',
          videoUrl: '${baseYouTubeSearch}Pressure+Cooker+Biryani+Recipe',
        ),
        CookingVideo(
          id: 'vid_biryani_3',
          title: 'Vegetable Dum Biryani with Fragrant Masala',
          thumbnailUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&q=80',
          channelName: 'Veggie Delights',
          duration: '12:30 min',
          videoUrl: '${baseYouTubeSearch}Vegetable+Dum+Biryani+Recipe',
        ),
      ];
    }

    return videos;
  }

  // --- Dynamic Recommendations ---

  static List<String> _generateRecommendations(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('bread')) {
      return ['Garlic Bread', 'Bread Upma', 'French Toast', 'Grilled Cheese', 'Bread Pizza'];
    } else if (lower.contains('pasta')) {
      return ['Creamy Alfredo', 'Tomato Basil Pasta', 'Garlic Aglio e Olio', 'Mac & Cheese'];
    } else if (lower.contains('chicken')) {
      return ['Chicken Biryani', 'Butter Chicken', 'Crispy Chicken Tacos', 'Chicken Fried Rice'];
    } else if (lower.contains('paneer')) {
      return ['Palak Paneer', 'Paneer Tikka', 'Paneer Butter Masala', 'Paneer Bhurji'];
    } else if (lower.contains('rice')) {
      return ['Vegetable Biryani', 'Chinese Fried Rice', 'Italian Risotto', 'Jeera Rice'];
    } else if (lower.contains('potato')) {
      return ['Crispy French Fries', 'Aloo Gobi', 'Mashed Potatoes', 'Potato Wedges'];
    }
    return ['$query Stir-fry', 'Crispy $query', '$query Bowl', 'Spicy $query'];
  }

  // --- Dynamic Novel Recipe Generator ---

  static List<Recipe> _generateDynamicRecipesForQuery(String query) {
    final cap = query[0].toUpperCase() + query.substring(1);
    return [
      Recipe(
        id: 'dyn_${query}_indian',
        name: 'Spiced $cap Masala Curry',
        emoji: '🍛',
        cuisine: 'Indian',
        description: 'Tender $query cooked in an aromatic, flavorful onion-tomato gravy with warm spices.',
        prepTime: '10 min',
        cookTime: '20 min',
        totalTime: '30 min',
        servings: 3,
        difficulty: 'Medium',
        isVegetarian: !query.contains('chicken') && !query.contains('meat') && !query.contains('fish'),
        ingredients: [
          RecipeIngredient(name: cap, quantity: '250 g'),
          const RecipeIngredient(name: 'Onions', quantity: '2 medium, chopped'),
          const RecipeIngredient(name: 'Tomatoes', quantity: '2 pureed'),
          const RecipeIngredient(name: 'Ginger Garlic Paste', quantity: '1 tbsp'),
          const RecipeIngredient(name: 'Garam Masala & Turmeric', quantity: '1 tsp each'),
        ],
        steps: [
          'Prepare and clean $query thoroughly into bite-sized pieces.',
          'Heat oil in a pan, sauté onions until golden brown.',
          'Add ginger garlic paste and tomato puree; cook until oil separates.',
          'Add spices, salt, and $query. Simmer on low heat for 12-15 minutes until tender.',
          'Garnish with fresh cilantro and serve hot with steamed rice or flatbread.',
        ],
        nutrition: const RecipeNutrition(calories: 320, protein: 18, carbs: 14, fat: 12, fiber: 4),
      ),
      Recipe(
        id: 'dyn_${query}_asian',
        name: 'Wok-Tossed $cap Fried Rice',
        emoji: '🥢',
        cuisine: 'Chinese',
        description: 'High-heat wok-seared rice tossed with crisp vegetables, savory soy sauce, and $query.',
        prepTime: '8 min',
        cookTime: '12 min',
        totalTime: '20 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: !query.contains('chicken') && !query.contains('meat') && !query.contains('fish'),
        ingredients: [
          RecipeIngredient(name: cap, quantity: '150 g'),
          const RecipeIngredient(name: 'Steamed Jasmine Rice', quantity: '2 cups cold'),
          const RecipeIngredient(name: 'Mixed Vegetables (Carrot, Peas)', quantity: '1/2 cup'),
          const RecipeIngredient(name: 'Soy Sauce & Sesame Oil', quantity: '1.5 tbsp'),
          const RecipeIngredient(name: 'Spring Onions', quantity: '2 stalks chopped'),
        ],
        steps: [
          'Heat a wok with sesame oil over high flame until smoking hot.',
          'Add $query and stir-fry vigorously for 3 minutes.',
          'Toss in vegetables and cold cooked rice, breaking up any clumps.',
          'Drizzle soy sauce around the edges of the wok for wok-hei aroma.',
          'Garnish with sliced spring onions and serve immediately.',
        ],
        nutrition: const RecipeNutrition(calories: 380, protein: 14, carbs: 54, fat: 9, fiber: 3),
      ),
      Recipe(
        id: 'dyn_${query}_italian',
        name: 'Creamy Garlic & Herb $cap',
        emoji: '🍝',
        cuisine: 'Italian',
        description: 'Tender $query tossed with garlic, olive oil, and herbs in a delicate reduction.',
        prepTime: '10 min',
        cookTime: '15 min',
        totalTime: '25 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: !query.contains('chicken') && !query.contains('meat') && !query.contains('fish'),
        ingredients: [
          RecipeIngredient(name: cap, quantity: '200 g'),
          const RecipeIngredient(name: 'Extra Virgin Olive Oil', quantity: '2 tbsp'),
          const RecipeIngredient(name: 'Garlic', quantity: '4 cloves, sliced'),
          const RecipeIngredient(name: 'Fresh Parsley & Basil', quantity: '2 tbsp chopped'),
          const RecipeIngredient(name: 'Parmesan Cheese', quantity: '2 tbsp grated'),
        ],
        steps: [
          'Gently heat olive oil and sliced garlic in a skillet until fragrant.',
          'Add $query and sauté over medium heat until cooked through.',
          'Season with sea salt, black pepper, and chili flakes.',
          'Fold in fresh herbs and sprinkle with grated cheese.',
          'Serve with crusty toasted bread.',
        ],
        nutrition: const RecipeNutrition(calories: 290, protein: 16, carbs: 8, fat: 18, fiber: 2),
      ),
    ];
  }

  // --- Comprehensive Multi-Cuisine Catalog ---

  static List<Recipe> _getFullCatalog() {
    return [
      // 1. Bread (Multi-Cuisine)
      const Recipe(
        id: 'cat_bread_garlic',
        name: 'Crispy Garlic Bread',
        emoji: '🍞',
        cuisine: 'Italian',
        description: 'Crispy baguette slices slathered with rich roasted garlic butter, fresh parsley, and melted cheese.',
        prepTime: '8 min',
        cookTime: '10 min',
        totalTime: '18 min',
        servings: 4,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'French Baguette or Bread', quantity: '1 loaf or 6 thick slices'),
          RecipeIngredient(name: 'Unsalted Butter (softened)', quantity: '4 tbsp'),
          RecipeIngredient(name: 'Garlic', quantity: '4 cloves, finely minced'),
          RecipeIngredient(name: 'Fresh Parsley', quantity: '2 tbsp, chopped'),
          RecipeIngredient(name: 'Mozzarella Cheese', quantity: '1/2 cup grated'),
        ],
        steps: [
          'Preheat oven to 200°C (390°F). Slice bread diagonally.',
          'In a small bowl, blend softened butter, minced garlic, parsley, and a pinch of salt.',
          'Generously spread garlic butter on each bread slice.',
          'Top with shredded mozzarella cheese.',
          'Bake for 8-10 minutes until edges are golden and cheese is bubbly.',
        ],
        nutrition: RecipeNutrition(calories: 210, protein: 6.5, carbs: 24, fat: 10, fiber: 1.5),
      ),
      const Recipe(
        id: 'cat_bread_upma',
        name: 'South Indian Spiced Bread Upma',
        emoji: '🥪',
        cuisine: 'Indian',
        description: 'A comforting breakfast dish made by tossing torn bread cubes in tempered mustard seeds, onions, tomatoes, and curry leaves.',
        prepTime: '5 min',
        cookTime: '10 min',
        totalTime: '15 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'White or Whole Wheat Bread', quantity: '5 slices, cubed'),
          RecipeIngredient(name: 'Onion', quantity: '1 medium, diced'),
          RecipeIngredient(name: 'Tomato', quantity: '1 ripe, chopped'),
          RecipeIngredient(name: 'Mustard Seeds & Curry Leaves', quantity: '1 tsp & 8 leaves'),
          RecipeIngredient(name: 'Turmeric & Chili Powder', quantity: '1/2 tsp each'),
        ],
        steps: [
          'Heat 1 tbsp oil in a pan. Add mustard seeds and curry leaves; allow them to crackle.',
          'Add diced onions and green chilies. Sauté until translucent.',
          'Add chopped tomatoes, turmeric, chili powder, and salt. Cook until tomatoes are mushy.',
          'Gently toss in bread cubes until evenly coated with the masala.',
          'Sprinkle fresh coriander and a squeeze of lime juice. Serve hot.',
        ],
        nutrition: RecipeNutrition(calories: 220, protein: 5.5, carbs: 36, fat: 6, fiber: 3.2),
      ),
      const Recipe(
        id: 'cat_bread_french_toast',
        name: 'Classic Golden French Toast',
        emoji: '🥞',
        cuisine: 'French',
        description: 'Fluffy brioche soaked in a rich vanilla-cinnamon egg custard and pan-toasted to golden perfection.',
        prepTime: '5 min',
        cookTime: '8 min',
        totalTime: '13 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Thick Bread Slices', quantity: '4 slices'),
          RecipeIngredient(name: 'Eggs', quantity: '2 large'),
          RecipeIngredient(name: 'Milk', quantity: '1/4 cup'),
          RecipeIngredient(name: 'Cinnamon & Vanilla Extract', quantity: '1/2 tsp each'),
          RecipeIngredient(name: 'Maple Syrup or Honey', quantity: 'For serving'),
        ],
        steps: [
          'Whisk eggs, milk, cinnamon, vanilla, and a pinch of salt in a wide shallow dish.',
          'Melt 1 tbsp butter in a skillet over medium heat.',
          'Dip each bread slice in the custard mixture for 10 seconds per side.',
          'Cook in the skillet for 3-4 minutes per side until golden brown.',
          'Serve with warm maple syrup and sliced berries.',
        ],
        nutrition: RecipeNutrition(calories: 280, protein: 11, carbs: 34, fat: 11, fiber: 1.8),
      ),
      const Recipe(
        id: 'cat_bread_grilled_cheese',
        name: 'All-American Crisp Grilled Cheese',
        emoji: '🧀',
        cuisine: 'American',
        description: 'Golden buttery toasted sandwich oozing with melted cheddar and mozzarella cheese.',
        prepTime: '3 min',
        cookTime: '6 min',
        totalTime: '9 min',
        servings: 1,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Sourdough or White Bread', quantity: '2 slices'),
          RecipeIngredient(name: 'Cheddar & Mozzarella Cheese', quantity: '2 thick slices each'),
          RecipeIngredient(name: 'Butter (salted)', quantity: '1.5 tbsp'),
        ],
        steps: [
          'Butter one side of each bread slice generously.',
          'Place one slice butter-side down in a medium skillet over medium-low heat.',
          'Layer cheeses on top, then place the second bread slice on top, butter-side facing up.',
          'Cook for 3-4 minutes until the bottom is deeply golden.',
          'Flip carefully and cook the other side until cheese is completely melted.',
        ],
        nutrition: RecipeNutrition(calories: 360, protein: 15, carbs: 28, fat: 22, fiber: 1.5),
      ),

      // 2. Pasta (Multi-Cuisine)
      const Recipe(
        id: 'cat_pasta_alfredo',
        name: 'Creamy Garlic Alfredo Pasta',
        emoji: '🍝',
        cuisine: 'Italian',
        description: 'Silky fettuccine coated in rich garlic parmesan cream sauce made from scratch.',
        prepTime: '5 min',
        cookTime: '12 min',
        totalTime: '17 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Fettuccine or Penne Pasta', quantity: '200 g'),
          RecipeIngredient(name: 'Heavy Cream / Milk', quantity: '3/4 cup'),
          RecipeIngredient(name: 'Parmesan Cheese (grated)', quantity: '1/2 cup'),
          RecipeIngredient(name: 'Butter & Garlic', quantity: '2 tbsp butter, 3 cloves garlic'),
          RecipeIngredient(name: 'Black Pepper & Nutmeg', quantity: 'Pinch of each'),
        ],
        steps: [
          'Boil pasta in salted water until al dente; reserve 1/2 cup pasta cooking water.',
          'Melt butter in a pan over medium heat. Sauté minced garlic for 1 minute.',
          'Pour in cream and simmer gently for 2 minutes.',
          'Remove from heat, whisk in parmesan cheese until smooth and creamy.',
          'Toss pasta into the sauce, adding pasta water if needed to loosen.',
        ],
        nutrition: RecipeNutrition(calories: 460, protein: 14, carbs: 52, fat: 22, fiber: 2.5),
      ),
      const Recipe(
        id: 'cat_pasta_arrabbiata',
        name: 'Spicy Penne all’Arrabbiata',
        emoji: '🍅',
        cuisine: 'Italian',
        description: 'Classic Roman penne in a fiery tomato sauce infused with garlic, olive oil, and dried red chili flakes.',
        prepTime: '5 min',
        cookTime: '15 min',
        totalTime: '20 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Penne Pasta', quantity: '200 g'),
          RecipeIngredient(name: 'Crushed Tomatoes', quantity: '1 can (400 g)'),
          RecipeIngredient(name: 'Garlic', quantity: '4 cloves, sliced'),
          RecipeIngredient(name: 'Red Chili Flakes', quantity: '1 tsp'),
          RecipeIngredient(name: 'Extra Virgin Olive Oil', quantity: '2 tbsp'),
        ],
        steps: [
          'Boil penne pasta until al dente.',
          'In a large pan, heat olive oil over medium-low flame. Gently fry sliced garlic and chili flakes.',
          'Add crushed tomatoes and salt. Simmer for 12 minutes until thick and rich.',
          'Stir in cooked penne pasta and fresh basil leaves.',
          'Serve with a sprinkle of grated cheese or extra chili flakes.',
        ],
        nutrition: RecipeNutrition(calories: 340, protein: 10, carbs: 58, fat: 8, fiber: 4.5),
      ),
      const Recipe(
        id: 'cat_pasta_masala',
        name: 'Desi Indian Masala Pasta',
        emoji: '🍲',
        cuisine: 'Indian',
        description: 'Macaroni tossed in an Indian spiced sauce with bell peppers, onions, tomatoes, and chatpata seasoning.',
        prepTime: '7 min',
        cookTime: '13 min',
        totalTime: '20 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Macaroni / Elbow Pasta', quantity: '180 g'),
          RecipeIngredient(name: 'Onion & Capsicum', quantity: '1 each, diced'),
          RecipeIngredient(name: 'Tomatoes', quantity: '2 pureed'),
          RecipeIngredient(name: 'Garam Masala & Pav Bhaji Masala', quantity: '1 tsp each'),
          RecipeIngredient(name: 'Coriander Leaves', quantity: '2 tbsp'),
        ],
        steps: [
          'Boil pasta in salted water until tender; drain and rinse with cold water.',
          'Heat oil in a wok. Sauté cumin seeds, onions, and capsicum until tender-crisp.',
          'Add tomato puree, turmeric, chili powder, and pav bhaji masala. Cook until aromatic.',
          'Toss boiled pasta in the masala sauce with 2 tbsp water.',
          'Garnish with fresh coriander and serve piping hot.',
        ],
        nutrition: RecipeNutrition(calories: 325, protein: 9.5, carbs: 54, fat: 7.5, fiber: 3.8),
      ),

      // 3. Rice & Biryani (Multi-Cuisine)
      const Recipe(
        id: 'cat_rice_biryani_chicken',
        name: 'Hyderabadi Chicken Dum Biryani',
        emoji: '🍗',
        cuisine: 'Indian',
        description: 'Fragrant aged basmati rice layered with succulent marinated chicken, saffron milk, fried onions, and whole spices.',
        prepTime: '20 min',
        cookTime: '35 min',
        totalTime: '55 min',
        servings: 4,
        difficulty: 'Medium',
        isVegetarian: false,
        ingredients: [
          RecipeIngredient(name: 'Basmati Rice', quantity: '2 cups aged long-grain'),
          RecipeIngredient(name: 'Chicken', quantity: '500 g, curry cut'),
          RecipeIngredient(name: 'Yogurt / Curd', quantity: '1/2 cup'),
          RecipeIngredient(name: 'Fried Onions (Birista)', quantity: '1 cup'),
          RecipeIngredient(name: 'Biryani Spices & Saffron Milk', quantity: 'Cardamom, cinnamon, cloves, 2 tbsp milk with saffron'),
        ],
        steps: [
          'Marinate chicken in yogurt, ginger-garlic paste, chili powder, garam masala, and fried onions for 30 minutes.',
          'Par-boil basmati rice with whole spices until 70% cooked; drain.',
          'In a heavy-bottomed pot, spread marinated chicken at the base.',
          'Layer parboiled rice on top. Sprinkle fried onions, mint leaves, saffron milk, and ghee.',
          'Seal with a tight lid. Cook on high for 5 minutes, then dum on low heat for 25 minutes.',
          'Rest for 10 minutes before gently fluffing and serving with raita.',
        ],
        nutrition: RecipeNutrition(calories: 520, protein: 32, carbs: 64, fat: 14, fiber: 3.0),
      ),
      const Recipe(
        id: 'cat_rice_veg_fried_rice',
        name: 'Vegetable Fried Rice',
        emoji: '🥢',
        cuisine: 'Chinese',
        description: 'Wok-tossed long grain rice with colorful crisp carrots, beans, spring onions, and toasted sesame oil.',
        prepTime: '10 min',
        cookTime: '10 min',
        totalTime: '20 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Cooked Rice (chilled)', quantity: '3 cups'),
          RecipeIngredient(name: 'Carrots & Green Beans', quantity: '1/2 cup finely diced'),
          RecipeIngredient(name: 'Garlic & Ginger', quantity: '1 tbsp minced'),
          RecipeIngredient(name: 'Soy Sauce & White Pepper', quantity: '2 tbsp & 1/2 tsp'),
          RecipeIngredient(name: 'Spring Onions', quantity: '1/4 cup'),
        ],
        steps: [
          'Heat sesame oil in a wok over high flame.',
          'Add minced garlic and ginger, stir-frying for 30 seconds.',
          'Add diced vegetables; toss for 2 minutes to retain crunch.',
          'Add cold cooked rice and drizzle soy sauce.',
          'Toss continuously on high flame for 3 minutes until grains are separated and heated through.',
          'Finish with sliced spring onions.',
        ],
        nutrition: RecipeNutrition(calories: 310, protein: 6.5, carbs: 58, fat: 6.5, fiber: 3.5),
      ),
      const Recipe(
        id: 'cat_rice_mexican_bowl',
        name: 'Mexican Fiesta Rice Bowl',
        emoji: '🥑',
        cuisine: 'Mexican',
        description: 'Zesty tomato-cilantro rice topped with black beans, sweet corn, salsa, and creamy avocado.',
        prepTime: '10 min',
        cookTime: '15 min',
        totalTime: '25 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Long Grain Rice', quantity: '1.5 cups'),
          RecipeIngredient(name: 'Black Beans / Kidney Beans', quantity: '1 cup cooked'),
          RecipeIngredient(name: 'Corn & Diced Tomatoes', quantity: '1/2 cup each'),
          RecipeIngredient(name: 'Avocado & Lime', quantity: '1 avocado sliced, 1 lime'),
          RecipeIngredient(name: 'Cumin & Paprika', quantity: '1 tsp each'),
        ],
        steps: [
          'Cook rice with tomato paste, cumin, paprika, and broth until tender and fluffy.',
          'Warm black beans and corn with salt and lime juice.',
          'Assemble bowls with a base of flavorful red rice.',
          'Top with beans, corn, diced fresh tomatoes, and sliced avocado.',
          'Garnish with cilantro leaves and a squeeze of lime.',
        ],
        nutrition: RecipeNutrition(calories: 390, protein: 11, carbs: 68, fat: 9, fiber: 8.5),
      ),
      const Recipe(
        id: 'cat_rice_risotto',
        name: 'Creamy Parmesan Mushroom Risotto',
        emoji: '🍄',
        cuisine: 'Italian',
        description: 'Arborio rice slowly simmered in warm broth to create a naturally rich, velvety Italian risotto.',
        prepTime: '10 min',
        cookTime: '25 min',
        totalTime: '35 min',
        servings: 3,
        difficulty: 'Medium',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Arborio Rice', quantity: '1.5 cups'),
          RecipeIngredient(name: 'Mushrooms', quantity: '200 g, sliced'),
          RecipeIngredient(name: 'Vegetable Broth (warm)', quantity: '4 cups'),
          RecipeIngredient(name: 'Parmesan & Butter', quantity: '1/2 cup & 2 tbsp'),
          RecipeIngredient(name: 'Shallot / Onion', quantity: '1 finely chopped'),
        ],
        steps: [
          'Sauté sliced mushrooms in 1 tbsp butter until browned; set aside.',
          'In the same pan, sauté shallots in butter. Add arborio rice and toast for 2 minutes.',
          'Add warm broth one ladle at a time, stirring constantly until absorbed before adding the next.',
          'Repeat for 18-20 minutes until rice is creamy yet al dente.',
          'Stir in sautéed mushrooms, parmesan cheese, and black pepper.',
        ],
        nutrition: RecipeNutrition(calories: 360, protein: 9.5, carbs: 58, fat: 11, fiber: 2.8),
      ),

      // 4. Chicken (Multi-Cuisine)
      const Recipe(
        id: 'cat_chicken_butter',
        name: 'Classic Murgh Makhani (Butter Chicken)',
        emoji: '🍗',
        cuisine: 'Indian',
        description: 'Tender marinated roasted chicken simmered in a velvety, rich tomato, butter, and cashew gravy.',
        prepTime: '15 min',
        cookTime: '20 min',
        totalTime: '35 min',
        servings: 3,
        difficulty: 'Medium',
        isVegetarian: false,
        ingredients: [
          RecipeIngredient(name: 'Chicken Breast / Thighs', quantity: '400 g, bite-sized'),
          RecipeIngredient(name: 'Tomato Puree', quantity: '1.5 cups'),
          RecipeIngredient(name: 'Cashew Paste & Cream', quantity: '2 tbsp each'),
          RecipeIngredient(name: 'Butter', quantity: '3 tbsp'),
          RecipeIngredient(name: 'Kasuri Methi & Garam Masala', quantity: '1 tbsp & 1 tsp'),
        ],
        steps: [
          'Pan-sear marinated chicken pieces in 1 tbsp butter until lightly charred; set aside.',
          'In the same pan, melt remaining butter and simmer tomato puree with ginger-garlic paste for 8 minutes.',
          'Stir in cashew paste, Kashmiri red chili powder, and salt.',
          'Add seared chicken pieces and simmer for 6 minutes.',
          'Finish with heavy cream and crushed kasuri methi.',
        ],
        nutrition: RecipeNutrition(calories: 430, protein: 32, carbs: 12, fat: 28, fiber: 2.0),
      ),
      const Recipe(
        id: 'cat_chicken_tacos',
        name: 'Zesty Street-Style Chicken Tacos',
        emoji: '🌮',
        cuisine: 'Mexican',
        description: 'Warm corn tortillas stuffed with spiced shredded chicken, crunchy cabbage slaw, and cilantro crema.',
        prepTime: '10 min',
        cookTime: '12 min',
        totalTime: '22 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: false,
        ingredients: [
          RecipeIngredient(name: 'Chicken', quantity: '300 g cooked or shredded'),
          RecipeIngredient(name: 'Corn or Flour Tortillas', quantity: '6 small'),
          RecipeIngredient(name: 'Taco Seasoning (Cumin, Chili, Oregano)', quantity: '1.5 tbsp'),
          RecipeIngredient(name: 'Shredded Cabbage & Lime', quantity: '1 cup cabbage, 1 lime'),
          RecipeIngredient(name: 'Salsa or Hot Sauce', quantity: 'For topping'),
        ],
        steps: [
          'Sauté shredded chicken with taco seasoning and 3 tbsp water until heated through and glazed.',
          'Warm tortillas in a dry skillet for 30 seconds on each side.',
          'Fill each tortilla with seasoned chicken.',
          'Top with shredded cabbage, fresh cilantro, salsa, and a squeeze of lime.',
        ],
        nutrition: RecipeNutrition(calories: 340, protein: 28, carbs: 32, fat: 10, fiber: 4.2),
      ),
      const Recipe(
        id: 'cat_chicken_teriyaki',
        name: 'Japanese Glazed Chicken Teriyaki',
        emoji: '🍱',
        cuisine: 'Japanese',
        description: 'Juicy chicken thighs glazed in an authentic homemade sweet-savory soy and ginger teriyaki sauce.',
        prepTime: '8 min',
        cookTime: '12 min',
        totalTime: '20 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: false,
        ingredients: [
          RecipeIngredient(name: 'Chicken Thighs (boneless)', quantity: '350 g'),
          RecipeIngredient(name: 'Soy Sauce', quantity: '3 tbsp'),
          RecipeIngredient(name: 'Mirin / Honey', quantity: '2 tbsp'),
          RecipeIngredient(name: 'Grated Ginger & Garlic', quantity: '1 tsp each'),
          RecipeIngredient(name: 'Toasted Sesame Seeds', quantity: '1 tsp'),
        ],
        steps: [
          'Season chicken with salt and pepper.',
          'Pan-sear chicken in 1 tsp oil skin-side down for 5 minutes until crispy, then flip.',
          'Mix soy sauce, honey, ginger, and garlic in a small cup.',
          'Pour glaze into the pan. Simmer until the sauce thickens into a glossy coat.',
          'Slice and serve over steamed rice with sesame seeds.',
        ],
        nutrition: RecipeNutrition(calories: 370, protein: 34, carbs: 14, fat: 18, fiber: 0.8),
      ),

      // 5. Paneer (Multi-Cuisine)
      const Recipe(
        id: 'cat_paneer_tikka',
        name: 'Tandoori Paneer Tikka Skewers',
        emoji: '🧀',
        cuisine: 'Indian',
        description: 'Succulent cubes of cottage cheese and crunchy peppers marinated in spiced yogurt and roasted until smoky.',
        prepTime: '15 min',
        cookTime: '12 min',
        totalTime: '27 min',
        servings: 3,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Paneer (cubed)', quantity: '250 g'),
          RecipeIngredient(name: 'Bell Peppers & Onion', quantity: '1 each, cubed'),
          RecipeIngredient(name: 'Hung Curd / Yogurt', quantity: '1/2 cup'),
          RecipeIngredient(name: 'Besan (Gram Flour)', quantity: '1.5 tbsp roasted'),
          RecipeIngredient(name: 'Chaat Masala & Mustard Oil', quantity: '1 tsp each'),
        ],
        steps: [
          'Whisk yogurt, roasted besan, mustard oil, chili powder, and chaat masala.',
          'Coat paneer cubes, onions, and bell peppers gently in marinade. Rest for 15 minutes.',
          'Thread onto skewers.',
          'Roast in an oven at 220°C (425°F) or on a tawa for 10-12 minutes until charred.',
          'Sprinkle chaat masala and lemon juice; serve hot with mint chutney.',
        ],
        nutrition: RecipeNutrition(calories: 290, protein: 18, carbs: 10, fat: 20, fiber: 2.5),
      ),
      const Recipe(
        id: 'cat_paneer_chili',
        name: 'Indo-Chinese Chili Paneer',
        emoji: '🥢',
        cuisine: 'Asian',
        description: 'Crispy golden paneer cubes tossed with crunchy bell peppers, green chilies, and tangy garlic-soy sauce.',
        prepTime: '10 min',
        cookTime: '10 min',
        totalTime: '20 min',
        servings: 2,
        difficulty: 'Easy',
        isVegetarian: true,
        ingredients: [
          RecipeIngredient(name: 'Paneer', quantity: '200 g, cubed'),
          RecipeIngredient(name: 'Cornstarch & Flour', quantity: '2 tbsp each for coating'),
          RecipeIngredient(name: 'Capsicum & Spring Onion', quantity: '1 diced, 2 stalks'),
          RecipeIngredient(name: 'Soy Sauce, Chili Sauce, Vinegar', quantity: '1 tbsp each'),
          RecipeIngredient(name: 'Garlic & Green Chilies', quantity: '1 tbsp minced, 3 slit'),
        ],
        steps: [
          'Toss paneer cubes in cornstarch, salt, and pepper with 1 tbsp water; pan-fry until crisp.',
          'Heat oil in a wok. Sauté minced garlic, chilies, and capsicum for 1 minute.',
          'Mix sauces with 3 tbsp water and a splash of cornstarch slurry; pour into pan.',
          'Simmer until sauce glazes the pan, then fold in crispy paneer cubes.',
          'Toss for 30 seconds and serve immediately.',
        ],
        nutrition: RecipeNutrition(calories: 320, protein: 16, carbs: 18, fat: 21, fiber: 2.0),
      ),
    ];
  }
}
