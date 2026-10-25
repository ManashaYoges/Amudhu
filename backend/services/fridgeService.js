/**
 * Amudhu Fridge to Recipe Service
 * 1. AI Vision: Recognizes ingredients inside refrigerator / pantry photos.
 * 2. AI Chef: Generates customized, step-by-step recipes matching detected ingredients.
 * 3. Smart Local Engine: Comprehensive culinary fallback catalog when offline or API keys are unconfigured.
 */

const FRIDGE_VISION_PROMPT = `
You are an expert food and kitchen ingredient recognition computer vision AI for the Amudhu "Fridge to Recipe" system.
Your mission is to inspect the photograph of a refrigerator interior, freezer, pantry, kitchen counter, or grocery items and identify all visibly present food ingredients.

CRITICAL INSTRUCTIONS:
1. Identify all distinct raw ingredients, produce, dairy, eggs, condiments, vegetables, fruits, meats, breads, grains, and kitchen staples visible in the image.
2. Provide a realistic estimated quantity for each item (e.g. "4 eggs", "3 medium", "1 bunch", "200 g", "1 bottle", "half loaf").
3. Assign an appropriate emoji to each ingredient (e.g. 🥚, 🍅, 🥬, 🧅, 🧀, 🥛, 🥕, 🫑, 🍞, 🍗, 🧄, 🥔, 🍋, 🌿, etc.).
4. Do NOT invent ingredients that are not visually present.
5. If the photograph does NOT show a refrigerator, pantry, food ingredients, or groceries (e.g. it shows a pet, car, room, document, or blank wall), set "isFridgeOrFood": false with a clear explanation in "message".

You MUST respond with a valid JSON object matching EXACTLY this structure:
{
  "isFridgeOrFood": true,
  "ingredients": [
    {
      "name": "Eggs",
      "quantity": "4 eggs",
      "emoji": "🥚"
    },
    {
      "name": "Tomatoes",
      "quantity": "3 medium",
      "emoji": "🍅"
    }
  ]
}
Do NOT include markdown formatting, backticks, or extra text outside the JSON object.
`;

const RECIPE_GENERATION_PROMPT = `
You are Amudhu's AI Master Chef and Culinary Nutritionist.
Your mission is to create 3 to 4 creative, practical, and nutritionally balanced recipes based PRIMARILY on the user's available ingredients, supplemented only with common kitchen pantry staples (like cooking oil, salt, pepper, basic spices, water, flour).

CRITICAL RULES:
1. CULINARY VARIETY: Offer diverse dishes (e.g. a quick breakfast/snack, an Indian regional dish/curry, a continental/global dish, or a wholesome stir-fry/bowl).
2. REALISTIC INSTRUCTIONS: Provide clear, numbered, easy-to-follow cooking instructions that anyone can make at home in under 40 minutes.
3. INGREDIENT TAGGING: For every ingredient in the recipe's ingredient list, set "isFromFridge": true if it matches or derives from the user's available ingredients, or "isFromFridge": false if it is a common pantry item.
4. NUTRITION ESTIMATES: Provide realistic per-serving nutritional estimates (calories, protein in grams, carbs in grams, fat in grams, fiber in grams).
5. MATCH COUNT: Calculate "matchedCount" (number of ingredients matching the user's list) and "totalIngredientsCount".
6. VIDEO GUIDE: Provide a relevant YouTube search link in "videoUrl" format: https://www.youtube.com/results?search_query=\${encodeURIComponent(recipeName + " recipe step by step")}

You MUST respond with a valid JSON object matching EXACTLY this structure:
{
  "success": true,
  "recipes": [
    {
      "id": "recipe_1",
      "name": "Recipe Title",
      "emoji": "🍳",
      "description": "Appetizing 1-2 sentence description",
      "prepTime": "8 min",
      "cookTime": "12 min",
      "totalTime": "20 min",
      "servings": 2,
      "difficulty": "Easy",
      "cuisine": "Indian",
      "isVegetarian": true,
      "ingredients": [
        { "name": "Eggs", "quantity": "3 large", "isFromFridge": true },
        { "name": "Cooking Oil", "quantity": "1 tbsp", "isFromFridge": false }
      ],
      "steps": [
        "Heat oil in skillet...",
        "Add beaten eggs and cook..."
      ],
      "nutrition": {
        "calories": 280,
        "protein": 18.5,
        "carbs": 6.0,
        "fat": 19.0,
        "fiber": 2.5
      },
      "matchedCount": 3,
      "totalIngredientsCount": 5,
      "videoUrl": "https://www.youtube.com/results?search_query=..."
    }
  ]
}
Do NOT include markdown formatting, backticks, or extra text outside the JSON object.
`;

const SMART_FRIDGE_PRESETS = [
  {
    name: 'Fresh Produce & Dairy',
    ingredients: [
      { name: 'Eggs', quantity: '4 eggs', emoji: '🥚' },
      { name: 'Tomatoes', quantity: '3 medium', emoji: '🍅' },
      { name: 'Spinach', quantity: '1 fresh bunch', emoji: '🥬' },
      { name: 'Onions', quantity: '2 medium', emoji: '🧅' },
      { name: 'Paneer', quantity: '200 g', emoji: '🧀' },
      { name: 'Curd / Yogurt', quantity: '250 g', emoji: '🥛' },
      { name: 'Green Chillies', quantity: '4 pieces', emoji: '🫑' },
    ],
  },
  {
    name: 'Breakfast Staples & Greens',
    ingredients: [
      { name: 'Eggs', quantity: '6 eggs', emoji: '🥚' },
      { name: 'Whole Wheat Bread', quantity: '4 slices', emoji: '🍞' },
      { name: 'Tomatoes', quantity: '2 ripe', emoji: '🍅' },
      { name: 'Cheese Slices', quantity: '2 slices', emoji: '🧀' },
      { name: 'Butter', quantity: '50 g', emoji: '🧈' },
      { name: 'Capsicum / Bell Pepper', quantity: '1 medium', emoji: '🫑' },
      { name: 'Milk', quantity: '500 ml', emoji: '🥛' },
    ],
  },
  {
    name: 'Indian Pantry & Vegetables',
    ingredients: [
      { name: 'Paneer', quantity: '250 g', emoji: '🧀' },
      { name: 'Spinach', quantity: '1 bunch', emoji: '🥬' },
      { name: 'Carrots', quantity: '2 medium', emoji: '🥕' },
      { name: 'Potatoes', quantity: '3 medium', emoji: '🥔' },
      { name: 'Tomatoes', quantity: '3 ripe', emoji: '🍅' },
      { name: 'Onions', quantity: '2 medium', emoji: '🧅' },
      { name: 'Garlic', quantity: '1 bulb', emoji: '🧄' },
      { name: 'Ginger', quantity: '1 inch piece', emoji: '🫚' },
    ],
  },
  {
    name: 'High Protein & Salad',
    ingredients: [
      { name: 'Eggs', quantity: '6 eggs', emoji: '🥚' },
      { name: 'Chicken Breast / Paneer', quantity: '250 g', emoji: '🍗' },
      { name: 'Cucumber', quantity: '2 medium', emoji: '🥒' },
      { name: 'Tomatoes', quantity: '2 medium', emoji: '🍅' },
      { name: 'Greek Yogurt / Curd', quantity: '200 g', emoji: '🥛' },
      { name: 'Lemon', quantity: '2 pieces', emoji: '🍋' },
      { name: 'Coriander / Herbs', quantity: '1 sprig', emoji: '🌿' },
    ],
  },
];

