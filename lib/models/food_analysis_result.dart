library food_analysis_result;

/// Amudhu Food Analysis Models
/// Null-safe Dart models representing food detection, portion estimation,
/// and consistent nutrition analysis.

class FoodItem {
  final String name;
  final String quantity;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final String emoji;

  /// Vision model recognition confidence score (0.0 to 1.0)
  final double confidence;

  /// Estimated edible portion in grams
  final double estimatedGrams;

  /// Whether the portion size is visually estimated
  final bool portionIsEstimated;

  /// Plausible alternative food identifications if uncertain
  final List<String> alternatives;

  /// Important visual uncertainty or preparation notes
  final String? notes;

  const FoodItem({
    required this.name,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.sugar = 0.0,
    this.emoji = '🍲',
    this.confidence = 0.85,
    this.estimatedGrams = 100.0,
    this.portionIsEstimated = true,
    this.alternatives = const [],
    this.notes,
  });

  FoodItem copyWith({
    String? name,
    String? quantity,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    String? emoji,
    double? confidence,
    double? estimatedGrams,
    bool? portionIsEstimated,
    List<String>? alternatives,
    String? notes,
  }) {
    return FoodItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      emoji: emoji ?? this.emoji,
      confidence: confidence ?? this.confidence,
      estimatedGrams: estimatedGrams ?? this.estimatedGrams,
      portionIsEstimated: portionIsEstimated ?? this.portionIsEstimated,
      alternatives: alternatives ?? this.alternatives,
      notes: notes ?? this.notes,
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? 'Identified Food';
    final parsedGrams = (json['estimatedGrams'] as num?)?.toDouble() ??
        _extractGrams(json['quantity'] as String?) ??
        100.0;
    final qty = json['quantity'] as String? ?? '${parsedGrams.toStringAsFixed(0)} g';

    final altList = (json['alternatives'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return FoodItem(
      name: rawName,
      quantity: qty,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
      emoji: json['emoji'] as String? ?? _guessEmoji(rawName),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      estimatedGrams: parsedGrams,
      portionIsEstimated: json['portionIsEstimated'] as bool? ?? true,
      alternatives: altList,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
    'emoji': emoji,
    'confidence': confidence,
    'estimatedGrams': estimatedGrams,
    'portionIsEstimated': portionIsEstimated,
    'alternatives': alternatives,
    'notes': notes,
  };

  static double? _extractGrams(String? text) {
    if (text == null) return null;
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*g', caseSensitive: false).firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  static String _guessEmoji(String foodName) {
    final lower = foodName.toLowerCase();
    if (lower.contains('rice') || lower.contains('biryani') || lower.contains('pulao') || lower.contains('pongal')) {
      return '🍚';
    } else if (lower.contains('dal') || lower.contains('sambar') || lower.contains('rasam') || lower.contains('soup') || lower.contains('curry') || lower.contains('kootu')) {
      return '🥣';
    } else if (lower.contains('egg')) {
      return '🥚';
    } else if (lower.contains('idli')) {
      return '⚪';
    } else if (lower.contains('dosa') || lower.contains('roti') || lower.contains('chapati') || lower.contains('poori') || lower.contains('parotta') || lower.contains('bread') || lower.contains('naan')) {
      return '🫓';
    } else if (lower.contains('paneer') || lower.contains('cheese') || lower.contains('tofu')) {
      return '🧀';
    } else if (lower.contains('chicken') || lower.contains('meat') || lower.contains('mutton')) {
      return '🍗';
    } else if (lower.contains('fish') || lower.contains('seafood') || lower.contains('prawn')) {
      return '🐟';
    } else if (lower.contains('vada')) {
      return '🥯';
    } else if (lower.contains('chutney') || lower.contains('dip') || lower.contains('sauce')) {
      return '🍵';
    } else if (lower.contains('salad') || lower.contains('cucumber') || lower.contains('raita')) {
      return '🥗';
    } else if (lower.contains('vegetable') || lower.contains('poriyal') || lower.contains('spinach') || lower.contains('greens') || lower.contains('beans') || lower.contains('broccoli')) {
      return '🥦';
    } else if (lower.contains('curd') || lower.contains('yogurt') || lower.contains('milk') || lower.contains('dahi')) {
      return '🥛';
    } else if (lower.contains('tea') || lower.contains('chai') || lower.contains('coffee')) {
      return '☕';
    } else if (lower.contains('fruit') || lower.contains('apple') || lower.contains('banana')) {
      return '🍎';
    } else if (lower.contains('nut') || lower.contains('almond') || lower.contains('seed')) {
      return '🥜';
    }
    return '🍽️';
  }
}

/// Type alias for DetectedFood for clear domain semantic naming
typedef DetectedFood = FoodItem;

class NutritionSummary {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;

  const NutritionSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.sugar = 0.0,
  });

  NutritionSummary copyWith({
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
  }) {
    return NutritionSummary(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
    );
  }

  factory NutritionSummary.fromJson(Map<String, dynamic> json) {
    return NutritionSummary(
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
  };
}

class MealBalance {
  final int score;
  final String status;
  final String description;
  final String tip;
  final String amudhuNote;

  const MealBalance({
    required this.score,
    required this.status,
    required this.description,
    required this.tip,
    required this.amudhuNote,
  });

  MealBalance copyWith({
    int? score,
    String? status,
    String? description,
    String? tip,
    String? amudhuNote,
  }) {
    return MealBalance(
      score: score ?? this.score,
      status: status ?? this.status,
      description: description ?? this.description,
      tip: tip ?? this.tip,
      amudhuNote: amudhuNote ?? this.amudhuNote,
    );
  }

  factory MealBalance.fromJson(Map<String, dynamic> json) {
    return MealBalance(
      score: (json['score'] as num?)?.toInt() ?? 75,
      status: json['status'] as String? ?? 'Good balance!',
      description: json['description'] as String? ??
          'Your meal brings together wholesome energy and nutrients.',
      tip: json['tip'] as String? ??
          'Consider adding a little more greens or protein for a well-rounded meal.',
      amudhuNote: json['amudhuNote'] as String? ??
          'Nutrition values are educational approximations based on visible plate portions.',
    );
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'status': status,
    'description': description,
    'tip': tip,
    'amudhuNote': amudhuNote,
  };
}

class FoodAnalysisResult {
  final String mealName;
  final List<FoodItem> foods;
  final NutritionSummary total;
  final MealBalance balance;
  final List<String> vitaminsAndMinerals;
  final DateTime timestamp;
  final String? imagePath;

  /// Identifier of the recognition engine ('real_ai', 'user_edited', etc.)
  final String analysisSource;

  /// Discloses that values are calculated estimates
  final bool isEstimate;

  /// Global notes or warnings regarding lighting, blur, or occlusions
  final String? uncertaintyNotes;

  const FoodAnalysisResult({
    required this.mealName,
    required this.foods,
    required this.total,
    required this.balance,
    required this.vitaminsAndMinerals,
    required this.timestamp,
    this.imagePath,
    this.analysisSource = 'real_ai',
    this.isEstimate = true,
    this.uncertaintyNotes,
  });

  /// Semantic getters matching Section 7 requirements
  NutritionSummary get nutrition => total;
  List<DetectedFood> get detectedFoods => foods;

  FoodAnalysisResult copyWith({
    String? mealName,
    List<FoodItem>? foods,
    NutritionSummary? total,
    MealBalance? balance,
    List<String>? vitaminsAndMinerals,
    DateTime? timestamp,
    String? imagePath,
    String? analysisSource,
    bool? isEstimate,
    String? uncertaintyNotes,
  }) {
    return FoodAnalysisResult(
      mealName: mealName ?? this.mealName,
      foods: foods ?? this.foods,
      total: total ?? this.total,
      balance: balance ?? this.balance,
      vitaminsAndMinerals: vitaminsAndMinerals ?? this.vitaminsAndMinerals,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      analysisSource: analysisSource ?? this.analysisSource,
      isEstimate: isEstimate ?? this.isEstimate,
      uncertaintyNotes: uncertaintyNotes ?? this.uncertaintyNotes,
    );
  }

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json, {String? imagePath}) {
    final foodsList = (json['foods'] as List<dynamic>?)
            ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Support both 'nutrition' and 'total' keys
    final totalMap = (json['nutrition'] as Map<String, dynamic>?) ??
        (json['total'] as Map<String, dynamic>?);

    final totalSummary = totalMap != null
        ? NutritionSummary.fromJson(totalMap)
        : calculateTotal(foodsList);

    final balanceInfo = json['balance'] != null
        ? MealBalance.fromJson(json['balance'] as Map<String, dynamic>)
        : calculateBalance(totalSummary, foodsList);

    final vitaminsList = (json['vitaminsAndMinerals'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        defaultVitamins;

    return FoodAnalysisResult(
      mealName: json['mealName'] as String? ?? 'Nutritious Meal',
      foods: foodsList,
      total: totalSummary,
      balance: balanceInfo,
      vitaminsAndMinerals: vitaminsList,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      imagePath: imagePath ?? json['imagePath'] as String?,
      analysisSource: json['analysisSource'] as String? ?? 'real_ai',
      isEstimate: json['isEstimate'] as bool? ?? true,
      uncertaintyNotes: json['uncertaintyNotes'] as String? ?? json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'mealName': mealName,
    'foods': foods.map((f) => f.toJson()).toList(),
    'total': total.toJson(),
    'nutrition': total.toJson(),
    'balance': balance.toJson(),
    'vitaminsAndMinerals': vitaminsAndMinerals,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
    'analysisSource': analysisSource,
    'isEstimate': isEstimate,
    'uncertaintyNotes': uncertaintyNotes,
  };

  /// Calculates the nutritional sum across all recognized items
  static NutritionSummary calculateTotal(List<FoodItem> items) {
    int cals = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;
    double sugar = 0;

    for (final f in items) {
      cals += f.calories;
      protein += f.protein;
      carbs += f.carbs;
      fat += f.fat;
      fiber += f.fiber;
      sugar += f.sugar;
    }

    return NutritionSummary(
      calories: cals,
      protein: double.parse(protein.toStringAsFixed(1)),
      carbs: double.parse(carbs.toStringAsFixed(1)),
      fat: double.parse(fat.toStringAsFixed(1)),
      fiber: double.parse(fiber.toStringAsFixed(1)),
      sugar: double.parse(sugar.toStringAsFixed(1)),
    );
  }

  /// Calculates an approximate meal balance score (40 - 95)
  /// Presented clearly as an approximate educational indicator.
  static MealBalance calculateBalance(NutritionSummary total, List<FoodItem> items) {
    int score = 65;
    if (total.protein >= 18) score += 12;
    if (total.fiber >= 6) score += 13;
    if (total.fat > 25) score -= 6;
    if (total.sugar > 20) score -= 8;
    score = score.clamp(40, 96);

    String status = score >= 80 ? 'Well Balanced!' : (score >= 65 ? 'Good Balance!' : 'Needs Balance');
    String desc = 'Your meal brings together wholesome energy and nutrients.';
    String tip = 'Try pairing with a serving of leafy greens or fresh salad for more fiber.';
    if (total.protein < 15) {
      tip = 'Consider adding more lentils, eggs, paneer, or tofu to increase protein.';
    } else if (total.fiber < 5) {
      tip = 'Adding raw salad or steamed greens will boost your meal’s dietary fiber.';
    }

    return MealBalance(
      score: score,
      status: status,
      description: desc,
      tip: tip,
      amudhuNote: 'Approximate nutritional balance indicator based on detected foods and portions. Not a medical assessment.',
    );
  }

  static const List<String> defaultVitamins = [
    'Vitamin A  28%',
    'B1  18%',
    'B2  22%',
    'B6  19%',
    'B12  12%',
    'Vitamin C  35%',
    'Vitamin D  8%',
    'Vitamin E  16%',
    'Vitamin K  30%',
    'Calcium  18%',
    'Iron  24%',
    'Magnesium  21%',
    'Potassium  26%',
    'Zinc  14%',
    'Phosphorus  29%',
  ];
}
