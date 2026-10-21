import '../models/food_analysis_result.dart';

/// Entry representing cooked or prepared food composition values per 100 grams.
class FoodCompositionEntry {
  final String canonicalName;
  final List<String> aliases;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final double sugarPer100g;
  final double defaultServingGrams;
  final String emoji;
  final String category;
  final bool isCooked;

  const FoodCompositionEntry({
    required this.canonicalName,
    required this.aliases,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
    this.sugarPer100g = 0.0,
    this.defaultServingGrams = 100.0,
    this.emoji = '🍲',
    this.category = 'General',
    this.isCooked = true,
  });
}

/// Standardized Food Composition and Nutrition Calculation Service.
/// Implements consistent calculation:
/// Nutrient = (Nutrient per 100g * portion in grams) / 100
class NutritionDatabaseService {
  NutritionDatabaseService._();
  static final NutritionDatabaseService instance = NutritionDatabaseService._();

  static final List<FoodCompositionEntry> catalog = [
    // --- GRAINS & RICE ---
    const FoodCompositionEntry(
      canonicalName: 'Cooked white rice',
      aliases: ['rice', 'steamed rice', 'white rice', 'boiled rice', 'sadham', 'chawal', 'sona masoori', 'ponni rice'],
      caloriesPer100g: 130,
      proteinPer100g: 2.7,
      carbsPer100g: 28.2,
      fatPer100g: 0.3,
      fiberPer100g: 0.4,
      sugarPer100g: 0.1,
      defaultServingGrams: 180.0,
      emoji: '🍚',
      category: 'Grains',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Cooked brown rice',
      aliases: ['brown rice', 'matta rice'],
      caloriesPer100g: 111,
      proteinPer100g: 2.6,
      carbsPer100g: 23.0,
      fatPer100g: 0.9,
      fiberPer100g: 1.8,
      sugarPer100g: 0.4,
      defaultServingGrams: 180.0,
      emoji: '🍚',
      category: 'Grains',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Vegetable biryani',
      aliases: ['veg biryani', 'vegetable biryani', 'veg pulao', 'vegetable pulao'],
      caloriesPer100g: 152,
      proteinPer100g: 3.6,
      carbsPer100g: 26.5,
      fatPer100g: 3.8,
      fiberPer100g: 2.4,
      sugarPer100g: 1.2,
      defaultServingGrams: 200.0,
      emoji: '🍚',
      category: 'Grains',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Chicken biryani',
      aliases: ['chicken biryani', 'mutton biryani'],
      caloriesPer100g: 185,
      proteinPer100g: 10.2,
      carbsPer100g: 22.0,
      fatPer100g: 6.2,
      fiberPer100g: 1.5,
      sugarPer100g: 0.8,
      defaultServingGrams: 220.0,
      emoji: '🍗',
      category: 'Grains',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Ven Pongal',
      aliases: ['pongal', 'khichdi', 'ghee pongal', 'ven pongal'],
      caloriesPer100g: 165,
      proteinPer100g: 4.5,
      carbsPer100g: 24.0,
      fatPer100g: 5.8,
      fiberPer100g: 1.6,
      sugarPer100g: 0.4,
      defaultServingGrams: 180.0,
      emoji: '🍚',
      category: 'Grains',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Rava Upma',
      aliases: ['upma', 'rava upma', 'uppumavu'],
      caloriesPer100g: 142,
      proteinPer100g: 3.5,
      carbsPer100g: 22.5,
      fatPer100g: 4.2,
      fiberPer100g: 1.8,
      sugarPer100g: 0.9,
      defaultServingGrams: 160.0,
      emoji: '🥣',
      category: 'Grains',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Cooked oatmeal',
      aliases: ['oatmeal', 'oats', 'porridge', 'rolled oats bowl'],
      caloriesPer100g: 71,
      proteinPer100g: 2.5,
      carbsPer100g: 12.0,
      fatPer100g: 1.5,
      fiberPer100g: 1.7,
      sugarPer100g: 0.4,
      defaultServingGrams: 200.0,
      emoji: '🥣',
      category: 'Grains',
    ),

    // --- BREADS & FLATBREADS ---
    const FoodCompositionEntry(
      canonicalName: 'Whole wheat chapati',
      aliases: ['chapati', 'roti', 'phulka', 'whole wheat roti', 'wheat chapati'],
      caloriesPer100g: 264,
      proteinPer100g: 9.2,
      carbsPer100g: 48.0,
      fatPer100g: 3.7,
      fiberPer100g: 9.1,
      sugarPer100g: 0.4,
      defaultServingGrams: 70.0, // ~2 pieces
      emoji: '🫓',
      category: 'Breads',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Steamed Idli',
      aliases: ['idli', 'steamed idli', 'idly'],
      caloriesPer100g: 138,
      proteinPer100g: 3.8,
      carbsPer100g: 28.2,
      fatPer100g: 0.6,
      fiberPer100g: 1.5,
      sugarPer100g: 0.3,
      defaultServingGrams: 120.0, // ~2-3 idlis
      emoji: '⚪',
      category: 'Breads',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Plain Dosa',
      aliases: ['dosa', 'dosai', 'plain dosa', 'crispy dosa', 'ghee roast dosa'],
      caloriesPer100g: 168,
      proteinPer100g: 3.9,
      carbsPer100g: 29.0,
      fatPer100g: 3.7,
      fiberPer100g: 1.4,
      sugarPer100g: 0.2,
      defaultServingGrams: 100.0,
      emoji: '🫓',
      category: 'Breads',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Masala Dosa',
      aliases: ['masala dosa', 'potato masala dosa', 'mysore masala dosa'],
      caloriesPer100g: 206,
      proteinPer100g: 4.2,
      carbsPer100g: 31.5,
      fatPer100g: 6.8,
      fiberPer100g: 2.5,
      sugarPer100g: 1.2,
      defaultServingGrams: 160.0,
      emoji: '🫓',
      category: 'Breads',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Poori',
      aliases: ['poori', 'puri'],
      caloriesPer100g: 320,
      proteinPer100g: 6.8,
      carbsPer100g: 45.0,
      fatPer100g: 12.5,
      fiberPer100g: 4.0,
      sugarPer100g: 0.5,
      defaultServingGrams: 80.0,
      emoji: '🫓',
      category: 'Breads',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Malabar Parotta',
      aliases: ['parotta', 'paratha', 'plain paratha', 'kerala parotta'],
      caloriesPer100g: 326,
      proteinPer100g: 7.5,
      carbsPer100g: 52.0,
      fatPer100g: 9.8,
      fiberPer100g: 2.5,
      sugarPer100g: 1.5,
      defaultServingGrams: 100.0,
      emoji: '🫓',
      category: 'Breads',
    ),
    const FoodCompositionEntry(
      canonicalName: 'White bread slice',
      aliases: ['bread', 'white bread', 'toast'],
      caloriesPer100g: 265,
      proteinPer100g: 9.0,
      carbsPer100g: 49.0,
      fatPer100g: 3.2,
      fiberPer100g: 2.7,
      sugarPer100g: 5.0,
      defaultServingGrams: 60.0,
      emoji: '🍞',
      category: 'Breads',
    ),

    // --- DALS, SAMBAR & GRAVIES ---
    const FoodCompositionEntry(
      canonicalName: 'Cooked lentil dal',
      aliases: ['dal', 'lentil dal', 'toor dal', 'yellow dal', 'dal tadka', 'dal fry', 'moong dal', 'parippu'],
      caloriesPer100g: 116,
      proteinPer100g: 7.3,
      carbsPer100g: 18.2,
      fatPer100g: 1.5,
      fiberPer100g: 4.2,
      sugarPer100g: 0.8,
      defaultServingGrams: 120.0,
      emoji: '🥣',
      category: 'Lentils',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Vegetable sambar',
      aliases: ['sambar', 'vegetable sambar', 'south indian sambar'],
      caloriesPer100g: 78,
      proteinPer100g: 2.8,
      carbsPer100g: 11.5,
      fatPer100g: 2.2,
      fiberPer100g: 2.8,
      sugarPer100g: 2.1,
      defaultServingGrams: 140.0,
      emoji: '🥣',
      category: 'Lentils',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Tomato rasam',
      aliases: ['rasam', 'tomato rasam', 'pepper rasam'],
      caloriesPer100g: 36,
      proteinPer100g: 0.8,
      carbsPer100g: 5.2,
      fatPer100g: 1.2,
      fiberPer100g: 0.9,
      sugarPer100g: 2.0,
      defaultServingGrams: 120.0,
      emoji: '🥣',
      category: 'Soups',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Chana Masala',
      aliases: ['chana masala', 'chole', 'chickpea curry'],
      caloriesPer100g: 164,
      proteinPer100g: 7.2,
      carbsPer100g: 24.5,
      fatPer100g: 4.1,
      fiberPer100g: 6.4,
      sugarPer100g: 2.5,
      defaultServingGrams: 150.0,
      emoji: '🥣',
      category: 'Lentils',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Dal Makhani',
      aliases: ['dal makhani', 'black dal', 'makhani dal'],
      caloriesPer100g: 145,
      proteinPer100g: 5.6,
      carbsPer100g: 15.2,
      fatPer100g: 7.0,
      fiberPer100g: 4.5,
      sugarPer100g: 1.8,
      defaultServingGrams: 140.0,
      emoji: '🥣',
      category: 'Lentils',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Kootu (Lentil & Veg)',
      aliases: ['kootu', 'cabbage kootu', 'chow chow kootu', 'snake gourd kootu'],
      caloriesPer100g: 90,
      proteinPer100g: 3.8,
      carbsPer100g: 12.0,
      fatPer100g: 3.0,
      fiberPer100g: 3.5,
      sugarPer100g: 2.0,
      defaultServingGrams: 120.0,
      emoji: '🥣',
      category: 'Lentils',
    ),

    // --- PANEER & VEGETARIAN CURRIES ---
    const FoodCompositionEntry(
      canonicalName: 'Palak Paneer',
      aliases: ['palak paneer', 'spinach paneer', 'saag paneer'],
      caloriesPer100g: 155,
      proteinPer100g: 8.2,
      carbsPer100g: 5.4,
      fatPer100g: 11.2,
      fiberPer100g: 2.6,
      sugarPer100g: 1.2,
      defaultServingGrams: 140.0,
      emoji: '🧀',
      category: 'Curries',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Paneer Butter Masala',
      aliases: ['paneer butter masala', 'paneer tikka masala', 'shahi paneer', 'paneer curry'],
      caloriesPer100g: 215,
      proteinPer100g: 7.8,
      carbsPer100g: 8.5,
      fatPer100g: 16.8,
      fiberPer100g: 2.1,
      sugarPer100g: 3.5,
      defaultServingGrams: 150.0,
      emoji: '🧀',
      category: 'Curries',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Vegetable Kurma',
      aliases: ['kurma', 'veg kurma', 'vegetable korma'],
      caloriesPer100g: 105,
      proteinPer100g: 2.8,
      carbsPer100g: 10.5,
      fatPer100g: 5.8,
      fiberPer100g: 3.0,
      sugarPer100g: 2.5,
      defaultServingGrams: 140.0,
      emoji: '🥣',
      category: 'Curries',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Aloo Gobi',
      aliases: ['aloo gobi', 'potato cauliflower curry'],
      caloriesPer100g: 110,
      proteinPer100g: 2.5,
      carbsPer100g: 16.0,
      fatPer100g: 4.2,
      fiberPer100g: 3.2,
      sugarPer100g: 2.2,
      defaultServingGrams: 130.0,
      emoji: '🥔',
      category: 'Curries',
    ),

    // --- PORIYAL & VEGETABLE SIDES ---
    const FoodCompositionEntry(
      canonicalName: 'Beans Poriyal',
      aliases: ['beans poriyal', 'green beans poriyal', 'beans stir fry', 'french beans'],
      caloriesPer100g: 68,
      proteinPer100g: 2.4,
      carbsPer100g: 8.2,
      fatPer100g: 2.8,
      fiberPer100g: 3.4,
      sugarPer100g: 2.0,
      defaultServingGrams: 100.0,
      emoji: '🥗',
      category: 'Vegetables',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Carrot & Beans Poriyal',
      aliases: ['carrot poriyal', 'beans carrot poriyal', 'carrot beans stir fry'],
      caloriesPer100g: 72,
      proteinPer100g: 2.0,
      carbsPer100g: 9.5,
      fatPer100g: 2.8,
      fiberPer100g: 3.6,
      sugarPer100g: 3.2,
      defaultServingGrams: 100.0,
      emoji: '🥗',
      category: 'Vegetables',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Cabbage Poriyal',
      aliases: ['cabbage poriyal', 'cabbage stir fry'],
      caloriesPer100g: 62,
      proteinPer100g: 1.8,
      carbsPer100g: 7.5,
      fatPer100g: 2.7,
      fiberPer100g: 2.5,
      sugarPer100g: 2.8,
      defaultServingGrams: 100.0,
      emoji: '🥗',
      category: 'Vegetables',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Potato Roast / Fry',
      aliases: ['potato fry', 'aloo roast', 'potato roast', 'aloo fry'],
      caloriesPer100g: 148,
      proteinPer100g: 2.5,
      carbsPer100g: 23.0,
      fatPer100g: 5.2,
      fiberPer100g: 2.2,
      sugarPer100g: 1.0,
      defaultServingGrams: 100.0,
      emoji: '🥔',
      category: 'Vegetables',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Bhindi Masala (Okra)',
      aliases: ['bhindi', 'okra fry', 'vendakkai poriyal', 'ladies finger stir fry'],
      caloriesPer100g: 85,
      proteinPer100g: 2.2,
      carbsPer100g: 9.0,
      fatPer100g: 4.5,
      fiberPer100g: 3.6,
      sugarPer100g: 2.2,
      defaultServingGrams: 100.0,
      emoji: '🥦',
      category: 'Vegetables',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Fresh Green Salad',
      aliases: ['salad', 'green salad', 'cucumber salad', 'mixed salad', 'kachumber'],
      caloriesPer100g: 25,
      proteinPer100g: 1.1,
      carbsPer100g: 4.5,
      fatPer100g: 0.3,
      fiberPer100g: 1.8,
      sugarPer100g: 2.4,
      defaultServingGrams: 80.0,
      emoji: '🥗',
      category: 'Vegetables',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Steamed Mixed Vegetables',
      aliases: ['steamed vegetables', 'mixed vegetables', 'boiled vegetables', 'veggies'],
      caloriesPer100g: 55,
      proteinPer100g: 2.2,
      carbsPer100g: 9.5,
      fatPer100g: 1.0,
      fiberPer100g: 3.2,
      sugarPer100g: 2.5,
      defaultServingGrams: 110.0,
      emoji: '🥦',
      category: 'Vegetables',
    ),

    // --- PROTEIN & EGGS & MEATS ---
    const FoodCompositionEntry(
      canonicalName: 'Boiled Egg',
      aliases: ['egg', 'boiled egg', 'hard boiled egg'],
      caloriesPer100g: 155,
      proteinPer100g: 12.6,
      carbsPer100g: 1.1,
      fatPer100g: 10.6,
      fiberPer100g: 0.0,
      sugarPer100g: 1.1,
      defaultServingGrams: 50.0, // 1 large egg
      emoji: '🥚',
      category: 'Protein',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Egg Curry',
      aliases: ['egg curry', 'muttai curry', 'anda curry'],
      caloriesPer100g: 135,
      proteinPer100g: 9.2,
      carbsPer100g: 4.5,
      fatPer100g: 8.8,
      fiberPer100g: 1.0,
      sugarPer100g: 1.8,
      defaultServingGrams: 140.0,
      emoji: '🥚',
      category: 'Protein',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Chicken Curry',
      aliases: ['chicken curry', 'chicken gravy', 'murgh curry'],
      caloriesPer100g: 140,
      proteinPer100g: 14.5,
      carbsPer100g: 4.2,
      fatPer100g: 7.2,
      fiberPer100g: 1.2,
      sugarPer100g: 1.5,
      defaultServingGrams: 150.0,
      emoji: '🍗',
      category: 'Protein',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Grilled Chicken Breast',
      aliases: ['grilled chicken', 'chicken breast', 'roast chicken'],
      caloriesPer100g: 165,
      proteinPer100g: 31.0,
      carbsPer100g: 0.0,
      fatPer100g: 3.6,
      fiberPer100g: 0.0,
      sugarPer100g: 0.0,
      defaultServingGrams: 120.0,
      emoji: '🍗',
      category: 'Protein',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Fish Curry',
      aliases: ['fish curry', 'meen kulambu', 'meen curry'],
      caloriesPer100g: 125,
      proteinPer100g: 15.0,
      carbsPer100g: 3.5,
      fatPer100g: 5.5,
      fiberPer100g: 0.8,
      sugarPer100g: 1.0,
      defaultServingGrams: 150.0,
      emoji: '🐟',
      category: 'Protein',
    ),

    // --- DAIRY & CONDIMENTS ---
    const FoodCompositionEntry(
      canonicalName: 'Curd / Yogurt',
      aliases: ['curd', 'yogurt', 'dahi', 'plain curd', 'perugu'],
      caloriesPer100g: 61,
      proteinPer100g: 3.5,
      carbsPer100g: 4.7,
      fatPer100g: 3.3,
      fiberPer100g: 0.0,
      sugarPer100g: 4.7,
      defaultServingGrams: 100.0,
      emoji: '🥛',
      category: 'Dairy',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Cucumber & Onion Raita',
      aliases: ['raita', 'cucumber raita', 'onion raita'],
      caloriesPer100g: 52,
      proteinPer100g: 2.8,
      carbsPer100g: 4.2,
      fatPer100g: 2.4,
      fiberPer100g: 0.8,
      sugarPer100g: 3.2,
      defaultServingGrams: 90.0,
      emoji: '🥣',
      category: 'Dairy',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Coconut Chutney',
      aliases: ['coconut chutney', 'white chutney', 'thengai chutney'],
      caloriesPer100g: 210,
      proteinPer100g: 3.2,
      carbsPer100g: 7.5,
      fatPer100g: 18.5,
      fiberPer100g: 3.8,
      sugarPer100g: 2.5,
      defaultServingGrams: 40.0,
      emoji: '🍵',
      category: 'Condiments',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Tomato Chutney',
      aliases: ['tomato chutney', 'kara chutney', 'red chutney'],
      caloriesPer100g: 85,
      proteinPer100g: 1.8,
      carbsPer100g: 11.2,
      fatPer100g: 3.8,
      fiberPer100g: 2.2,
      sugarPer100g: 5.2,
      defaultServingGrams: 40.0,
      emoji: '🍵',
      category: 'Condiments',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Medu Vada',
      aliases: ['vada', 'medu vada', 'ulundu vadai'],
      caloriesPer100g: 265,
      proteinPer100g: 8.5,
      carbsPer100g: 28.0,
      fatPer100g: 13.0,
      fiberPer100g: 4.2,
      sugarPer100g: 0.5,
      defaultServingGrams: 50.0, // 1 piece
      emoji: '🥯',
      category: 'Snacks',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Papad / Papadum',
      aliases: ['papad', 'appalam', 'papadum'],
      caloriesPer100g: 295,
      proteinPer100g: 21.0,
      carbsPer100g: 48.0,
      fatPer100g: 2.0,
      fiberPer100g: 12.0,
      sugarPer100g: 1.0,
      defaultServingGrams: 15.0, // 1 roasted piece
      emoji: '🍘',
      category: 'Snacks',
    ),

    // --- FRUITS & NUTS ---
    const FoodCompositionEntry(
      canonicalName: 'Sliced Banana',
      aliases: ['banana', 'sliced banana'],
      caloriesPer100g: 89,
      proteinPer100g: 1.1,
      carbsPer100g: 22.8,
      fatPer100g: 0.3,
      fiberPer100g: 2.6,
      sugarPer100g: 12.2,
      defaultServingGrams: 110.0,
      emoji: '🍌',
      category: 'Fruits',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Fresh Apple',
      aliases: ['apple', 'sliced apple'],
      caloriesPer100g: 52,
      proteinPer100g: 0.3,
      carbsPer100g: 13.8,
      fatPer100g: 0.2,
      fiberPer100g: 2.4,
      sugarPer100g: 10.4,
      defaultServingGrams: 120.0,
      emoji: '🍎',
      category: 'Fruits',
    ),
    const FoodCompositionEntry(
      canonicalName: 'Almonds & Nuts',
      aliases: ['almonds', 'nuts', 'mixed nuts', 'chia seeds'],
      caloriesPer100g: 579,
      proteinPer100g: 21.2,
      carbsPer100g: 21.6,
      fatPer100g: 49.9,
      fiberPer100g: 12.5,
      sugarPer100g: 4.4,
      defaultServingGrams: 20.0,
      emoji: '🥜',
      category: 'Nuts',
    ),
  ];