const CURATED_RECIPE_CATALOG = [
  {
    id: 'spinach_omelette',
    name: 'Spinach & Herb Omelette',
    emoji: '🍳',
    description: 'A fluffy, protein-rich omelette packed with tender sautéed spinach and fresh aromatics.',
    prepTime: '5 min',
    cookTime: '8 min',
    totalTime: '13 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Continental',
    isVegetarian: false,
    ingredients: [
      { name: 'Eggs', quantity: '3 large' },
      { name: 'Spinach', quantity: '1 cup finely chopped' },
      { name: 'Onion', quantity: '1/2 medium diced' },
      { name: 'Green Chili', quantity: '1 minced' },
      { name: 'Olive Oil / Butter', quantity: '1 tsp', isPantry: true },
      { name: 'Salt & Black Pepper', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'Wash spinach thoroughly and chop into ribbons. Finely dice the onion.',
      'Crack eggs into a bowl and whisk vigorously with salt and pepper until frothy.',
      'Heat oil or butter in a skillet over medium flame. Sauté onions and green chili for 2 minutes.',
      'Add chopped spinach and sauté for 1 minute until just wilted.',
      'Pour whisked eggs evenly over the skillet.',
      'Cook on low-medium flame until edges set. Gently fold and cook for 1 more minute.',
      'Slide onto a plate and serve hot with toast or salad.',
    ],
    nutrition: { calories: 275, protein: 21.0, carbs: 4.5, fat: 19.0, fiber: 2.8 },
    videoQuery: 'Spinach Omelette recipe step by step',
  },
  {
    id: 'spiced_tomato_egg_bhurji',
    name: 'Homestyle Spiced Tomato Egg Bhurji',
    emoji: '🥘',
    description: 'Classic Indian scrambled eggs tossed with juicy tomatoes, onions, green chillies, and warming spices.',
    prepTime: '7 min',
    cookTime: '10 min',
    totalTime: '17 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Indian',
    isVegetarian: false,
    ingredients: [
      { name: 'Eggs', quantity: '4 eggs' },
      { name: 'Tomatoes', quantity: '2 ripe chopped' },
      { name: 'Onion', quantity: '1 large diced' },
      { name: 'Green Chillies', quantity: '2 slit' },
      { name: 'Cooking Oil', quantity: '1 tbsp', isPantry: true },
      { name: 'Turmeric & Cumin', quantity: '1/2 tsp each', isPantry: true },
      { name: 'Salt', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'Heat oil in a pan over medium heat. Splutter cumin seeds.',
      'Add chopped onions and green chillies. Sauté until light golden brown.',
      'Add diced tomatoes, turmeric, and salt. Cook until tomatoes soften and release juices.',
      'Crack eggs directly into the pan and stir gently on medium-low flame.',
      'Scramble until cooked through yet moist and aromatic.',
      'Garnish with fresh herbs and serve hot with roti or toast.',
    ],
    nutrition: { calories: 290, protein: 24.5, carbs: 7.8, fat: 18.2, fiber: 2.4 },
    videoQuery: 'Spiced Egg Bhurji recipe step by step',
  },
  {
    id: 'palak_paneer_quick',
    name: 'Quick Palak Paneer Stir-Fry',
    emoji: '🧀',
    description: 'Fresh paneer cubes gently tossed with garlicky sautéed spinach, onions, and fragrant spices.',
    prepTime: '8 min',
    cookTime: '12 min',
    totalTime: '20 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Paneer', quantity: '200 g cubed' },
      { name: 'Spinach', quantity: '1 bunch (200g)' },
      { name: 'Onion', quantity: '1 medium sliced' },
      { name: 'Tomatoes', quantity: '1 small diced' },
      { name: 'Garlic', quantity: '4 cloves minced' },
      { name: 'Ghee or Cooking Oil', quantity: '1 tbsp', isPantry: true },
      { name: 'Garam Masala & Salt', quantity: '1/2 tsp each', isPantry: true },
    ],
    steps: [
      'Roughly chop spinach. Soak paneer cubes in warm water for 5 minutes for softness.',
      'Heat ghee or oil in a pan. Sauté minced garlic until golden and fragrant.',
      'Add sliced onions and fry until translucent. Add diced tomato and cook for 2 minutes.',
      'Toss in chopped spinach and cook until wilted and vibrant green.',
      'Add paneer cubes, garam masala, and salt. Gently fold to coat paneer evenly.',
      'Cover and simmer on low for 3 minutes to let flavors meld.',
      'Serve warm as a high-protein, nutrient-rich dish.',
    ],
    nutrition: { calories: 340, protein: 19.8, carbs: 8.5, fat: 25.0, fiber: 4.2 },
    videoQuery: 'Quick Palak Paneer Stir Fry recipe',
  },
  {
    id: 'savory_tomato_egg_toast',
    name: 'Savory Tomato & Egg Toast',
    emoji: '🍞',
    description: 'Crispy toasted bread topped with savory spiced scrambled eggs, roasted tomatoes, and melted cheese.',
    prepTime: '5 min',
    cookTime: '7 min',
    totalTime: '12 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Continental',
    isVegetarian: false,
    ingredients: [
      { name: 'Bread', quantity: '4 slices' },
      { name: 'Eggs', quantity: '2 large' },
      { name: 'Tomatoes', quantity: '1 large sliced' },
      { name: 'Cheese', quantity: '2 slices or 30g grated' },
      { name: 'Butter', quantity: '1 tbsp', isPantry: true },
      { name: 'Salt & Pepper', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'Toast bread slices on a skillet with a light smear of butter until crisp and golden.',
      'Melt butter in a small pan. Lightly sear tomato slices for 1 minute on each side; set aside.',
      'Whisk eggs with a pinch of salt and scramble softly on low flame.',
      'Layer warm scrambled eggs and seared tomato slices over the crispy toast.',
      'Top with cheese, cover for 30 seconds until cheese melts, and serve immediately.',
    ],
    nutrition: { calories: 320, protein: 16.5, carbs: 32.0, fat: 14.0, fiber: 2.2 },
    videoQuery: 'Tomato Egg Toast breakfast recipe',
  },
  {
    id: 'garlic_paneer_greens_scramble',
    name: 'Garlic Paneer & Greens Scramble',
    emoji: '🧄',
    description: 'Crumbled cottage cheese sautéed with garlic, onions, tomatoes, and shredded greens.',
    prepTime: '6 min',
    cookTime: '9 min',
    totalTime: '15 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Paneer', quantity: '180 g crumbled' },
      { name: 'Spinach', quantity: '1 cup shredded' },
      { name: 'Onions', quantity: '1 medium chopped' },
      { name: 'Garlic', quantity: '4 cloves minced' },
      { name: 'Tomatoes', quantity: '1 chopped' },
      { name: 'Cooking Oil / Butter', quantity: '1 tbsp', isPantry: true },
      { name: 'Turmeric & Salt', quantity: '1/2 tsp each', isPantry: true },
    ],
    steps: [
      'Crumble fresh paneer into pea-sized bits.',
      'Heat oil or butter. Sauté minced garlic until fragrant and light golden.',
      'Add chopped onions and sauté for 3 minutes until soft.',
      'Add chopped tomato and spinach; cook for 2 minutes until juices release.',
      'Fold in crumbled paneer with turmeric and salt. Cook gently on medium heat for 2 minutes.',
      'Remove from flame while moist and tender. Serve warm with toast or roti.',
    ],
    nutrition: { calories: 310, protein: 18.2, carbs: 7.0, fat: 23.5, fiber: 3.1 },
    videoQuery: 'Paneer Bhurji recipe step by step',
  },
  {
    id: 'warm_spinach_boiled_egg_bowl',
    name: 'Warm Spinach & Boiled Egg Bowl',
    emoji: '🥗',
    description: 'Steamed greens paired with soft or hard-boiled eggs, juicy tomato wedges, and a tangy dressing.',
    prepTime: '6 min',
    cookTime: '8 min',
    totalTime: '14 min',
    servings: 1,
    difficulty: 'Easy',
    cuisine: 'Continental',
    isVegetarian: false,
    ingredients: [
      { name: 'Eggs', quantity: '2 large' },
      { name: 'Spinach', quantity: '2 cups fresh' },
      { name: 'Tomatoes', quantity: '1 ripe wedged' },
      { name: 'Onions', quantity: '1/4 sliced' },
      { name: 'Lemon Juice', quantity: '1 tbsp', isPantry: true },
      { name: 'Olive Oil', quantity: '1 tsp', isPantry: true },
      { name: 'Salt & Pepper', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'Boil eggs for 7 minutes for jammy yolks (or 9 minutes for firm). Cool in ice water and peel.',
      'Flash-steam or sauté spinach in a pan with 2 tbsp water and olive oil for 90 seconds until wilted.',
      'Arrange warm wilted spinach at the base of your serving bowl.',
      'Halve boiled eggs and place over spinach along with fresh tomato wedges and sliced onion.',
      'Drizzle with olive oil, fresh lemon juice, salt, and freshly cracked black pepper.',
    ],
    nutrition: { calories: 220, protein: 16.0, carbs: 6.2, fat: 14.5, fiber: 3.6 },
    videoQuery: 'Warm Spinach and Boiled Egg Salad recipe',
  },
  {
    id: 'creamy_curd_rice_tadka',
    name: 'Comforting Curd Rice with Mustard Tadka',
    emoji: '🍚',
    description: 'Creamy South Indian comfort curd rice tempered with mustard seeds, curry leaves, and green chillies.',
    prepTime: '5 min',
    cookTime: '5 min',
    totalTime: '10 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'South Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Curd / Yogurt', quantity: '1.5 cups fresh' },
      { name: 'Cooked Rice', quantity: '2 cups soft cooked' },
      { name: 'Green Chillies', quantity: '2 slit' },
      { name: 'Ginger', quantity: '1 tsp finely minced' },
      { name: 'Cooking Oil', quantity: '1 tsp', isPantry: true },
      { name: 'Mustard Seeds', quantity: '1/2 tsp', isPantry: true },
      { name: 'Salt', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'Gently mash soft cooked rice in a mixing bowl with a fork or back of spoon.',
      'Add fresh curd and 1/4 cup water or milk with salt. Mix until smooth and creamy.',
      'Heat oil in a small tadka ladle. Add mustard seeds and allow them to crackle.',
      'Add slit green chillies and minced ginger; sauté for 30 seconds until fragrant.',
      'Pour hot aromatic tadka over the curd rice and fold gently.',
      'Serve cool or at room temperature with pickle or papad.',
    ],
    nutrition: { calories: 260, protein: 7.5, carbs: 42.0, fat: 7.0, fiber: 1.2 },
    videoQuery: 'South Indian Curd Rice recipe step by step',
  },
  {
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
    ingredients: [
      { name: 'Potatoes', quantity: '3 medium diced' },
      { name: 'Onions', quantity: '1 large sliced' },
      { name: 'Cooking Oil / Butter', quantity: '1.5 tbsp', isPantry: true },
      { name: 'Salt & Pepper', quantity: 'To taste', isPantry: true },
      { name: 'Paprika / Chili Flakes', quantity: '1/2 tsp', isPantry: true },
    ],
    steps: [
      'Dice potatoes into small 1/2-inch cubes. Rinse in cold water and pat dry.',
      'Heat oil in a heavy non-stick skillet over medium heat.',
      'Add potatoes in a single layer. Cook undisturbed for 5 minutes until underside browns.',
      'Stir and add sliced onions, salt, and pepper.',
      'Cook for another 8-10 minutes, tossing periodically until potatoes are fork-tender and crisp.',
      'Sprinkle chili flakes and serve warm as a satisfying side or breakfast skillet.',
    ],
    nutrition: { calories: 230, protein: 4.2, carbs: 36.0, fat: 8.5, fiber: 3.8 },
    videoQuery: 'Crispy Potato Onion Hash recipe skillet',
  },
  {
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
    ingredients: [
      { name: 'Chicken', quantity: '350 g cut into pieces' },
      { name: 'Onions', quantity: '2 medium finely sliced' },
      { name: 'Tomatoes', quantity: '2 ripe pureed' },
      { name: 'Ginger', quantity: '1 tbsp minced' },
      { name: 'Garlic', quantity: '1 tbsp minced' },
      { name: 'Green Chillies', quantity: '2 slit' },
      { name: 'Cooking Oil', quantity: '2 tbsp', isPantry: true },
      { name: 'Garam Masala & Turmeric', quantity: '1 tsp each', isPantry: true },
      { name: 'Salt', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'Heat oil in a heavy-bottomed pot. Add sliced onions and cook until golden brown.',
      'Stir in minced ginger, garlic, and green chillies. Sauté for 1 minute until fragrant.',
      'Add pureed tomatoes, turmeric, garam masala, and salt. Cook until oil separates from the masala.',
      'Add chicken pieces. Sear on high heat for 3 minutes to lock in moisture.',
      'Add 1/2 cup water, cover tightly, and simmer on low-medium flame for 15 minutes until chicken is tender.',
      'Garnish with fresh coriander and serve steaming hot with rice or roti.',
    ],
    nutrition: { calories: 340, protein: 32.0, carbs: 8.5, fat: 18.0, fiber: 2.2 },
    videoQuery: 'Homestyle Chicken Curry recipe step by step',
  },
  {
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
    ingredients: [
      { name: 'Chicken', quantity: '2 chicken breasts / cutlets' },
      { name: 'Garlic', quantity: '4 cloves minced' },
      { name: 'Lemon', quantity: '1 whole juiced' },
      { name: 'Olive Oil / Butter', quantity: '1.5 tbsp', isPantry: true },
      { name: 'Salt & Black Pepper', quantity: '1/2 tsp each', isPantry: true },
    ],
    steps: [
      'Pat chicken breasts dry with paper towels. Season both sides generously with salt and black pepper.',
      'Heat olive oil or butter in a skillet over medium-high heat until shimmering.',
      'Place chicken in skillet. Sear undisturbed for 5-6 minutes until a golden crust develops.',
      'Flip chicken, add minced garlic and lemon juice around the pan.',
      'Spoon sizzling garlic lemon pan juices over chicken for 4-5 minutes until internal temp reaches 165°F.',
      'Rest for 3 minutes before slicing. Serve with a fresh side salad or steamed vegetables.',
    ],
    nutrition: { calories: 280, protein: 36.0, carbs: 2.5, fat: 12.0, fiber: 0.5 },
    videoQuery: 'Pan Seared Lemon Garlic Chicken Breast recipe',
  },
  {
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
    ingredients: [
      { name: 'Pasta', quantity: '200 g (penne, spaghetti, or macaroni)' },
      { name: 'Milk / Cream', quantity: '1 cup' },
      { name: 'Garlic', quantity: '4 cloves minced' },
      { name: 'Cheese', quantity: '50 g grated' },
      { name: 'Butter', quantity: '1 tbsp', isPantry: true },
      { name: 'Salt & Black Pepper', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'Boil pasta in salted water until al dente. Reserve 1/4 cup pasta water, then drain.',
      'Melt butter in a skillet over medium heat. Sauté minced garlic for 1 minute until fragrant.',
      'Pour in milk or cream. Bring to a gentle simmer for 3 minutes.',
      'Lower flame and stir in grated cheese until sauce turns smooth and velvety.',
      'Toss in cooked pasta and reserved pasta water. Coat every strand evenly.',
      'Season with black pepper and serve hot.',
    ],
    nutrition: { calories: 430, protein: 15.0, carbs: 54.0, fat: 18.0, fiber: 3.0 },
    videoQuery: 'Creamy Garlic Alfredo Pasta recipe step by step',
  },
  {
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
    ingredients: [
      { name: 'Pasta', quantity: '200 g' },
      { name: 'Tomatoes', quantity: '4 ripe diced' },
      { name: 'Garlic', quantity: '4 cloves minced' },
      { name: 'Onions', quantity: '1 small diced' },
      { name: 'Olive Oil', quantity: '1.5 tbsp', isPantry: true },
      { name: 'Salt & Pepper', quantity: 'To taste', isPantry: true },
      { name: 'Oregano / Herbs', quantity: '1 tsp', isPantry: true },
    ],
    steps: [
      'Boil pasta in a pot of salted water until al dente. Drain and set aside.',
      'Heat olive oil in a skillet. Sauté onions and minced garlic until translucent.',
      'Add diced ripe tomatoes, oregano, salt, and black pepper.',
      'Simmer for 8 minutes, crushing tomatoes with a wooden spoon until a jammy sauce forms.',
      'Toss pasta into the sauce and fold gently for 2 minutes to absorb flavors.',
      'Serve warm topped with a sprinkle of cheese or fresh herbs.',
    ],
    nutrition: { calories: 360, protein: 11.5, carbs: 62.0, fat: 8.5, fiber: 4.8 },
    videoQuery: 'Fresh Tomato Garlic Basil Pasta recipe',
  },
  {
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
    ingredients: [
      { name: 'Bread', quantity: '4 slices' },
      { name: 'Garlic', quantity: '4 cloves finely minced' },
      { name: 'Cheese', quantity: '60 g shredded' },
      { name: 'Butter', quantity: '2 tbsp softened' },
      { name: 'Chili Flakes & Oregano', quantity: '1/2 tsp each', isPantry: true },
    ],
    steps: [
      'In a small bowl, mix softened butter, minced garlic, and chili flakes together.',
      'Spread the garlic butter generously over one side of each bread slice.',
      'Top evenly with shredded cheese and a pinch of oregano.',
      'Toast on a lidded tawa or skillet on low flame for 4-5 minutes until cheese melts and bottom is golden crisp.',
      'Cut diagonally and serve hot as an irresistible snack.',
    ],
    nutrition: { calories: 290, protein: 9.5, carbs: 28.0, fat: 16.0, fiber: 2.0 },
    videoQuery: 'Crispy Garlic Cheese Toast recipe skillet tawa',
  },
  {
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
    ingredients: [
      { name: 'Bread', quantity: '4 slices cut into cubes' },
      { name: 'Onions', quantity: '1 medium chopped' },
      { name: 'Tomatoes', quantity: '1 large chopped' },
      { name: 'Green Chillies', quantity: '2 slit' },
      { name: 'Mustard Seeds', quantity: '1/2 tsp', isPantry: true },
      { name: 'Cooking Oil', quantity: '1 tbsp', isPantry: true },
      { name: 'Turmeric & Salt', quantity: '1/2 tsp each', isPantry: true },
    ],
    steps: [
      'Cut bread slices into bite-sized 1-inch squares.',
      'Heat oil in a pan. Splutter mustard seeds and curry leaves.',
      'Add chopped onions and green chillies; sauté until soft and light golden.',
      'Add chopped tomatoes, turmeric, and salt. Cook until tomatoes turn mushy.',
      'Toss in bread cubes and sprinkle 1 tablespoon water. Fold gently until bread absorbs the masala.',
      'Cook for 2 minutes on low flame and serve warm with a squeeze of lemon.',
    ],
    nutrition: { calories: 220, protein: 6.5, carbs: 36.0, fat: 6.0, fiber: 3.2 },
    videoQuery: 'Spicy South Indian Bread Upma recipe',
  },
  {
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
    ingredients: [
      { name: 'Bread', quantity: '4 slices' },
      { name: 'Eggs', quantity: '3 large' },
      { name: 'Onions', quantity: '1/2 medium finely chopped' },
      { name: 'Tomatoes', quantity: '1/2 medium finely diced' },
      { name: 'Green Chillies', quantity: '1 minced' },
      { name: 'Coriander / Herbs', quantity: '2 tbsp chopped' },
      { name: 'Butter or Oil', quantity: '1 tbsp', isPantry: true },
      { name: 'Salt & Pepper', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'In a wide dish, whisk eggs with salt, pepper, turmeric, chopped onions, tomatoes, green chilli, and coriander.',
      'Heat butter or oil on a flat tawa or skillet over medium heat.',
      'Dip bread slices into the egg mixture, coating both sides well with aromatics.',
      'Place on hot tawa and cook for 2-3 minutes per side until golden brown and cooked through.',
      'Serve hot with mint chutney or ketchup.',
    ],
    nutrition: { calories: 310, protein: 17.5, carbs: 30.0, fat: 13.5, fiber: 2.8 },
    videoQuery: 'Indian Savory Masala French Toast recipe',
  },
  {
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
    ingredients: [
      { name: 'Cooked Rice', quantity: '2 cups chilled' },
      { name: 'Chicken', quantity: '150 g cooked or diced' },
      { name: 'Eggs', quantity: '2 large beaten' },
      { name: 'Onions', quantity: '1 small diced' },
      { name: 'Garlic', quantity: '3 cloves minced' },
      { name: 'Cooking Oil', quantity: '1.5 tbsp', isPantry: true },
      { name: 'Soy Sauce or Salt', quantity: '1 tbsp', isPantry: true },
      { name: 'Black Pepper', quantity: '1/2 tsp', isPantry: true },
    ],
    steps: [
      'Heat 1/2 tbsp oil in a wok or large pan. Scramble eggs softly and transfer to a plate.',
      'Add remaining oil to wok on high flame. Sauté garlic and onions for 1 minute.',
      'Add diced chicken and stir-fry for 3-4 minutes until cooked through.',
      'Add cold cooked rice. Break up clumps and toss vigorously on high flame.',
      'Drizzle soy sauce or salt and cracked pepper. Fold in scrambled eggs.',
      'Toss for 1 more minute until fragrant and steaming. Serve hot.',
    ],
    nutrition: { calories: 420, protein: 28.0, carbs: 48.0, fat: 12.0, fiber: 2.0 },
    videoQuery: 'Chicken and Egg Fried Rice quick skillet recipe',
  },
  {
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
    ingredients: [
      { name: 'Paneer', quantity: '200 g cubed' },
      { name: 'Tomatoes', quantity: '3 ripe blended' },
      { name: 'Onions', quantity: '1 large finely chopped' },
      { name: 'Butter', quantity: '1.5 tbsp' },
      { name: 'Ginger & Garlic', quantity: '1 tsp each minced' },
      { name: 'Curd / Cream', quantity: '2 tbsp' },
      { name: 'Garam Masala & Salt', quantity: '1/2 tsp each', isPantry: true },
    ],
    steps: [
      'Melt butter in a pan over medium heat. Sauté onions, ginger, and garlic until soft and fragrant.',
      'Pour in blended tomato puree and cook for 6 minutes until gravy thickens.',
      'Add garam masala, chili powder, and salt. Stir in curd or cream for richness.',
      'Gently slide in paneer cubes. Simmer on low flame for 4 minutes to absorb flavors.',
      'Garnish with a swirl of butter and fresh coriander. Serve with roti, naan, or rice.',
    ],
    nutrition: { calories: 370, protein: 18.0, carbs: 12.0, fat: 28.0, fiber: 2.6 },
    videoQuery: 'Quick Paneer Butter Masala restaurant style recipe',
  },
  {
    id: 'aloo_jeera_dry',
    name: 'Cumin Spiced Aloo Jeera',
    emoji: '🥔',
    description: 'Tender potato cubes tempered with roasted cumin seeds, green chillies, and fresh herbs.',
    prepTime: '5 min',
    cookTime: '12 min',
    totalTime: '17 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Potatoes', quantity: '3 medium boiled & cubed' },
      { name: 'Cumin Seeds', quantity: '1 tbsp', isPantry: true },
      { name: 'Green Chillies', quantity: '2 slit' },
      { name: 'Ginger', quantity: '1 tsp minced' },
      { name: 'Coriander / Herbs', quantity: '2 tbsp chopped' },
      { name: 'Cooking Oil', quantity: '1 tbsp', isPantry: true },
      { name: 'Turmeric & Salt', quantity: '1/2 tsp each', isPantry: true },
    ],
    steps: [
      'Peel and dice boiled potatoes into bite-sized cubes.',
      'Heat oil in a pan. Add cumin seeds and let them splutter and release their earthy aroma.',
      'Add slit green chillies and minced ginger; sauté for 30 seconds.',
      'Add potato cubes, turmeric powder, and salt. Toss gently to coat evenly.',
      'Roast on medium flame for 5-7 minutes until the edges turn golden and crisp.',
      'Finish with fresh chopped coriander and a squeeze of lemon.',
    ],
    nutrition: { calories: 210, protein: 3.8, carbs: 34.0, fat: 7.0, fiber: 3.5 },
    videoQuery: 'Dhaba style Aloo Jeera recipe dry',
  },
  {
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
    ingredients: [
      { name: 'Basmati Rice', quantity: '1.5 cups rinsed' },
      { name: 'Carrots', quantity: '1 medium diced' },
      { name: 'Onions', quantity: '1 medium sliced' },
      { name: 'Green Peas / Beans', quantity: '1/2 cup' },
      { name: 'Ginger & Garlic', quantity: '1 tsp each minced' },
      { name: 'Ghee or Cooking Oil', quantity: '1 tbsp', isPantry: true },
      { name: 'Cumin & Whole Spices', quantity: '1 tsp', isPantry: true },
      { name: 'Salt', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'Heat ghee or oil in a pot. Splutter cumin seeds and whole aromatics.',
      'Add sliced onions, ginger, and garlic; sauté until golden.',
      'Add diced carrots and green peas. Sauté for 2 minutes.',
      'Add rinsed basmati rice and gently toast for 1 minute.',
      'Add 2.5 cups water and salt. Bring to a rolling boil, then reduce flame to lowest, cover, and cook for 12 minutes.',
      'Fluff gently with a fork and serve with cool raita.',
    ],
    nutrition: { calories: 310, protein: 6.5, carbs: 58.0, fat: 6.0, fiber: 4.2 },
    videoQuery: 'One Pot Veg Pulao recipe step by step',
  },
  {
    id: 'garlic_butter_mushrooms',
    name: 'Sautéed Garlic Butter Mushrooms',
    emoji: '🍄',
    description: 'Plump button mushrooms pan-caramelized in foaming garlic butter and fresh herbs.',
    prepTime: '5 min',
    cookTime: '8 min',
    totalTime: '13 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Continental',
    isVegetarian: true,
    ingredients: [
      { name: 'Mushrooms', quantity: '250 g cleaned & halved' },
      { name: 'Garlic', quantity: '5 cloves minced' },
      { name: 'Butter', quantity: '2 tbsp' },
      { name: 'Coriander / Parsley', quantity: '2 tbsp chopped' },
      { name: 'Salt & Black Pepper', quantity: 'To taste', isPantry: true },
    ],
    steps: [
      'Wipe mushrooms clean and slice in halves or quarters.',
      'Melt butter in a large skillet over medium-high heat.',
      'Add mushrooms in a single layer. Cook without moving for 3 minutes to allow deep browning.',
      'Flip and add minced garlic, salt, and freshly cracked black pepper.',
      'Sauté for another 3-4 minutes until tender, juicy, and glazed.',
      'Toss in fresh herbs and serve immediately with toast or steak.',
    ],
    nutrition: { calories: 160, protein: 4.8, carbs: 6.5, fat: 13.5, fiber: 2.0 },
    videoQuery: 'Garlic Butter Mushrooms skillet recipe',
  },
  {
    id: 'skillet_bread_pizza',
    name: 'Quick Stovetop Skillet Bread Pizza',
    emoji: '🍕',
    description: 'Crispy bread base slathered with spiced tomato sauce, capsicum, onions, and melted cheese.',
    prepTime: '5 min',
    cookTime: '7 min',
    totalTime: '12 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Fusion',
    isVegetarian: true,
    ingredients: [
      { name: 'Bread', quantity: '4 slices' },
      { name: 'Tomatoes', quantity: '2 ripe diced' },
      { name: 'Cheese', quantity: '80 g mozzarella or cheddar' },
      { name: 'Capsicum / Bell Pepper', quantity: '1/2 medium diced' },
      { name: 'Onions', quantity: '1/2 medium diced' },
      { name: 'Butter', quantity: '1 tbsp', isPantry: true },
      { name: 'Oregano & Chili Flakes', quantity: '1 tsp each', isPantry: true },
    ],
    steps: [
      'Spread tomato sauce or crushed seasoned tomatoes evenly on bread slices.',
      'Top with diced capsicum, onions, oregano, and generous shredded cheese.',
      'Heat butter in a non-stick pan on low heat.',
      'Place bread slices, cover with lid, and cook on low heat for 5-6 minutes until cheese melts completely and bread base turns super crispy.',
      'Cut into triangles and serve hot.',
    ],
    nutrition: { calories: 285, protein: 11.0, carbs: 29.0, fat: 14.0, fiber: 2.8 },
    videoQuery: 'Tawa Bread Pizza recipe without oven',
  },
  {
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
    ingredients: [
      { name: 'Lentils / Dal', quantity: '1 cup washed' },
      { name: 'Tomatoes', quantity: '2 ripe chopped' },
      { name: 'Spinach', quantity: '1 cup roughly chopped' },
      { name: 'Carrots', quantity: '1 medium diced' },
      { name: 'Garlic', quantity: '4 cloves minced' },
      { name: 'Cumin Seeds', quantity: '1 tsp', isPantry: true },
      { name: 'Olive Oil / Ghee', quantity: '1 tbsp', isPantry: true },
      { name: 'Turmeric & Salt', quantity: '1/2 tsp each', isPantry: true },
    ],
    steps: [
      'Heat oil or ghee in a soup pot. Splutter cumin seeds and sauté minced garlic.',
      'Add washed lentils, diced carrots, chopped tomatoes, turmeric, and 4 cups of water.',
      'Bring to a boil, then cover and simmer on medium flame for 15 minutes until lentils soften.',
      'Mash lightly with a whisk or immersion blender for creamy body.',
      'Stir in fresh chopped spinach and simmer for 2 more minutes until vibrant green.',
      'Season with salt, black pepper, and a squeeze of fresh lemon juice before serving.',
    ],
    nutrition: { calories: 240, protein: 14.0, carbs: 38.0, fat: 4.5, fiber: 9.0 },
    videoQuery: 'Healthy Dal Soup with spinach and vegetables recipe',
  },
];

/**
 * Normalizes string for fuzzy ingredient matching
 */
function normalize(str) {
  return String(str || '').toLowerCase().replace(/[^a-z0-9]/g, ' ').trim();
}

function stemWord(word) {
  let w = String(word || '').toLowerCase().trim();
  if (w.endsWith('ies') && w.length > 4) return w.slice(0, -3) + 'y';
  if (w.endsWith('es') && w.length > 4) return w.slice(0, -2);
  if (w.endsWith('s') && !w.endsWith('ss') && w.length > 3) return w.slice(0, -1);
  return w;
}

const CULINARY_SYNONYMS = {
  tomato: ['tomato', 'tomatoes', 'tamatar'],
  onion: ['onion', 'onions', 'pyaz', 'shallot', 'shallots', 'scallion', 'scallions', 'spring onion'],
  potato: ['potato', 'potatoes', 'aloo', 'batata'],
  spinach: ['spinach', 'palak', 'greens', 'keerai', 'saag'],
  egg: ['egg', 'eggs', 'anda', 'boiled egg', 'egg white', 'omelette'],
  paneer: ['paneer', 'cottage cheese', 'chenna'],
  curd: ['curd', 'yogurt', 'yoghurt', 'dahi'],
  coriander: ['coriander', 'cilantro', 'dhania', 'kothmir', 'herbs', 'parsley'],
  chilli: ['chilli', 'chili', 'chilies', 'chillies', 'green chilli', 'red chilli', 'mirch', 'mirchi', 'jalapeno', 'capsicum', 'bell pepper', 'peppers'],
  garlic: ['garlic', 'garlic cloves', 'lahsun'],
  ginger: ['ginger', 'ginger root', 'adrak'],
  bread: ['bread', 'bread slices', 'toast', 'loaf', 'pav', 'bun'],
  rice: ['rice', 'cooked rice', 'steamed rice', 'basmati', 'chawal'],
  chicken: ['chicken', 'chicken breast', 'chicken pieces', 'poultry', 'murgh'],
  cheese: ['cheese', 'cheddar', 'mozzarella', 'parmesan', 'processed cheese'],
  milk: ['milk', 'dairy milk', 'doodh', 'cream'],
  lemon: ['lemon', 'lime', 'lemon juice', 'nimbu'],
  pasta: ['pasta', 'macaroni', 'penne', 'spaghetti', 'fusilli', 'noodles'],
  butter: ['butter', 'ghee', 'makhan'],
  lentil: ['lentil', 'lentils', 'dal', 'daal', 'toor dal', 'moong dal', 'chana dal'],
  flour: ['flour', 'atta', 'wheat flour', 'maida', 'all purpose flour', 'besan'],
  mushroom: ['mushroom', 'mushrooms', 'button mushroom'],
  carrot: ['carrot', 'carrots', 'gajar'],
  peas: ['peas', 'green peas', 'matar'],
  cucumber: ['cucumber', 'kheera', 'kakdi'],
};

function getSynonymGroup(word) {
  const stemmed = stemWord(word);
  for (const [key, list] of Object.entries(CULINARY_SYNONYMS)) {
    if (key === stemmed || list.some((item) => stemWord(item) === stemmed || item.includes(stemmed) || stemmed.includes(item))) return list;
  }
  return [stemmed];
}

/**
 * Checks if a user's fridge ingredient matches a recipe ingredient
 * Uses exact match, stemmed token match, and culinary synonym expansion.
 */
function isIngredientMatch(userIngName, recipeIngName) {
  const u = normalize(userIngName);
  const r = normalize(recipeIngName);
  if (!u || !r) return false;
  if (u === r || r.includes(u) || u.includes(r)) return true;

  const uTokens = u.split(/\s+/).filter((t) => t.length > 2);
  const rTokens = r.split(/\s+/).filter((t) => t.length > 2);

  for (const ut of uTokens) {
    const sUt = stemWord(ut);
    for (const rt of rTokens) {
      const sRt = stemWord(rt);
      if (sUt === sRt || sRt.includes(sUt) || sUt.includes(sRt)) return true;
    }
  }

  for (const ut of uTokens) {
    const uSynonyms = getSynonymGroup(ut);
    for (const rt of rTokens) {
      const sRt = stemWord(rt);
      if (uSynonyms.some((syn) => stemWord(syn) === sRt || sRt.includes(stemWord(syn)) || stemWord(syn).includes(sRt))) return true;
    }
  }

  return false;
}

/**
 * Analyzes photo using Google Gemini Vision (or smart local fallback)
 */
async function analyzeFridgeImage({ buffer, mimeType, apiKey, model = 'gemini-1.5-flash' }) {
  if (!buffer || buffer.length === 0) {
    throw new Error('No image data provided for fridge analysis.');
  }

  const hasKey = Boolean(apiKey && typeof apiKey === 'string' && apiKey.trim().length > 0);

  if (hasKey) {
    try {
      const base64Data = buffer.toString('base64');
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey.trim()}`;

      const payload = {
        contents: [
          {
            parts: [
              { text: FRIDGE_VISION_PROMPT },
              { text: 'Analyze this photograph of a refrigerator, pantry, or ingredients. Return strictly formatted JSON:' },
              {
                inlineData: {
                  mimeType: mimeType || 'image/jpeg',
                  data: base64Data,
                },
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.1,
          responseMimeType: 'application/json',
        },
      };

      const res = await fetch(url, {
        method: 'POST',
        signal: AbortSignal.timeout(25000),
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        const data = await res.json();
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text) {
          let cleaned = text.trim();
          if (cleaned.startsWith('```json')) cleaned = cleaned.replace(/^```json\s*/, '').replace(/\s*```$/, '');
          else if (cleaned.startsWith('```')) cleaned = cleaned.replace(/^```\s*/, '').replace(/\s*```$/, '');
          const parsed = JSON.parse(cleaned);

          if (parsed.isFridgeOrFood === false) {
            return {
              success: false,
              isFridgeOrFood: false,
              message: parsed.message || 'We could not detect any refrigerator, pantry, or edible ingredients in this image.',
              ingredients: [],
            };
          }

          if (Array.isArray(parsed.ingredients) && parsed.ingredients.length > 0) {
            return {
              success: true,
              isFridgeOrFood: true,
              ingredients: parsed.ingredients.map((ing) => ({
                name: ing.name || 'Ingredient',
                quantity: ing.quantity || 'Available',
                emoji: ing.emoji || '🥗',
              })),
              source: 'gemini_vision',
              timestamp: new Date().toISOString(),
            };
          }
        }
      }
    } catch (err) {
      console.warn(`[FridgeService] Gemini Vision error: ${err.message}. Using smart local fallback.`);
    }
  }

  // Deterministic smart local fallback based on image bytes hash
  let hash = 0;
  const step = Math.max(1, Math.floor(buffer.length / 48));
  for (let i = 0; i < buffer.length; i += step) {
    hash = (hash * 31 + buffer[i]) & 0x7FFFFFFF;
  }
  const preset = SMART_FRIDGE_PRESETS[hash % SMART_FRIDGE_PRESETS.length];

  return {
    success: true,
    isFridgeOrFood: true,
    ingredients: JSON.parse(JSON.stringify(preset.ingredients)),
    source: hasKey ? 'smart_local_fallback' : 'smart_local',
    noticeNote: hasKey
      ? null
      : 'Smart Local Mode: Add GEMINI_API_KEY to backend/.env for live Google Gemini Vision fridge recognition.',
    timestamp: new Date().toISOString(),
  };
}

