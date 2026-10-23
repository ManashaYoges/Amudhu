require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const multer = require('multer');
const mongoose = require('mongoose');
const authRoutes = require('./routes/auth');
const mealRoutes = require('./routes/meals');
const chatRoutes = require('./routes/chat');
const { notFound, errorHandler } = require('./middleware/errors');
const { processFoodImage } = require('./services/visionService');
const { calculateMealNutrition, FOOD_DATABASE } = require('./services/nutritionDatabase');

const app = express();
app.disable('x-powered-by');
app.use(helmet());
const allowedOrigins = (process.env.CORS_ORIGINS || '').split(',').map((x) => x.trim()).filter(Boolean);
app.use(cors({ origin: (origin, callback) => {
  if (!origin || allowedOrigins.some((allowed) => allowed.endsWith('*')
    ? origin.startsWith(allowed.slice(0, -1)) : origin === allowed)) return callback(null, true);
  return callback(null, false);
} }));
app.use(express.json({ limit: '25mb' }));

const upload = multer({
  storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype?.startsWith('image/') || file.mimetype === 'application/octet-stream' ||
      /\.(jpe?g|png|webp|heic|bmp)$/i.test(file.originalname || '')) cb(null, true);
    else cb(new Error('Only image files (JPEG, PNG, WEBP) are accepted.'));
  },
});

app.get(['/health', '/api/health'], (req, res) => res.json({
  status: 'online', service: 'Amudhu API', database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  provider: process.env.GEMINI_API_KEY ? 'gemini' : process.env.OPENAI_API_KEY ? 'openai' : 'smart_local',
  apiKeyConfigured: Boolean(process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY),
  foodCatalogCount: FOOD_DATABASE.length, timestamp: new Date().toISOString(),
}));

app.use(['/auth', '/api/auth'], authRoutes);
app.use(['/meals', '/api/meals'], mealRoutes);
app.use(['/chat', '/api/chat'], chatRoutes);

app.post(['/analyze-plate', '/api/analyze-plate'], upload.single('image'), async (req, res, next) => {
  let imageBuffer; let mimeType = 'image/jpeg';
  if (req.file) { imageBuffer = req.file.buffer; mimeType = req.file.mimetype || mimeType; }
  else if (req.body?.image) {
    let raw = req.body.image;
    const dataUri = raw.match(/^data:([a-zA-Z0-9]+\/[a-zA-Z0-9-.+]+);base64,(.+)$/);
    if (dataUri) { mimeType = dataUri[1]; raw = dataUri[2]; } else if (req.body.mimeType) mimeType = req.body.mimeType;
    imageBuffer = Buffer.from(raw, 'base64');
  }
  if (!imageBuffer?.length) return res.status(400).json({ error: 'No valid image was provided', code: 'IMAGE_REQUIRED' });
  try {
    const apiKey = (process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY || '').trim();
    const result = await processFoodImage({ buffer: imageBuffer, mimeType, apiKey,
      provider: process.env.AI_PROVIDER || (apiKey ? 'gemini' : 'smart_local'), model: process.env.GEMINI_MODEL || 'gemini-3.5-flash' });
    if (!result.success) return res.status(422).json({ error: result.message, code: 'NO_FOOD_DETECTED' });
    return res.json(result);
  } catch (err) {
    const limited = /quota|rate/i.test(err.message);
    return res.status(limited ? 429 : 502).json({ error: limited ? 'Analysis provider rate limit reached' : 'Meal analysis failed', code: limited ? 'RATE_LIMIT_EXCEEDED' : 'RECOGNITION_ERROR' });
  }
});

app.post(['/recalculate', '/api/recalculate'], (req, res) => {
  if (!Array.isArray(req.body?.foods) || req.body.foods.length > 100) return res.status(400).json({ error: 'Foods array is required', code: 'VALIDATION_ERROR' });
  return res.json({ success: true, ...calculateMealNutrition(req.body.foods), analysisSource: 'user_edited', timestamp: new Date().toISOString() });
});

app.post(['/api/analyze-fridge', '/v1/analyze-fridge'], upload.single('image'), (req, res) => res.json({
  ingredients: [
    { name: 'Eggs', quantity: '4 pieces', emoji: '🥚' }, { name: 'Tomatoes', quantity: '3 medium', emoji: '🍅' },
    { name: 'Onions', quantity: '2 medium', emoji: '🧅' }, { name: 'Spinach / Palak', quantity: '1 bunch', emoji: '🥬' },
    { name: 'Paneer', quantity: '200 g', emoji: '🧀' }, { name: 'Curd / Yogurt', quantity: '250 g', emoji: '🥛' },
    { name: 'Carrots', quantity: '2 medium', emoji: '🥕' }, { name: 'Green Chillies', quantity: '4 pieces', emoji: '🫑' },
  ], timestamp: new Date().toISOString(),
}));
app.post(['/api/generate-recipes', '/v1/generate-recipes'], (req, res) => {
  const ingredients = Array.isArray(req.body?.ingredients) ? req.body.ingredients : [];
  return res.json({ success: true, recipes: [{ id: 'recipe_egg_bhurji', name: 'Homestyle Spiced Egg Bhurji', emoji: '🍳',
    description: 'Quick, protein-rich scrambled eggs with onions, tomatoes and spices.', prepTime: '5 min', cookTime: '10 min',
    totalTime: '15 min', servings: 2, difficulty: 'Easy', cuisine: 'Indian', isVegetarian: false,
    ingredients: [{ name: 'Eggs', quantity: '3 pieces', isFromFridge: true }, { name: 'Onion', quantity: '1 finely chopped', isFromFridge: true },
      { name: 'Tomato', quantity: '1 medium chopped', isFromFridge: true }, { name: 'Oil / Ghee', quantity: '1 tsp', isFromFridge: false }],
    steps: ['Sauté onion and tomato.', 'Add beaten eggs and spices; scramble until cooked through.'],
    nutrition: { calories: 220, protein: 16.5, carbs: 6.2, fat: 14.8, fiber: 1.5 }, matchedCount: Math.min(3, ingredients.length), totalIngredientsCount: 4,
  }] });
});
app.get(['/api/recipes/search', '/v1/recipes/search'], (req, res) => res.json({
  query: String(req.query.q || '').slice(0, 100), count: 0, recipes: [], videos: [], cuisines: ['All'], recommendations: [],
}));

app.use(notFound);
app.use(errorHandler);
module.exports = app;
