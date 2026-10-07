class DetectedIngredient {
  final String name;
  final String quantity;
  final String emoji;

  const DetectedIngredient({
    required this.name,
    this.quantity = '',
    this.emoji = '🥗',
  });

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    final nameStr = json['name'] as String? ?? 'Ingredient';
    return DetectedIngredient(
      name: nameStr,
      quantity: json['quantity'] as String? ?? '',
      emoji: json['emoji'] as String? ?? guessEmoji(nameStr),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'emoji': emoji,
  };

  DetectedIngredient copyWith({String? name, String? quantity, String? emoji}) {
    return DetectedIngredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      emoji: emoji ?? this.emoji,
    );
  }

  static String guessEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('egg')) return '🥚';
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('spinach') || lower.contains('palak') || lower.contains('green')) return '🥬';
    if (lower.contains('onion')) return '🧅';
    if (lower.contains('milk') || lower.contains('curd') || lower.contains('yogurt')) return '🥛';
    if (lower.contains('cheese') || lower.contains('paneer')) return '🧀';
    if (lower.contains('bread') || lower.contains('toast')) return '🍞';
    if (lower.contains('carrot')) return '🥕';
    if (lower.contains('potato')) return '🥔';
    if (lower.contains('garlic')) return '🧄';
    if (lower.contains('ginger')) return '🫚';
    if (lower.contains('chicken') || lower.contains('meat')) return '🍗';
    if (lower.contains('rice')) return '🍚';
    if (lower.contains('chili') || lower.contains('chilli') || lower.contains('pepper') || lower.contains('capsicum')) return '🫑';
    if (lower.contains('lemon') || lower.contains('lime')) return '🍋';
    if (lower.contains('mushroom')) return '🍄';
    if (lower.contains('cucumber')) return '🥒';
    if (lower.contains('coriander') || lower.contains('cilantro') || lower.contains('herb')) return '🌿';
    if (lower.contains('butter')) return '🧈';
    if (lower.contains('oil')) return '🫒';
    if (lower.contains('flour') || lower.contains('atta') || lower.contains('wheat')) return '🌾';
    return '🥗';
  }
}

class FridgeAnalysisResult {
  final List<DetectedIngredient> ingredients;
  final DateTime timestamp;
  final String? imagePath;

  const FridgeAnalysisResult({
    required this.ingredients,
    required this.timestamp,
    this.imagePath,
  });

  factory FridgeAnalysisResult.fromJson(Map<String, dynamic> json, {String? imagePath}) {
    final list = (json['ingredients'] as List<dynamic>?)
            ?.map((e) => DetectedIngredient.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return FridgeAnalysisResult(
      ingredients: list,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      imagePath: imagePath ?? json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
  };
}

class RecipeIngredient {
  final String name;
  final String quantity;
  final bool isFromFridge;

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    this.isFromFridge = true,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      isFromFridge: json['isFromFridge'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'isFromFridge': isFromFridge,
  };

  RecipeIngredient copyWith({String? name, String? quantity, bool? isFromFridge}) {
    return RecipeIngredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isFromFridge: isFromFridge ?? this.isFromFridge,
    );
  }
}

class RecipeNutrition {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  const RecipeNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
  });

  factory RecipeNutrition.fromJson(Map<String, dynamic> json) {
    return RecipeNutrition(
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
  };
}

class Recipe {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String prepTime;
  final String cookTime;
  final String totalTime;
  final int servings;
  final String difficulty;
  final String cuisine;
  final String? imageUrl;
  final String? videoUrl;
  final String? source;
  final bool isVegetarian;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final RecipeNutrition nutrition;
  final int matchedCount;
  final int totalIngredientsCount;

  const Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.difficulty,
    this.cuisine = 'General',
    this.imageUrl,
    this.videoUrl,
    this.source,
    this.isVegetarian = true,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    this.matchedCount = 0,
    this.totalIngredientsCount = 0,
  });

  double get matchPercentage =>
      totalIngredientsCount > 0 ? (matchedCount / totalIngredientsCount) : 0.0;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String? ?? 'recipe_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Delicious Recipe',
      emoji: json['emoji'] as String? ?? '🍲',
      description: json['description'] as String? ?? '',
      prepTime: json['prepTime'] as String? ?? '10 min',
      cookTime: json['cookTime'] as String? ?? '15 min',
      totalTime: json['totalTime'] as String? ?? '25 min',
      servings: (json['servings'] as num?)?.toInt() ?? 2,
      difficulty: json['difficulty'] as String? ?? 'Easy',
      cuisine: json['cuisine'] as String? ?? 'General',
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      source: json['source'] as String?,
      isVegetarian: json['isVegetarian'] as bool? ?? true,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      nutrition: json['nutrition'] != null
          ? RecipeNutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
          : const RecipeNutrition(calories: 300, protein: 12, carbs: 32, fat: 10),
      matchedCount: (json['matchedCount'] as num?)?.toInt() ?? 0,
      totalIngredientsCount: (json['totalIngredientsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'description': description,
    'prepTime': prepTime,
    'cookTime': cookTime,
    'totalTime': totalTime,
    'servings': servings,
    'difficulty': difficulty,
    'cuisine': cuisine,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'source': source,
    'isVegetarian': isVegetarian,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'steps': steps,
    'nutrition': nutrition.toJson(),
    'matchedCount': matchedCount,
    'totalIngredientsCount': totalIngredientsCount,
  };
}

class CookingVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelName;
  final String duration;
  final String videoUrl;

  const CookingVideo({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.channelName = 'YouTube Chef',
    this.duration = '8 min',
    required this.videoUrl,
  });

  factory CookingVideo.fromJson(Map<String, dynamic> json) {
    return CookingVideo(
      id: json['id'] as String? ?? 'vid_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Cooking Video',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      channelName: json['channelName'] as String? ?? 'YouTube',
      duration: json['duration'] as String? ?? '8 min',
      videoUrl: json['videoUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'channelName': channelName,
    'duration': duration,
    'videoUrl': videoUrl,
  };
}

class RecipeSearchResult {
  final String query;
  final List<Recipe> recipes;
  final List<CookingVideo> videos;
  final List<String> availableCuisines;
  final List<String> relatedRecommendations;

  const RecipeSearchResult({
    required this.query,
    required this.recipes,
    required this.videos,
    required this.availableCuisines,
    required this.relatedRecommendations,
  });
}