  /// Generic cooked food fallback when an exact match isn't found
  static const FoodCompositionEntry defaultCookedFallback = FoodCompositionEntry(
    canonicalName: 'Cooked meal portion',
    aliases: ['cooked dish', 'dish', 'portion'],
    caloriesPer100g: 120,
    proteinPer100g: 4.5,
    carbsPer100g: 15.0,
    fatPer100g: 4.5,
    fiberPer100g: 2.5,
    sugarPer100g: 2.0,
    defaultServingGrams: 120.0,
    emoji: '🍽️',
    category: 'General',
  );

  /// Matches a food name against the cooked food composition catalog.
  FoodCompositionEntry findMatch(String foodName) {
    final clean = foodName.trim().toLowerCase();

    // 1. Exact canonical or alias match
    for (final entry in catalog) {
      if (entry.canonicalName.toLowerCase() == clean) return entry;
      for (final a in entry.aliases) {
        if (a.toLowerCase() == clean) return entry;
      }
    }

    // 2. Substring match (e.g. "cooked white rice" contains "rice", or "rice" in "steamed rice")
    for (final entry in catalog) {
      for (final a in entry.aliases) {
        if (clean.contains(a) || a.contains(clean)) {
          return entry;
        }
      }
    }

    // 3. Keyword token matching
    final tokens = clean.split(RegExp(r'\s+'));
    for (final token in tokens) {
      if (token.length <= 2) continue;
      for (final entry in catalog) {
        for (final a in entry.aliases) {
          if (a.contains(token)) return entry;
        }
      }
    }

    return defaultCookedFallback;
  }

