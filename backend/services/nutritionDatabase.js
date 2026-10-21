/**
 * Amudhu Food Composition & Nutrition Database
 * Standardized nutritional values per 100 grams of cooked/prepared edible portion.
 * Formula: nutrient = (nutrientPer100g * estimatedGrams) / 100
 */

const FOOD_DATABASE = [
  // --- GRAINS & RICE ---
  {
    canonicalName: 'Cooked white rice',
    aliases: ['rice', 'steamed rice', 'white rice', 'boiled rice', 'sadham', 'chawal', 'sona masoori', 'ponni rice'],
    caloriesPer100g: 130,
    proteinPer100g: 2.7,
    carbsPer100g: 28.2,
    fatPer100g: 0.3,
    fiberPer100g: 0.4,
    sugarPer100g: 0.1,
    defaultServingGrams: 180,
    emoji: '🍚',
    category: 'Grains'
  },
  {
    canonicalName: 'Cooked brown rice',
    aliases: ['brown rice', 'matta rice'],
    caloriesPer100g: 111,
    proteinPer100g: 2.6,
    carbsPer100g: 23.0,
    fatPer100g: 0.9,
    fiberPer100g: 1.8,
    sugarPer100g: 0.4,
    defaultServingGrams: 180,
    emoji: '🍚',
    category: 'Grains'
  },
  {
    canonicalName: 'Vegetable biryani',
    aliases: ['veg biryani', 'vegetable biryani', 'veg pulao', 'vegetable pulao'],
    caloriesPer100g: 152,
    proteinPer100g: 3.6,
    carbsPer100g: 26.5,
    fatPer100g: 3.8,
    fiberPer100g: 2.4,
    sugarPer100g: 1.2,
    defaultServingGrams: 200,
    emoji: '🍚',
    category: 'Grains'
  },
  {
    canonicalName: 'Chicken biryani',
    aliases: ['chicken biryani', 'mutton biryani'],
    caloriesPer100g: 185,
    proteinPer100g: 10.2,
    carbsPer100g: 22.0,
    fatPer100g: 6.2,
    fiberPer100g: 1.5,
    sugarPer100g: 0.8,
    defaultServingGrams: 220,
    emoji: '🍗',
    category: 'Grains'
  },
  {
    canonicalName: 'Ven Pongal',
    aliases: ['pongal', 'khichdi', 'ghee pongal', 'ven pongal'],
    caloriesPer100g: 165,
    proteinPer100g: 4.5,
    carbsPer100g: 24.0,
    fatPer100g: 5.8,
    fiberPer100g: 1.6,
    sugarPer100g: 0.4,
    defaultServingGrams: 180,
    emoji: '🍚',
    category: 'Grains'
  },
  {
    canonicalName: 'Rava Upma',
    aliases: ['upma', 'rava upma', 'uppumavu'],
    caloriesPer100g: 142,
    proteinPer100g: 3.5,
    carbsPer100g: 22.5,
    fatPer100g: 4.2,
    fiberPer100g: 1.8,
    sugarPer100g: 0.9,
    defaultServingGrams: 160,
    emoji: '🥣',
    category: 'Grains'
  },
  {
    canonicalName: 'Cooked oatmeal',
    aliases: ['oatmeal', 'oats', 'porridge', 'rolled oats bowl'],
    caloriesPer100g: 71,
    proteinPer100g: 2.5,
    carbsPer100g: 12.0,
    fatPer100g: 1.5,
    fiberPer100g: 1.7,
    sugarPer100g: 0.4,
    defaultServingGrams: 200,
    emoji: '🥣',
    category: 'Grains'
  },

  // --- BREADS & FLATBREADS ---
  {
    canonicalName: 'Whole wheat chapati',
    aliases: ['chapati', 'roti', 'phulka', 'whole wheat roti', 'wheat chapati'],
    caloriesPer100g: 264,
    proteinPer100g: 9.2,
    carbsPer100g: 48.0,
    fatPer100g: 3.7,
    fiberPer100g: 9.1,
    sugarPer100g: 0.4,
    defaultServingGrams: 70, // ~2 pieces
    emoji: '🫓',
    category: 'Breads'
  },
  {
    canonicalName: 'Steamed Idli',
    aliases: ['idli', 'steamed idli', 'idly'],
    caloriesPer100g: 138,
    proteinPer100g: 3.8,
    carbsPer100g: 28.2,
    fatPer100g: 0.6,
    fiberPer100g: 1.5,
    sugarPer100g: 0.3,
    defaultServingGrams: 120, // ~2-3 idlis
    emoji: '⚪',
    category: 'Breads'
  },
  {
    canonicalName: 'Plain Dosa',
    aliases: ['dosa', 'dosai', 'plain dosa', 'crispy dosa', 'ghee roast dosa'],
    caloriesPer100g: 168,
    proteinPer100g: 3.9,
    carbsPer100g: 29.0,
    fatPer100g: 3.7,
    fiberPer100g: 1.4,
    sugarPer100g: 0.2,
    defaultServingGrams: 100,
    emoji: '🫓',
    category: 'Breads'
  },
  {
    canonicalName: 'Masala Dosa',
    aliases: ['masala dosa', 'potato masala dosa', 'mysore masala dosa'],
    caloriesPer100g: 206,
    proteinPer100g: 4.2,
    carbsPer100g: 31.5,
    fatPer100g: 6.8,
    fiberPer100g: 2.5,
    sugarPer100g: 1.2,
    defaultServingGrams: 160,
    emoji: '🫓',
    category: 'Breads'
  },
  {
    canonicalName: 'Poori',
    aliases: ['poori', 'puri'],
    caloriesPer100g: 320,
    proteinPer100g: 6.8,
    carbsPer100g: 45.0,
    fatPer100g: 12.5,
    fiberPer100g: 4.0,
    sugarPer100g: 0.5,
    defaultServingGrams: 80,
    emoji: '🫓',
    category: 'Breads'
  },
  {
    canonicalName: 'Malabar Parotta',
    aliases: ['parotta', 'paratha', 'plain paratha', 'kerala parotta'],
    caloriesPer100g: 326,
    proteinPer100g: 7.5,
    carbsPer100g: 52.0,
    fatPer100g: 9.8,
    fiberPer100g: 2.5,
    sugarPer100g: 1.5,
    defaultServingGrams: 100,
    emoji: '🫓',
    category: 'Breads'
  },
  {
    canonicalName: 'White bread slice',
    aliases: ['bread', 'white bread', 'toast'],
    caloriesPer100g: 265,
    proteinPer100g: 9.0,
    carbsPer100g: 49.0,
    fatPer100g: 3.2,
    fiberPer100g: 2.7,
    sugarPer100g: 5.0,
    defaultServingGrams: 60,
    emoji: '🍞',
    category: 'Breads'
  },

  // --- DALS, SAMBAR & SOUPS ---
  {
    canonicalName: 'Cooked lentil dal',
    aliases: ['dal', 'lentil dal', 'toor dal', 'yellow dal', 'dal tadka', 'dal fry', 'moong dal', 'parippu'],
    caloriesPer100g: 116,
    proteinPer100g: 7.3,
    carbsPer100g: 18.2,
    fatPer100g: 1.5,
    fiberPer100g: 4.2,
    sugarPer100g: 0.8,
    defaultServingGrams: 120,
    emoji: '🥣',
    category: 'Lentils'
  },
  {
    canonicalName: 'Vegetable sambar',
    aliases: ['sambar', 'vegetable sambar', 'south indian sambar'],
    caloriesPer100g: 78,
    proteinPer100g: 2.8,
    carbsPer100g: 11.5,
    fatPer100g: 2.2,
    fiberPer100g: 2.8,
    sugarPer100g: 2.1,
    defaultServingGrams: 140,
    emoji: '🥣',
    category: 'Lentils'
  },
  {
    canonicalName: 'Tomato rasam',
    aliases: ['rasam', 'tomato rasam', 'pepper rasam'],
    caloriesPer100g: 36,
    proteinPer100g: 0.8,
    carbsPer100g: 5.2,
    fatPer100g: 1.2,
    fiberPer100g: 0.9,
    sugarPer100g: 2.0,
    defaultServingGrams: 120,
    emoji: '🥣',
    category: 'Soups'
  },
  {
    canonicalName: 'Chana Masala',
    aliases: ['chana masala', 'chole', 'chickpea curry'],
    caloriesPer100g: 164,
    proteinPer100g: 7.2,
    carbsPer100g: 24.5,
    fatPer100g: 4.1,
    fiberPer100g: 6.4,
    sugarPer100g: 2.5,
    defaultServingGrams: 150,
    emoji: '🥣',
    category: 'Lentils'
  },
  {
    canonicalName: 'Dal Makhani',
    aliases: ['dal makhani', 'black dal', 'makhani dal'],
    caloriesPer100g: 145,
    proteinPer100g: 5.6,
    carbsPer100g: 15.2,
    fatPer100g: 7.0,
    fiberPer100g: 4.5,
    sugarPer100g: 1.8,
    defaultServingGrams: 140,
    emoji: '🥣',
    category: 'Lentils'
  },
  {
    canonicalName: 'Kootu (Lentil & Veg)',
    aliases: ['kootu', 'cabbage kootu', 'chow chow kootu', 'snake gourd kootu'],
    caloriesPer100g: 90,
    proteinPer100g: 3.8,
    carbsPer100g: 12.0,
    fatPer100g: 3.0,
    fiberPer100g: 3.5,
    sugarPer100g: 2.0,
    defaultServingGrams: 120,
    emoji: '🥣',
    category: 'Lentils'
  },

  // --- PANEER & CURRIES ---
  {
    canonicalName: 'Palak Paneer',
    aliases: ['palak paneer', 'spinach paneer', 'saag paneer'],
    caloriesPer100g: 155,
    proteinPer100g: 8.2,
    carbsPer100g: 5.4,
    fatPer100g: 11.2,
    fiberPer100g: 2.6,
    sugarPer100g: 1.2,
    defaultServingGrams: 140,
    emoji: '🧀',
    category: 'Curries'
  },
  {
    canonicalName: 'Paneer Butter Masala',
    aliases: ['paneer butter masala', 'paneer tikka masala', 'shahi paneer', 'paneer curry'],
    caloriesPer100g: 215,
    proteinPer100g: 7.8,
    carbsPer100g: 8.5,
    fatPer100g: 16.8,
    fiberPer100g: 2.1,
    sugarPer100g: 3.5,
    defaultServingGrams: 150,
    emoji: '🧀',
    category: 'Curries'
  },
  {
    canonicalName: 'Vegetable Kurma',
    aliases: ['kurma', 'veg kurma', 'vegetable korma'],
    caloriesPer100g: 105,
    proteinPer100g: 2.8,
    carbsPer100g: 10.5,
    fatPer100g: 5.8,
    fiberPer100g: 3.0,
    sugarPer100g: 2.5,
    defaultServingGrams: 140,
    emoji: '🥣',
    category: 'Curries'
  },
  {
    canonicalName: 'Aloo Gobi',
    aliases: ['aloo gobi', 'potato cauliflower curry'],
    caloriesPer100g: 110,
    proteinPer100g: 2.5,
    carbsPer100g: 16.0,
    fatPer100g: 4.2,
    fiberPer100g: 3.2,
    sugarPer100g: 2.2,
    defaultServingGrams: 130,
    emoji: '🥔',
    category: 'Curries'
  },

  // --- PORIYAL & VEGETABLES ---
  {
    canonicalName: 'Beans Poriyal',
    aliases: ['beans poriyal', 'green beans poriyal', 'beans stir fry', 'french beans'],
    caloriesPer100g: 68,
    proteinPer100g: 2.4,
    carbsPer100g: 8.2,
    fatPer100g: 2.8,
    fiberPer100g: 3.4,
    sugarPer100g: 2.0,
    defaultServingGrams: 100,
    emoji: '🥗',
    category: 'Vegetables'
  },
  {
    canonicalName: 'Carrot & Beans Poriyal',
    aliases: ['carrot poriyal', 'beans carrot poriyal', 'carrot beans stir fry'],
    caloriesPer100g: 72,
    proteinPer100g: 2.0,
    carbsPer100g: 9.5,
    fatPer100g: 2.8,
    fiberPer100g: 3.6,
    sugarPer100g: 3.2,
    defaultServingGrams: 100,
    emoji: '🥗',
    category: 'Vegetables'
  },
  {
    canonicalName: 'Cabbage Poriyal',
    aliases: ['cabbage poriyal', 'cabbage stir fry'],
    caloriesPer100g: 62,
    proteinPer100g: 1.8,
    carbsPer100g: 7.5,
    fatPer100g: 2.7,
    fiberPer100g: 2.5,
    sugarPer100g: 2.8,
    defaultServingGrams: 100,
    emoji: '🥗',
    category: 'Vegetables'
  },
  {
    canonicalName: 'Potato Roast / Fry',
    aliases: ['potato fry', 'aloo roast', 'potato roast', 'aloo fry'],
    caloriesPer100g: 148,
    proteinPer100g: 2.5,
    carbsPer100g: 23.0,
    fatPer100g: 5.2,
    fiberPer100g: 2.2,
    sugarPer100g: 1.0,
    defaultServingGrams: 100,
    emoji: '🥔',
    category: 'Vegetables'
  },
  {
    canonicalName: 'Bhindi Masala (Okra)',
    aliases: ['bhindi', 'okra fry', 'vendakkai poriyal', 'ladies finger stir fry'],
    caloriesPer100g: 85,
    proteinPer100g: 2.2,
    carbsPer100g: 9.0,
    fatPer100g: 4.5,
    fiberPer100g: 3.6,
    sugarPer100g: 2.2,
    defaultServingGrams: 100,
    emoji: '🥦',
    category: 'Vegetables'
  },
  {
    canonicalName: 'Fresh Green Salad',
    aliases: ['salad', 'green salad', 'cucumber salad', 'mixed salad', 'kachumber'],
    caloriesPer100g: 25,
    proteinPer100g: 1.1,
    carbsPer100g: 4.5,
    fatPer100g: 0.3,
    fiberPer100g: 1.8,
    sugarPer100g: 2.4,
    defaultServingGrams: 80,
    emoji: '🥗',
    category: 'Vegetables'
  },
  {
    canonicalName: 'Steamed Mixed Vegetables',
    aliases: ['steamed vegetables', 'mixed vegetables', 'boiled vegetables', 'veggies'],
    caloriesPer100g: 55,
    proteinPer100g: 2.2,
    carbsPer100g: 9.5,
    fatPer100g: 1.0,
    fiberPer100g: 3.2,
    sugarPer100g: 2.5,
    defaultServingGrams: 110,
    emoji: '🥦',
    category: 'Vegetables'
  },

  // --- PROTEINS ---
  {
    canonicalName: 'Boiled Egg',
    aliases: ['egg', 'boiled egg', 'hard boiled egg'],
    caloriesPer100g: 155,
    proteinPer100g: 12.6,
    carbsPer100g: 1.1,
    fatPer100g: 10.6,
    fiberPer100g: 0.0,
    sugarPer100g: 1.1,
    defaultServingGrams: 50,
    emoji: '🥚',
    category: 'Protein'
  },
  {
    canonicalName: 'Egg Curry',
    aliases: ['egg curry', 'muttai curry', 'anda curry'],
    caloriesPer100g: 135,
    proteinPer100g: 9.2,
    carbsPer100g: 4.5,
    fatPer100g: 8.8,
    fiberPer100g: 1.0,
    sugarPer100g: 1.8,
    defaultServingGrams: 140,
    emoji: '🥚',
    category: 'Protein'
  },
  {
    canonicalName: 'Chicken Curry',
    aliases: ['chicken curry', 'chicken gravy', 'murgh curry'],
    caloriesPer100g: 140,
    proteinPer100g: 14.5,
    carbsPer100g: 4.2,
    fatPer100g: 7.2,
    fiberPer100g: 1.2,
    sugarPer100g: 1.5,
    defaultServingGrams: 150,
    emoji: '🍗',
    category: 'Protein'
  },
  {
    canonicalName: 'Grilled Chicken Breast',
    aliases: ['grilled chicken', 'chicken breast', 'roast chicken'],
    caloriesPer100g: 165,
    proteinPer100g: 31.0,
    carbsPer100g: 0.0,
    fatPer100g: 3.6,
    fiberPer100g: 0.0,
    sugarPer100g: 0.0,
    defaultServingGrams: 120,
    emoji: '🍗',
    category: 'Protein'
  },
  {
    canonicalName: 'Fish Curry',
    aliases: ['fish curry', 'meen kulambu', 'meen curry'],
    caloriesPer100g: 125,
    proteinPer100g: 15.0,
    carbsPer100g: 3.5,
    fatPer100g: 5.5,
    fiberPer100g: 0.8,
    sugarPer100g: 1.0,
    defaultServingGrams: 150,
    emoji: '🐟',
    category: 'Protein'
  },

  // --- DAIRY & CONDIMENTS ---
  {
    canonicalName: 'Curd / Yogurt',
    aliases: ['curd', 'yogurt', 'dahi', 'plain curd', 'perugu'],
    caloriesPer100g: 61,
    proteinPer100g: 3.5,
    carbsPer100g: 4.7,
    fatPer100g: 3.3,
    fiberPer100g: 0.0,
    sugarPer100g: 4.7,
    defaultServingGrams: 100,
    emoji: '🥛',
    category: 'Dairy'
  },
  {
    canonicalName: 'Cucumber & Onion Raita',
    aliases: ['raita', 'cucumber raita', 'onion raita'],
    caloriesPer100g: 52,
    proteinPer100g: 2.8,
    carbsPer100g: 4.2,
    fatPer100g: 2.4,
    fiberPer100g: 0.8,
    sugarPer100g: 3.2,
    defaultServingGrams: 90,
    emoji: '🥣',
    category: 'Dairy'
  },
  {
    canonicalName: 'Coconut Chutney',
    aliases: ['coconut chutney', 'white chutney', 'thengai chutney'],
    caloriesPer100g: 210,
    proteinPer100g: 3.2,
    carbsPer100g: 7.5,
    fatPer100g: 18.5,
    fiberPer100g: 3.8,
    sugarPer100g: 2.5,
    defaultServingGrams: 40,
    emoji: '🍵',
    category: 'Condiments'
  },
  {
    canonicalName: 'Tomato Chutney',
    aliases: ['tomato chutney', 'kara chutney', 'red chutney'],
    caloriesPer100g: 85,
    proteinPer100g: 1.8,
    carbsPer100g: 11.2,
    fatPer100g: 3.8,
    fiberPer100g: 2.2,
    sugarPer100g: 5.2,
    defaultServingGrams: 40,
    emoji: '🍵',
    category: 'Condiments'
  },
  {
    canonicalName: 'Medu Vada',
    aliases: ['vada', 'medu vada', 'ulundu vadai'],
    caloriesPer100g: 265,
    proteinPer100g: 8.5,
    carbsPer100g: 28.0,
    fatPer100g: 13.0,
    fiberPer100g: 4.2,
    sugarPer100g: 0.5,
    defaultServingGrams: 50,
    emoji: '🥯',
    category: 'Snacks'
  },
  {
    canonicalName: 'Papad / Papadum',
    aliases: ['papad', 'appalam', 'papadum'],
    caloriesPer100g: 295,
    proteinPer100g: 21.0,
    carbsPer100g: 48.0,
    fatPer100g: 2.0,
    fiberPer100g: 12.0,
    sugarPer100g: 1.0,
    defaultServingGrams: 15,
    emoji: '🍘',
    category: 'Snacks'
  },

  // --- FRUITS & NUTS ---
  {
    canonicalName: 'Sliced Banana',
    aliases: ['banana', 'sliced banana'],
    caloriesPer100g: 89,
    proteinPer100g: 1.1,
    carbsPer100g: 22.8,
    fatPer100g: 0.3,
    fiberPer100g: 2.6,
    sugarPer100g: 12.2,
    defaultServingGrams: 110,
    emoji: '🍌',
    category: 'Fruits'
  },
  {
    canonicalName: 'Fresh Apple',
    aliases: ['apple', 'sliced apple'],
    caloriesPer100g: 52,
    proteinPer100g: 0.3,
    carbsPer100g: 13.8,
    fatPer100g: 0.2,
    fiberPer100g: 2.4,
    sugarPer100g: 10.4,
    defaultServingGrams: 120,
    emoji: '🍎',
    category: 'Fruits'
  },
  {
    canonicalName: 'Almonds & Nuts',
    aliases: ['almonds', 'nuts', 'mixed nuts', 'chia seeds'],
    caloriesPer100g: 579,
    proteinPer100g: 21.2,
    carbsPer100g: 21.6,
    fatPer100g: 49.9,
    fiberPer100g: 12.5,
    sugarPer100g: 4.4,
    defaultServingGrams: 20,
    emoji: '🥜',
    category: 'Nuts'
  }
];

