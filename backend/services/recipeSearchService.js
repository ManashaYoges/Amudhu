/**
 * Amudhu Recipe Search & Discovery Service
 * Provides comprehensive multi-cuisine culinary recipe search, video tutorials,
 * and AI-augmented recipe generation.
 */

const FULL_RECIPE_CATALOG = [
  // --- BREAD DISHES ---
  {
    id: 'garlic_bread_cheese',
    name: 'Cheesy Garlic Bread Toast',
    emoji: '🍞',
    description: 'Crispy golden toasted bread slathered with roasted garlic butter, mixed herbs, and bubbling cheese.',
    prepTime: '5 min',
    cookTime: '7 min',
    totalTime: '12 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Italian',
    isVegetarian: true,
    ingredients: [
      { name: 'Bread', quantity: '4 thick slices' },
      { name: 'Butter', quantity: '2 tbsp softened' },
      { name: 'Garlic', quantity: '5 cloves finely minced' },
      { name: 'Cheese', quantity: '1/2 cup grated mozzarella' },
      { name: 'Oregano & Chili Flakes', quantity: '1/2 tsp each' },
    ],
    steps: [
      'In a bowl, mix softened butter with finely minced garlic, oregano, and chili flakes.',
      'Generously spread garlic butter over one side of each bread slice.',
      'Place on a warm skillet butter-side down for 2 minutes until golden and fragrant.',
      'Flip over, top with grated cheese, cover pan with a lid for 2 minutes until cheese melts completely.',
      'Sprinkle herbs and slice diagonally. Serve hot.',
    ],
    nutrition: { calories: 280, protein: 9.5, carbs: 28.0, fat: 15.0, fiber: 1.8 },
  },
  {
    id: 'homestyle_bread_upma',
    name: 'Spiced Homestyle Bread Upma',
    emoji: '🥪',
    description: 'A comforting South Indian breakfast skillet turning crusty bread cubes into a zesty, spiced snack.',
    prepTime: '6 min',
    cookTime: '8 min',
    totalTime: '14 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'South Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Bread', quantity: '5 slices cubed' },
      { name: 'Onions', quantity: '1 large finely diced' },
      { name: 'Tomatoes', quantity: '1 medium chopped' },
      { name: 'Green Chillies', quantity: '2 minced' },
      { name: 'Cooking Oil', quantity: '1 tbsp' },
      { name: 'Mustard Seeds', quantity: '1/2 tsp' },
      { name: 'Turmeric Powder', quantity: '1/4 tsp' },
      { name: 'Lemon Juice', quantity: '1 tsp' },
    ],
    steps: [
      'Cut bread slices into bite-sized cubes.',
      'Heat oil in a wok. Add mustard seeds and let crackle.',
      'Add onions and green chillies; sauté until translucent.',
      'Add chopped tomatoes, turmeric, and salt. Cook until mushy.',
      'Toss in bread cubes gently until coated with the onion-tomato masala.',
      'Drizzle lemon juice, garnish with coriander, and serve warm.',
    ],
    nutrition: { calories: 240, protein: 6.2, carbs: 38.0, fat: 7.5, fiber: 2.5 },
  },
  {
    id: 'masala_french_toast',
    name: 'Savory Indian Masala French Toast',
    emoji: '🍳',
    description: 'Bread slices dipped in a vibrant egg batter infused with onions, tomatoes, and green chillies.',
    prepTime: '5 min',
    cookTime: '6 min',
    totalTime: '11 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Indian',
    isVegetarian: false,
    ingredients: [
      { name: 'Bread', quantity: '4 slices' },
      { name: 'Eggs', quantity: '2 large' },
      { name: 'Onions', quantity: '1/2 finely chopped' },
      { name: 'Tomatoes', quantity: '1/2 finely diced' },
      { name: 'Green Chillies', quantity: '1 minced' },
      { name: 'Butter / Oil', quantity: '1 tbsp' },
      { name: 'Salt & Pepper', quantity: 'To taste' },
    ],
    steps: [
      'In a wide shallow bowl, whisk eggs with chopped onion, tomato, green chilli, salt, and pepper.',
      'Dip bread slice into the egg mixture, coating both sides well.',
      'Heat butter on a skillet over medium heat. Place coated bread in the pan.',
      'Spoon any extra vegetable bits over the top. Toast for 2-3 minutes per side until golden.',
      'Serve hot with tomato ketchup or mint chutney.',
    ],
    nutrition: { calories: 260, protein: 12.0, carbs: 29.0, fat: 11.0, fiber: 2.0 },
  },

  // --- PASTA DISHES ---
  {
    id: 'creamy_alfredo_pasta',
    name: 'Creamy Garlic Alfredo Penne',
    emoji: '🍝',
    description: 'Penne pasta tossed in a luxurious garlic parmesan cream sauce finished with fresh black pepper.',
    prepTime: '8 min',
    cookTime: '12 min',
    totalTime: '20 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Italian',
    isVegetarian: true,
    ingredients: [
      { name: 'Pasta', quantity: '200 g penne or fettuccine' },
      { name: 'Butter', quantity: '2 tbsp' },
      { name: 'Garlic', quantity: '4 cloves minced' },
      { name: 'Milk / Cream', quantity: '1 cup' },
      { name: 'Cheese', quantity: '1/3 cup grated parmesan or processed cheese' },
      { name: 'Black Pepper & Salt', quantity: 'To taste' },
    ],
    steps: [
      'Boil pasta in salted water for 9 minutes until al dente. Reserve 1/4 cup pasta water and drain.',
      'Melt butter in a skillet. Sauté minced garlic for 1 minute until fragrant.',
      'Pour in milk/cream and simmer gently for 2 minutes.',
      'Stir in cheese until smooth and melted. Season with salt and black pepper.',
      'Add boiled pasta with a splash of reserved water. Toss until sauce clings silkily.',
      'Serve warm topped with extra cracked pepper.',
    ],
    nutrition: { calories: 420, protein: 14.5, carbs: 54.0, fat: 17.0, fiber: 3.2 },
  },
  {
    id: 'tomato_basil_pasta',
    name: 'Classic Rustic Tomato Basil Pasta',
    emoji: '🍅',
    description: 'Fresh pasta tossed with aromatic simmered plum tomatoes, garlic, extra virgin olive oil, and fresh basil.',
    prepTime: '6 min',
    cookTime: '14 min',
    totalTime: '20 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Italian',
    isVegetarian: true,
    ingredients: [
      { name: 'Pasta', quantity: '200 g' },
      { name: 'Tomatoes', quantity: '4 ripe pureed or finely diced' },
      { name: 'Garlic', quantity: '4 cloves sliced' },
      { name: 'Olive Oil', quantity: '2 tbsp' },
      { name: 'Basil Leaves', quantity: '8-10 fresh leaves' },
      { name: 'Chili Flakes & Salt', quantity: 'To taste' },
    ],
    steps: [
      'Boil pasta in well-salted water until al dente.',
      'Heat olive oil in a pan. Sauté sliced garlic and chili flakes on low until golden.',
      'Add pureed tomatoes and salt. Simmer for 10 minutes until sauce thickens and oil separates.',
      'Toss drained pasta directly into the rich tomato sauce.',
      'Tear in fresh basil leaves and stir for 1 minute.',
      'Drizzle extra virgin olive oil and serve hot.',
    ],
    nutrition: { calories: 340, protein: 11.0, carbs: 56.0, fat: 8.5, fiber: 4.8 },
  },

  // --- PANEER DISHES ---
  {
    id: 'palak_paneer_restaurant',
    name: 'Smooth & Rich Palak Paneer',
    emoji: '🧀',
    description: 'Tender cottage cheese cubes simmered in a velvety, spiced spinach gravy finished with a touch of cream.',
    prepTime: '10 min',
    cookTime: '15 min',
    totalTime: '25 min',
    servings: 3,
    difficulty: 'Medium',
    cuisine: 'Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Paneer', quantity: '250 g cubed' },
      { name: 'Spinach', quantity: '1 large bunch (250g)' },
      { name: 'Onions', quantity: '1 medium diced' },
      { name: 'Tomatoes', quantity: '1 ripe chopped' },
      { name: 'Ginger & Garlic', quantity: '1 tbsp minced' },
      { name: 'Garam Masala', quantity: '1/2 tsp' },
      { name: 'Cream / Ghee', quantity: '1 tbsp' },
    ],
    steps: [
      'Blanch spinach in boiling water for 2 minutes, then plunge into ice water. Puree until smooth.',
      'Heat ghee or oil. Sauté onions, ginger, and garlic until golden.',
      'Add chopped tomato, turmeric, garam masala, and salt. Cook until soft.',
      'Pour in the bright green spinach puree and simmer for 4 minutes.',
      'Gently slide in paneer cubes. Simmer on low flame for 3 minutes.',
      'Stir in cream or ghee and serve warm with naan or jeera rice.',
    ],
    nutrition: { calories: 330, protein: 18.0, carbs: 9.2, fat: 24.5, fiber: 4.5 },
  },
  {
    id: 'paneer_butter_masala',
    name: 'Velvety Paneer Butter Masala',
    emoji: '🧈',
    description: 'Succulent paneer cubes bathed in a rich, mildly sweet, and aromatic buttery tomato-cashew gravy.',
    prepTime: '10 min',
    cookTime: '15 min',
    totalTime: '25 min',
    servings: 3,
    difficulty: 'Easy',
    cuisine: 'Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Paneer', quantity: '250 g cubed' },
      { name: 'Tomatoes', quantity: '4 ripe' },
      { name: 'Butter', quantity: '2 tbsp' },
      { name: 'Kasuri Methi', quantity: '1 tsp' },
      { name: 'Kashmiri Chili Powder', quantity: '1 tsp' },
      { name: 'Cream / Cashews', quantity: '2 tbsp' },
    ],
    steps: [
      'Boil tomatoes with 8-10 cashews for 6 minutes, then blend into a silky smooth puree.',
      'Melt butter in a pan. Add red chili powder and immediately pour in the tomato puree.',
      'Cook on medium heat until gravy thickens and butter releases at the edges.',
      'Add salt, a pinch of sugar, and crushed kasuri methi.',
      'Add paneer cubes and simmer on low for 3 minutes.',
      'Swirl in fresh cream and serve hot with rotis or pulao.',
    ],
    nutrition: { calories: 380, protein: 16.5, carbs: 14.0, fat: 28.0, fiber: 3.0 },
  },
  {
    id: 'paneer_tikka_skillet',
    name: 'Skillet Tandoori Paneer Tikka',
    emoji: '🍢',
    description: 'Smoky, spiced paneer cubes, bell peppers, and red onions charred to perfection on a hot skillet.',
    prepTime: '10 min',
    cookTime: '10 min',
    totalTime: '20 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Paneer', quantity: '250 g large cubes' },
      { name: 'Curd / Yogurt', quantity: '1/2 cup hung or thick' },
      { name: 'Capsicum', quantity: '1 cubed' },
      { name: 'Onions', quantity: '1 cubed' },
      { name: 'Tandoori Masala & Chaat Masala', quantity: '1 tsp each' },
      { name: 'Cooking Oil', quantity: '1 tbsp' },
    ],
    steps: [
      'Whisk curd with tandoori masala, salt, and 1 tsp oil to make marinade.',
      'Coat paneer cubes, capsicum, and onions gently in the marinade for 10 minutes.',
      'Heat oil on a skillet or grill pan over medium-high heat.',
      'Place paneer and vegetables in a single layer. Sear for 2-3 minutes per side until charred spots appear.',
      'Sprinkle chaat masala, squeeze fresh lemon juice, and serve immediately with mint chutney.',
    ],
    nutrition: { calories: 310, protein: 19.5, carbs: 8.0, fat: 22.0, fiber: 2.8 },
  },

  // --- BIRYANI & RICE ---
  {
    id: 'hyderabadi_chicken_biryani',
    name: 'Aromatic Chicken Dum Biryani',
    emoji: '🍗',
    description: 'Fragrant basmati rice layered with tender marinated chicken, saffron, fried onions, and whole spices.',
    prepTime: '20 min',
    cookTime: '30 min',
    totalTime: '50 min',
    servings: 4,
    difficulty: 'Medium',
    cuisine: 'Indian',
    isVegetarian: false,
    ingredients: [
      { name: 'Basmati Rice', quantity: '2 cups aged' },
      { name: 'Chicken', quantity: '500 g bone-in pieces' },
      { name: 'Curd / Yogurt', quantity: '1/2 cup' },
      { name: 'Biryani Masala & Ginger-Garlic', quantity: '1 tbsp each' },
      { name: 'Onions', quantity: '2 large fried crisp' },
      { name: 'Ghee & Saffron Milk', quantity: '2 tbsp' },
    ],
    steps: [
      'Marinate chicken in curd, ginger-garlic paste, biryani masala, and salt for 20 minutes.',
      'Parboil basmati rice with whole spices until 70% cooked; drain.',
      'In a heavy-bottomed pot, sear the marinated chicken for 8 minutes.',
      'Layer parboiled rice over the chicken. Top with fried onions, mint, and saffron milk.',
      'Seal with lid or foil. Cook on low heat (dum) for 20 minutes.',
      'Rest for 5 minutes, gently fluff with a ladle, and serve with raita.',
    ],
    nutrition: { calories: 520, protein: 34.0, carbs: 62.0, fat: 14.5, fiber: 2.5 },
  },
  {
    id: 'vegetable_dum_biryani',
    name: 'Fragrant Vegetable Dum Biryani',
    emoji: '🍚',
    description: 'Royal basmati rice layered with garden fresh vegetables, aromatic spices, and caramelized onions.',
    prepTime: '15 min',
    cookTime: '25 min',
    totalTime: '40 min',
    servings: 3,
    difficulty: 'Medium',
    cuisine: 'Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Basmati Rice', quantity: '1.5 cups' },
      { name: 'Mixed Vegetables', quantity: '2 cups carrots, beans, peas, potato' },
      { name: 'Curd / Yogurt', quantity: '1/3 cup' },
      { name: 'Biryani Spices', quantity: '1 tbsp' },
      { name: 'Onions', quantity: '2 sliced & browned' },
      { name: 'Ghee / Oil', quantity: '2 tbsp' },
    ],
    steps: [
      'Parboil soaked basmati rice until 70% cooked.',
      'Sauté vegetables in ghee with biryani spices, curd, and salt until half-cooked.',
      'Layer vegetables and rice alternately in a thick-bottomed pot.',
      'Garnish top layer with browned onions, coriander, and a drizzle of ghee.',
      'Cover tightly and cook on lowest flame for 18 minutes.',
      'Serve hot with cucumber raita and papad.',
    ],
    nutrition: { calories: 380, protein: 8.5, carbs: 68.0, fat: 9.0, fiber: 5.2 },
  },
  {
    id: 'egg_fried_rice_asian',
    name: 'Quick Indo-Chinese Egg Fried Rice',
    emoji: '🥢',
    description: 'Wok-tossed fluffy rice with scrambled eggs, scallions, carrots, soy sauce, and aromatic garlic.',
    prepTime: '8 min',
    cookTime: '8 min',
    totalTime: '16 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Asian',
    isVegetarian: false,
    ingredients: [
      { name: 'Cooked Rice', quantity: '2 cups chilled or leftover' },
      { name: 'Eggs', quantity: '3 large' },
      { name: 'Carrots & Beans', quantity: '1/2 cup finely diced' },
      { name: 'Garlic', quantity: '4 cloves minced' },
      { name: 'Soy Sauce', quantity: '1.5 tbsp' },
      { name: 'Cooking Oil', quantity: '1.5 tbsp' },
      { name: 'Spring Onions', quantity: '2 stalks chopped' },
    ],
    steps: [
      'Heat oil in a wok on high heat. Add minced garlic and sauté for 30 seconds.',
      'Toss in diced carrots and beans; stir-fry rapidly for 2 minutes to keep them crisp.',
      'Push vegetables to one side. Crack eggs into the wok and scramble softly.',
      'Add chilled cooked rice, soy sauce, pinch of salt, and black pepper.',
      'Toss vigorously on high flame for 3 minutes until rice is piping hot and fragrant.',
      'Top with green spring onions and serve immediately.',
    ],
    nutrition: { calories: 360, protein: 15.0, carbs: 48.0, fat: 12.5, fiber: 2.8 },
  },

  // --- CHICKEN DISHES ---
  {
    id: 'homestyle_chicken_curry',
    name: 'Homestyle Spiced Chicken Curry',
    emoji: '🍲',
    description: 'Tender chicken pieces simmered in an aromatic gravy of onions, tomatoes, ginger, garlic, and coriander.',
    prepTime: '10 min',
    cookTime: '22 min',
    totalTime: '32 min',
    servings: 3,
    difficulty: 'Easy',
    cuisine: 'Indian',
    isVegetarian: false,
    ingredients: [
      { name: 'Chicken', quantity: '450 g pieces' },
      { name: 'Onions', quantity: '2 finely sliced' },
      { name: 'Tomatoes', quantity: '2 pureed' },
      { name: 'Ginger-Garlic Paste', quantity: '1 tbsp' },
      { name: 'Coriander & Garam Masala', quantity: '1 tsp each' },
      { name: 'Cooking Oil', quantity: '2 tbsp' },
    ],
    steps: [
      'Heat oil in a pan. Sauté sliced onions until golden brown.',
      'Add ginger-garlic paste and sauté for 1 minute.',
      'Add pureed tomatoes, coriander powder, turmeric, and salt. Cook until oil separates.',
      'Add chicken pieces and sear in the masala for 5 minutes.',
      'Add 3/4 cup warm water, cover, and simmer for 15 minutes until chicken is tender.',
      'Stir in garam masala and chopped coriander leaves. Serve hot with rice or chapati.',
    ],
    nutrition: { calories: 340, protein: 32.0, carbs: 8.5, fat: 18.0, fiber: 2.2 },
  },
  {
    id: 'crispy_pan_seared_chicken',
    name: 'Pan-Seared Herb Chicken Breast',
    emoji: '🍗',
    description: 'Juicy chicken breast seasoned with garlic, rosemary, smoked paprika, and a squeeze of fresh lemon.',
    prepTime: '5 min',
    cookTime: '12 min',
    totalTime: '17 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Continental',
    isVegetarian: false,
    ingredients: [
      { name: 'Chicken Breast', quantity: '350 g (2 cutlets)' },
      { name: 'Garlic', quantity: '3 cloves minced' },
      { name: 'Olive Oil', quantity: '1 tbsp' },
      { name: 'Lemon Juice', quantity: '1 tbsp' },
      { name: 'Paprika & Mixed Herbs', quantity: '1 tsp each' },
      { name: 'Salt & Pepper', quantity: 'To taste' },
    ],
    steps: [
      'Lightly pound chicken breasts to uniform thickness.',
      'Season both sides with garlic, olive oil, lemon juice, paprika, herbs, salt, and pepper.',
      'Heat a heavy skillet over medium-high flame.',
      'Sear chicken for 6 minutes on the first side without moving, until golden brown.',
      'Flip and cook for 5-6 more minutes until internal temperature reaches 75°C.',
      'Rest for 3 minutes before slicing to keep juices locked in.',
    ],
    nutrition: { calories: 240, protein: 38.0, carbs: 2.0, fat: 8.5, fiber: 0.5 },
  },

  // --- PIZZA & SNACKS ---
  {
    id: 'skillet_bread_pizza',
    name: 'Quick Skillet Bread Pizza',
    emoji: '🍕',
    description: 'Crispy bread base topped with zesty pizza sauce, bell peppers, onions, sweet corn, and gooey cheese.',
    prepTime: '5 min',
    cookTime: '6 min',
    totalTime: '11 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'Italian',
    isVegetarian: true,
    ingredients: [
      { name: 'Bread', quantity: '4 slices' },
      { name: 'Pizza Sauce / Ketchup', quantity: '3 tbsp' },
      { name: 'Cheese', quantity: '1/2 cup grated mozzarella' },
      { name: 'Capsicum & Onions', quantity: '1/2 cup diced' },
      { name: 'Oregano & Chili Flakes', quantity: '1/2 tsp each' },
      { name: 'Butter', quantity: '1 tsp' },
    ],
    steps: [
      'Toast one side of bread slices lightly on a buttered pan.',
      'Remove and spread pizza sauce on the toasted side.',
      'Top with diced capsicum, onions, and generous grated cheese.',
      'Place back in the skillet on low heat. Cover with lid.',
      'Cook for 4-5 minutes until the bottom is ultra-crisp and cheese melts completely.',
      'Sprinkle oregano and chili flakes; slice and enjoy.',
    ],
    nutrition: { calories: 290, protein: 11.0, carbs: 32.0, fat: 13.5, fiber: 2.2 },
  },

  // --- BREAKFAST & SOUTH INDIAN CLASSICS ---
  {
    id: 'crispy_plain_dosa',
    name: 'Crispy Golden Plain Dosa',
    emoji: '🥞',
    description: 'Classic paper-thin crispy fermented rice-lentil crepe cooked with golden ghee and served with sambar.',
    prepTime: '2 min',
    cookTime: '5 min',
    totalTime: '7 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'South Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Dosa Batter', quantity: '2 cups' },
      { name: 'Ghee or Cooking Oil', quantity: '2 tsp' },
      { name: 'Sambar & Chutney', quantity: 'For serving' },
    ],
    steps: [
      'Heat a flat cast iron or non-stick tawa until medium-hot.',
      'Pour a ladle of batter in the center and spread outward in circular motions.',
      'Drizzle a little ghee around the perimeter.',
      'Cook until edges turn golden and crisp and lift easily from the pan.',
      'Fold into half and serve piping hot with vegetable sambar and coconut chutney.',
    ],
    nutrition: { calories: 190, protein: 4.2, carbs: 32.0, fat: 5.0, fiber: 1.5 },
  },
  {
    id: 'traditional_steamed_idli',
    name: 'Traditional Steamed Idli with Sambar',
    emoji: '🥣',
    description: 'Pillow-soft, gut-friendly steamed rice and urad dal cakes paired with vegetable sambar.',
    prepTime: '5 min',
    cookTime: '10 min',
    totalTime: '15 min',
    servings: 2,
    difficulty: 'Easy',
    cuisine: 'South Indian',
    isVegetarian: true,
    ingredients: [
      { name: 'Idli Batter', quantity: '2 cups fermented' },
      { name: 'Cooking Oil', quantity: '1 tsp for greasing' },
      { name: 'Sambar', quantity: '1 cup' },
    ],
    steps: [
      'Grease idli molds lightly with oil.',
      'Pour fermented idli batter into each mold cavity.',
      'Place in steamer over boiling water. Cover and steam for 10 minutes on medium-high heat.',
      'Remove from heat, let sit for 2 minutes, then unmold with a wet spoon.',
      'Serve warm immersed in piping hot sambar.',
    ],
    nutrition: { calories: 210, protein: 6.5, carbs: 42.0, fat: 1.2, fiber: 2.2 },
  },
];