  /// Calculates a [FoodItem] for a recognized food name and portion in grams.
  /// Uses strictly: nutrient = nutrient_per_100g * grams / 100
  FoodItem calculateFoodItem({
    required String name,
    required double grams,
    double confidence = 0.85,
    List<String> alternatives = const [],
    String? notes,
  }) {
    final entry = findMatch(name);

    final ratio = grams / 100.0;
    final cals = (entry.caloriesPer100g * ratio).round();
    final p = double.parse((entry.proteinPer100g * ratio).toStringAsFixed(1));
    final c = double.parse((entry.carbsPer100g * ratio).toStringAsFixed(1));
    final f = double.parse((entry.fatPer100g * ratio).toStringAsFixed(1));
    final fib = double.parse((entry.fiberPer100g * ratio).toStringAsFixed(1));
    final sug = double.parse((entry.sugarPer100g * ratio).toStringAsFixed(1));

    return FoodItem(
      name: name,
      quantity: '${grams.toStringAsFixed(0)} g',
      calories: cals,
      protein: p,
      carbs: c,
      fat: f,
      fiber: fib,
      sugar: sug,
      emoji: entry.emoji,
      confidence: confidence,
      estimatedGrams: grams,
      portionIsEstimated: true,
      alternatives: alternatives,
      notes: notes,
    );
  }

  /// Recalculates full [FoodAnalysisResult] after user edits food items or portions.
  FoodAnalysisResult recalculateMeal({
    required FoodAnalysisResult original,
    required List<FoodItem> updatedFoods,
  }) {
    final recalculatedFoods = updatedFoods.map((item) {
      return calculateFoodItem(
        name: item.name,
        grams: item.estimatedGrams,
        confidence: item.confidence,
        alternatives: item.alternatives,
        notes: item.notes,
      );
    }).toList();

    final totalSummary = FoodAnalysisResult.calculateTotal(recalculatedFoods);
    final balance = FoodAnalysisResult.calculateBalance(totalSummary, recalculatedFoods);

    return original.copyWith(
      foods: recalculatedFoods,
      total: totalSummary,
      balance: balance,
      analysisSource: 'user_edited',
    );
  }
}