const DEFAULT_FALLBACK = {
  canonicalName: 'Cooked meal portion',
  aliases: ['cooked dish', 'dish', 'portion'],
  caloriesPer100g: 120,
  proteinPer100g: 4.5,
  carbsPer100g: 15.0,
  fatPer100g: 4.5,
  fiberPer100g: 2.5,
  sugarPer100g: 2.0,
  defaultServingGrams: 120,
  emoji: '🍽️',
  category: 'General',
  isCooked: true
};

FOOD_DATABASE.forEach(item => {
  if (item.isCooked === undefined) item.isCooked = true;
});

function findFoodMatch(foodName) {
  if (!foodName) return DEFAULT_FALLBACK;
  const clean = foodName.trim().toLowerCase();

  for (const entry of FOOD_DATABASE) {
    if (entry.canonicalName.toLowerCase() === clean) return entry;
    for (const a of entry.aliases) {
      if (a.toLowerCase() === clean) return entry;
    }
  }

  for (const entry of FOOD_DATABASE) {
    for (const a of entry.aliases) {
      if (clean.includes(a) || a.includes(clean)) {
        return entry;
      }
    }
  }

  const tokens = clean.split(/\s+/);
  for (const token of tokens) {
    if (token.length <= 2) continue;
    for (const entry of FOOD_DATABASE) {
      for (const a of entry.aliases) {
        if (a.includes(token)) return entry;
      }
    }
  }

  return DEFAULT_FALLBACK;
}