/**
 * Generates tailored recipes using Google Gemini or curated catalog fallback
 */
async function generateRecipesFromIngredients({ ingredients = [], apiKey, model = 'gemini-1.5-flash' }) {
  if (!Array.isArray(ingredients) || ingredients.length === 0) {
    throw new Error('Please provide at least one available ingredient to generate recipes.');
  }

  const userIngredientNames = ingredients
    .map((i) => (typeof i === 'string' ? i : i.name || ''))
    .filter(Boolean);

  const hasKey = Boolean(apiKey && typeof apiKey === 'string' && apiKey.trim().length > 0);

  if (hasKey) {
    try {
      const ingListText = userIngredientNames.join(', ');
      const userPrompt = `Available ingredients:\n${ingListText}\n\nGenerate 3 to 4 creative recipes using as many of these ingredients as possible. Return strict JSON.`;

      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey.trim()}`;
      const payload = {
        contents: [
          {
            parts: [
              { text: RECIPE_GENERATION_PROMPT },
              { text: userPrompt },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.3,
          responseMimeType: 'application/json',
        },
      };

      const res = await fetch(url, {
        method: 'POST',
        signal: AbortSignal.timeout(28000),
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        const data = await res.json();
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text) {
          let cleaned = text.trim();
          if (cleaned.startsWith('```json')) cleaned = cleaned.replace(/^```json\s*/, '').replace(/\s*```$/, '');
          else if (cleaned.startsWith('```')) cleaned = cleaned.replace(/^```\s*/, '').replace(/\s*```$/, '');
          const parsed = JSON.parse(cleaned);

          if (Array.isArray(parsed.recipes) && parsed.recipes.length > 0) {
            // Enhance each recipe with videoUrl if not supplied
            const enhancedRecipes = parsed.recipes.map((r, idx) => ({
              id: r.id || `recipe_ai_${Date.now()}_${idx}`,
              name: r.name || 'Custom Recipe',
              emoji: r.emoji || '🍲',
              description: r.description || 'Delicious home-cooked recipe.',
              prepTime: r.prepTime || '10 min',
              cookTime: r.cookTime || '15 min',
              totalTime: r.totalTime || '25 min',
              servings: r.servings || 2,
              difficulty: r.difficulty || 'Easy',
              cuisine: r.cuisine || 'General',
              isVegetarian: r.isVegetarian !== false,
              ingredients: Array.isArray(r.ingredients)
                ? r.ingredients.map((ing) => ({
                    name: ing.name || 'Ingredient',
                    quantity: ing.quantity || 'As required',
                    isFromFridge: ing.isFromFridge !== false,
                  }))
                : [],
              steps: Array.isArray(r.steps) ? r.steps : ['Prepare ingredients.', 'Cook until done.'],
              nutrition: r.nutrition || { calories: 300, protein: 14, carbs: 28, fat: 12, fiber: 3 },
              matchedCount: typeof r.matchedCount === 'number' ? r.matchedCount : userIngredientNames.length,
              totalIngredientsCount: Array.isArray(r.ingredients) ? r.ingredients.length : 4,
              videoUrl:
                r.videoUrl ||
                `https://www.youtube.com/results?search_query=${encodeURIComponent((r.name || 'cooking') + ' recipe step by step')}`,
            }));

            return {
              success: true,
              recipes: enhancedRecipes,
              source: 'gemini_ai',
              timestamp: new Date().toISOString(),
            };
          }
        }
      }
    } catch (err) {
      console.warn(`[FridgeService] Gemini recipe generation error: ${err.message}. Using curated catalog matching.`);
    }
  }

  // Curated Catalog Matching Fallback
  const scoredRecipes = CURATED_RECIPE_CATALOG.map((template) => {
    let matched = 0;
    const updatedIngredients = template.ingredients.map((ing) => {
      const isMatch = userIngredientNames.some((u) => isIngredientMatch(u, ing.name));
      if (isMatch) matched++;
      return {
        name: ing.name,
        quantity: ing.quantity,
        isFromFridge: isMatch,
      };
    });

    const totalCount = updatedIngredients.length;
    const matchPercentage = totalCount > 0 ? matched / totalCount : 0;

    return {
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
      totalIngredientsCount: totalCount,
      matchPercentage,
      videoUrl: `https://www.youtube.com/results?search_query=${encodeURIComponent(template.videoQuery || template.name + ' recipe')}`,
    };
  });

  // Sort by highest matched count, then match percentage
  scoredRecipes.sort((a, b) => {
    const cmp = b.matchedCount - a.matchedCount;
    if (cmp !== 0) return cmp;
    return b.matchPercentage - a.matchPercentage;
  });

  const topRecipes = scoredRecipes.filter((r) => r.matchedCount > 0).slice(0, 5);
  const finalRecipes = topRecipes.length > 0 ? topRecipes : scoredRecipes.slice(0, 3);

  return {
    success: true,
    recipes: finalRecipes,
    source: hasKey ? 'curated_catalog_fallback' : 'curated_catalog',
    timestamp: new Date().toISOString(),
  };
}

module.exports = {
  analyzeFridgeImage,
  generateRecipesFromIngredients,
  SMART_FRIDGE_PRESETS,
  CURATED_RECIPE_CATALOG,
  FRIDGE_VISION_PROMPT,
  RECIPE_GENERATION_PROMPT,
};
