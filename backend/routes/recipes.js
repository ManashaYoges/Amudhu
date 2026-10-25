const express = require('express');
const rateLimit = require('express-rate-limit');
const { optionalAuthenticate, authenticate } = require('../middleware/authenticate');
const { searchRecipes } = require('../services/recipeSearchService');
const FavoriteRecipe = require('../models/FavoriteRecipe');

const router = express.Router();

const searchLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many search requests. Please slow down.', code: 'RATE_LIMIT_EXCEEDED' },
});

/**
 * GET /api/recipes/search?q=...&cuisine=...&diet=...&maxMinutes=...
 * Search across multi-cuisine recipes and videos
 */
router.get('/search', searchLimiter, optionalAuthenticate, async (req, res, next) => {
  try {
    const query = String(req.query.q || '').slice(0, 100);
    const cuisine = String(req.query.cuisine || 'All');
    const diet = String(req.query.diet || 'All');
    const maxMinutes = req.query.maxMinutes ? parseInt(req.query.maxMinutes, 10) : null;

    const apiKey = (process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY || '').trim();
    const result = await searchRecipes({
      query,
      cuisine,
      diet,
      maxMinutes,
      apiKey,
      model: process.env.GEMINI_MODEL || 'gemini-1.5-flash',
    });

    return res.json(result);
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/recipes/favorites
 * List saved favorite recipes for authenticated user
 */
router.get('/favorites', authenticate, async (req, res, next) => {
  try {
    const favorites = await FavoriteRecipe.find({ owner: req.userId })
      .sort({ timestamp: -1 })
      .limit(100)
      .lean();

    return res.json({
      success: true,
      favorites: favorites.map(({ _id, __v, owner, ...f }) => ({
        ...f,
        id: f.recipeId || _id.toString(),
        mongoId: _id.toString(),
      })),
    });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/recipes/favorites
 * Save a recipe to user's MongoDB favorites
 */
router.post('/favorites', authenticate, async (req, res, next) => {
  try {
    const recipe = req.body;
    if (!recipe || !recipe.name) {
      return res.status(400).json({ error: 'Recipe details are required', code: 'VALIDATION_ERROR' });
    }

    const recipeId = recipe.id || `recipe_${Date.now()}`;
    let sanitizedVideoUrl = null;
    if (recipe.videoUrl && typeof recipe.videoUrl === 'string') {
      try {
        const parsed = new URL(recipe.videoUrl.trim());
        if (parsed.protocol === 'https:' || parsed.protocol === 'http:') {
          sanitizedVideoUrl = parsed.href;
        }
      } catch (_) {
        sanitizedVideoUrl = null;
      }
    }

    const saved = await FavoriteRecipe.findOneAndUpdate(
      { owner: req.userId, recipeId },
      {
        $set: {
          owner: req.userId,
          recipeId,
          name: String(recipe.name).trim(),
          emoji: recipe.emoji || '🍲',
          description: recipe.description || '',
          prepTime: recipe.prepTime || '10 min',
          cookTime: recipe.cookTime || '15 min',
          totalTime: recipe.totalTime || '25 min',
          servings: recipe.servings || 2,
          difficulty: recipe.difficulty || 'Easy',
          cuisine: recipe.cuisine || 'General',
          isVegetarian: recipe.isVegetarian !== false,
          ingredients: Array.isArray(recipe.ingredients) ? recipe.ingredients : [],
          steps: Array.isArray(recipe.steps) ? recipe.steps : [],
          nutrition: recipe.nutrition || {},
          videoUrl: sanitizedVideoUrl,
          timestamp: new Date(),
        },
      },
      { upsert: true, new: true, runValidators: true }
    );

    return res.status(201).json({
      success: true,
      message: `${recipe.name} saved to favorites`,
      favorite: { ...saved.toObject(), owner: undefined },
    });
  } catch (err) {
    next(err);
  }
});

/**
 * DELETE /api/recipes/favorites/:id
 * Remove a recipe from favorites
 */
router.delete('/favorites/:id', authenticate, async (req, res, next) => {
  try {
    const id = req.params.id;
    await FavoriteRecipe.findOneAndDelete({
      owner: req.userId,
      $or: [{ recipeId: id }, { _id: id.match(/^[0-9a-fA-F]{24}$/) ? id : null }],
    });

    return res.json({ success: true, message: 'Recipe removed from favorites' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
