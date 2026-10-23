const mongoose = require('mongoose');

const mealSchema = new mongoose.Schema({
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  mealName: { type: String, required: true, trim: true, maxlength: 160 },
  foods: { type: [mongoose.Schema.Types.Mixed], default: [] },
  total: { type: mongoose.Schema.Types.Mixed, default: {} },
  vitaminsAndMinerals: { type: [mongoose.Schema.Types.Mixed], default: [] },
  balance: { type: mongoose.Schema.Types.Mixed, default: {} },
  uncertaintyNotes: { type: String, maxlength: 2000 },
  analysisSource: { type: String, maxlength: 80 },
  isEstimate: { type: Boolean, default: true },
  timestamp: { type: Date, default: Date.now },
}, { timestamps: true, collection: 'meals' });

mealSchema.index({ owner: 1, timestamp: -1 });
module.exports = mongoose.model('Meal', mealSchema);