/**
 * Calculates nutrients for a food item given its name and portion in grams.
 * Formula: nutrient = (nutrientPer100g * grams) / 100
 */
function calculateItemNutrients(item) {
  const match = findFoodMatch(item.name);
  const grams = parseFloat(item.estimatedGrams) || match.defaultServingGrams;
  const ratio = grams / 100.0;

  const calories = Math.round(match.caloriesPer100g * ratio);
  const protein = parseFloat((match.proteinPer100g * ratio).toFixed(1));
  const carbs = parseFloat((match.carbsPer100g * ratio).toFixed(1));
  const fat = parseFloat((match.fatPer100g * ratio).toFixed(1));
  const fiber = parseFloat((match.fiberPer100g * ratio).toFixed(1));
  const sugar = parseFloat((match.sugarPer100g * ratio).toFixed(1));

  return {
    name: item.name || match.canonicalName,
    quantity: `${Math.round(grams)} g`,
    calories,
    protein,
    carbs,
    fat,
    fiber,
    sugar,
    emoji: match.emoji,
    confidence: typeof item.confidence === 'number' ? item.confidence : 0.85,
    estimatedGrams: grams,
    portionIsEstimated: true,
    alternatives: Array.isArray(item.alternatives) ? item.alternatives : [],
    notes: item.notes || null
  };
}