/**
 * Searches the catalog and generates relevant YouTube video tutorials and recommendations
 */
function searchCatalog(query) {
  const clean = String(query || '').toLowerCase().trim();
  if (!clean) {
    return {
      recipes: FULL_RECIPE_CATALOG.slice(0, 6),
      cuisines: ['All', 'Indian', 'Italian', 'South Indian', 'Continental', 'Asian'],
      recommendations: ['Bread', 'Pasta', 'Paneer', 'Chicken', 'Biryani', 'Dosa'],
    };
  }

  const tokens = clean.split(/\s+/).filter((t) => t.length > 1);

  const matched = FULL_RECIPE_CATALOG.filter((recipe) => {
    const text = `${recipe.name} ${recipe.cuisine} ${recipe.description} ${recipe.ingredients.map((i) => i.name).join(' ')}`.toLowerCase();
    if (text.includes(clean)) return true;
    return tokens.some((t) => text.includes(t));
  });

  const cuisinesSet = new Set(['All']);
  matched.forEach((r) => cuisinesSet.add(r.cuisine));

  // Generate dynamic recommendations
  let recs = ['Bread', 'Paneer', 'Pasta', 'Chicken', 'Biryani'];
  if (clean.includes('bread')) {
    recs = ['Garlic Bread', 'Bread Upma', 'French Toast', 'Bread Pizza'];
  } else if (clean.includes('paneer')) {
    recs = ['Palak Paneer', 'Paneer Butter Masala', 'Paneer Tikka', 'Paneer Bhurji'];
  } else if (clean.includes('pasta')) {
    recs = ['Alfredo Pasta', 'Tomato Basil Pasta', 'Garlic Bread', 'White Sauce Pasta'];
  } else if (clean.includes('chicken')) {
    recs = ['Chicken Biryani', 'Chicken Curry', 'Pan Seared Chicken', 'Egg Fried Rice'];
  } else if (clean.includes('rice') || clean.includes('biryani')) {
    recs = ['Chicken Biryani', 'Veg Biryani', 'Egg Fried Rice', 'Curd Rice'];
  }

  return {
    recipes: matched,
    cuisines: Array.from(cuisinesSet),
    recommendations: recs,
  };
}

