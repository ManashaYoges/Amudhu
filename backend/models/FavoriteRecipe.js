const mongoose = require('mongoose');

const favoriteRecipeSchema = new mongoose.Schema({
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  recipeId: { type: String, required: true },
  name: { type: String, required: true, trim: true, maxlength: 160 },
  emoji: { type: String, default: '🍲' },
  description: { type: String, maxlength: 1000 },
  prepTime: { type: String },
  cookTime: { type: String },
  totalTime: { type: String },
  servings: { type: Number, default: 2 },
  difficulty: { type: String, default: 'Easy' },
  cuisine: { type: String, default: 'General' },
  isVegetarian: { type: Boolean, default: true },
  ingredients: { type: [mongoose.Schema.Types.Mixed], default: [] },
  steps: { type: [String], default: [] },
  nutrition: { type: mongoose.Schema.Types.Mixed, default: {} },
  videoUrl: { type: String },
  timestamp: { type: Date, default: Date.now },
}, { timestamps: true, collection: 'favorite_recipes' });

favoriteRecipeSchema.index({ owner: 1, recipeId: 1 }, { unique: true });
favoriteRecipeSchema.index({ owner: 1, timestamp: -1 });

module.exports = mongoose.model('FavoriteRecipe', favoriteRecipeSchema);
