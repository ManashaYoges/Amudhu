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
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String? ?? 'Unknown Food',
      quantity: json['quantity'] as String? ?? '1 serving',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
      emoji: json['emoji'] as String? ?? _guessEmoji(json['name'] as String? ?? ''),
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
  };

  static String _guessEmoji(String foodName) {
    final lower = foodName.toLowerCase();
    if (lower.contains('rice') || lower.contains('biryani') || lower.contains('pulao')) {
      return '🍚';
    } else if (lower.contains('dal') || lower.contains('sambar') || lower.contains('soup') || lower.contains('curry')) {
      return '🥣';
    } else if (lower.contains('egg')) {
      return '🥚';
    } else if (lower.contains('vegetable') || lower.contains('green') || lower.contains('spinach') || lower.contains('broccoli')) {
      return '🥦';
    } else if (lower.contains('salad') || lower.contains('cucumber')) {
      return '🥗';
    } else if (lower.contains('paneer') || lower.contains('cheese') || lower.contains('tofu')) {
      return '🧀';
    } else if (lower.contains('chicken') || lower.contains('meat') || lower.contains('mutton')) {
      return '🍗';
    } else if (lower.contains('fish') || lower.contains('seafood')) {
      return '🐟';
    } else if (lower.contains('roti') || lower.contains('chapati') || lower.contains('bread') || lower.contains('naan')) {
      return '🫓';
    } else if (lower.contains('fruit') || lower.contains('apple') || lower.contains('banana')) {
      return '🍎';
    } else if (lower.contains('yogurt') || lower.contains('curd')) {
      return '🥛';
    }
    return '🍽️';
  }
}

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

  factory MealBalance.fromJson(Map<String, dynamic> json) {
    return MealBalance(
      score: (json['score'] as num?)?.toInt() ?? 75,
      status: json['status'] as String? ?? 'Good balance!',
      description: json['description'] as String? ??
          'Your meal brings together wholesome energy and nutrients.',
      tip: json['tip'] as String? ??
          'Consider adding a little more greens or protein for a well-rounded meal.',
      amudhuNote: json['amudhuNote'] as String? ??
          'Nutrition values are estimates and may vary with ingredients and preparation.',
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

  const FoodAnalysisResult({
    required this.mealName,
    required this.foods,
    required this.total,
    required this.balance,
    required this.vitaminsAndMinerals,
    required this.timestamp,
    this.imagePath,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json, {String? imagePath}) {
    final foodsList = (json['foods'] as List<dynamic>?)
            ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final totalSummary = json['total'] != null
        ? NutritionSummary.fromJson(json['total'] as Map<String, dynamic>)
        : _calculateTotal(foodsList);

    final balanceInfo = json['balance'] != null
        ? MealBalance.fromJson(json['balance'] as Map<String, dynamic>)
        : _calculateBalance(totalSummary, foodsList);

    final vitaminsList = (json['vitaminsAndMinerals'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        _defaultVitamins;

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
    );
  }

  Map<String, dynamic> toJson() => {
    'mealName': mealName,
    'foods': foods.map((f) => f.toJson()).toList(),
    'total': total.toJson(),
    'balance': balance.toJson(),
    'vitaminsAndMinerals': vitaminsAndMinerals,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
  };

  static NutritionSummary _calculateTotal(List<FoodItem> items) {
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

  static MealBalance _calculateBalance(NutritionSummary total, List<FoodItem> items) {
    int score = 65;
    if (total.protein >= 18) score += 12;
    if (total.fiber >= 6) score += 13;
    if (total.fat > 25) score -= 6;
    if (total.sugar > 20) score -= 8;
    score = score.clamp(40, 96);

    String status = score >= 80 ? 'Well Balanced!' : (score >= 65 ? 'Good Balance!' : 'Needs Balance');
    String desc = 'Your meal brings together grains, protein, and nutrients.';
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
      amudhuNote: 'Estimated nutrition based on detected foods and portions. Values are educational approximations.',
    );
  }

  static const List<String> _defaultVitamins = [
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