/**
 * Generates relevant YouTube video tutorials for a query
 */
function generateVideosForQuery(query, recipes = []) {
  const cap = (query || 'Recipe').charAt(0).toUpperCase() + (query || 'Recipe').slice(1);
  const base = 'https://www.youtube.com/results?search_query=';

  const defaultThumbnails = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&q=80',
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&q=80',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500&q=80',
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=500&q=80',
  ];

  return [
    {
      id: `vid_search_1_${query}`,
      title: `How to Make Easy ${cap} (Step-by-Step for Beginners)`,
      thumbnailUrl: defaultThumbnails[0],
      channelName: 'Chef Masterclass',
      duration: '8:45 min',
      videoUrl: `${base}${encodeURIComponent(cap + ' recipe step by step')}`,
    },
    {
      id: `vid_search_2_${query}`,
      title: `Top 5 Quick & Tasty ${cap} Recipes in 15 Minutes`,
      thumbnailUrl: defaultThumbnails[1],
      channelName: 'Quick Home Cooking',
      duration: '11:20 min',
      videoUrl: `${base}${encodeURIComponent(cap + ' quick 15 min recipe')}`,
    },
    {
      id: `vid_search_3_${query}`,
      title: `Authentic Restaurant Style ${cap} Secrets`,
      thumbnailUrl: defaultThumbnails[2],
      channelName: 'Flavors of the World',
      duration: '14:10 min',
      videoUrl: `${base}${encodeURIComponent('restaurant style ' + cap)}`,
    },
  ];
}