/**
 * Computes meal summary and approximate balance indicator.
 */
function calculateMealNutrition(items) {
  const calculatedFoods = items.map(calculateItemNutrients);

  let calories = 0;
  let protein = 0;
  let carbs = 0;
  let fat = 0;
  let fiber = 0;
  let sugar = 0;

  for (const f of calculatedFoods) {
    calories += f.calories;
    protein += f.protein;
    carbs += f.carbs;
    fat += f.fat;
    fiber += f.fiber;
    sugar += f.sugar;
  }

  const total = {
    calories: Math.round(calories),
    protein: parseFloat(protein.toFixed(1)),
    carbs: parseFloat(carbs.toFixed(1)),
    fat: parseFloat(fat.toFixed(1)),
    fiber: parseFloat(fiber.toFixed(1)),
    sugar: parseFloat(sugar.toFixed(1))
  };

  // Approximate balance indicator
  let score = 65;
  if (total.protein >= 18) score += 12;
  if (total.fiber >= 6) score += 13;
  if (total.fat > 25) score -= 6;
  if (total.sugar > 20) score -= 8;
  score = Math.max(40, Math.min(95, score));

  const status = score >= 80 ? 'Well Balanced!' : (score >= 65 ? 'Good Balance!' : 'Needs Balance');
  let tip = 'Try pairing with a serving of leafy greens or fresh salad for more fiber.';
  if (total.protein < 15) {
    tip = 'Consider adding more lentils, eggs, paneer, or tofu to increase protein.';
  } else if (total.fiber < 5) {
    tip = 'Adding raw salad or steamed greens will boost your meal’s dietary fiber.';
  }

  const balance = {
    score,
    status,
    description: 'Your meal brings together wholesome energy and nutrients.',
    tip,
    amudhuNote: 'Approximate nutritional balance indicator based on detected foods and portions. Not a medical assessment.'
  };

  return {
    foods: calculatedFoods,
    total,
    nutrition: total,
    balance
  };
}

module.exports = {
  FOOD_DATABASE,
  findFoodMatch,
  calculateItemNutrients,
  calculateMealNutrition
};