/**
 * Main recipe search orchestrator
 */
async function searchRecipes({ query = '', cuisine = 'All', diet = 'All', maxMinutes = null, apiKey, model = 'gemini-1.5-flash' }) {
  const clean = String(query).trim();
  let searchData = searchCatalog(clean);

  // If user typed something creative that wasn't in catalog and an AI key is available, generate dynamically
  if (searchData.recipes.length === 0 && clean.length > 2 && apiKey && apiKey.trim().length > 0) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey.trim()}`;
      const prompt = `User searched for recipes related to: "${clean}". Create 2 to 3 delicious recipes for this search term. Return valid JSON: { "recipes": [{ "name": "...", "emoji": "...", "description": "...", "prepTime": "10 min", "cookTime": "15 min", "totalTime": "25 min", "servings": 2, "difficulty": "Easy", "cuisine": "...", "isVegetarian": true, "ingredients": [{"name": "...", "quantity": "..."}], "steps": ["..."], "nutrition": {"calories": 320, "protein": 14, "carbs": 30, "fat": 12, "fiber": 3} }] }`;

      const res = await fetch(url, {
        method: 'POST',
        signal: AbortSignal.timeout(20000),
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.3, responseMimeType: 'application/json' },
        }),
      });

      if (res.ok) {
        const json = await res.json();
        const text = json.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text) {
          const parsed = JSON.parse(text);
          if (Array.isArray(parsed.recipes) && parsed.recipes.length > 0) {
            searchData.recipes = parsed.recipes.map((r, i) => ({
              id: `recipe_ai_${Date.now()}_${i}`,
              ...r,
              videoUrl: `https://www.youtube.com/results?search_query=${encodeURIComponent(r.name + ' recipe')}`,
            }));
          }
        }
      }
    } catch (_) {}
  }

  // Apply filters
  let filtered = searchData.recipes;

  if (cuisine && cuisine !== 'All') {
    filtered = filtered.filter((r) => r.cuisine.toLowerCase() === cuisine.toLowerCase());
  }

  if (diet === 'Vegetarian') {
    filtered = filtered.filter((r) => r.isVegetarian === true);
  } else if (diet === 'Non-Veg') {
    filtered = filtered.filter((r) => r.isVegetarian === false);
  }

  if (maxMinutes && typeof maxMinutes === 'number') {
    filtered = filtered.filter((r) => {
      const mins = parseInt(String(r.totalTime).replace(/[^0-9]/g, ''), 10) || 30;
      return mins <= maxMinutes;
    });
  }

  const videos = generateVideosForQuery(clean, filtered);

  return {
    query: clean,
    count: filtered.length,
    recipes: filtered,
    videos,
    cuisines: searchData.cuisines,
    recommendations: searchData.recommendations,
  };
}

module.exports = {
  FULL_RECIPE_CATALOG,
  searchRecipes,
  searchCatalog,
  generateVideosForQuery,
};
