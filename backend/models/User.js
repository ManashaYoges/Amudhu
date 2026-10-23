const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  passwordHash: { type: String, required: true, select: false },
  displayName: { type: String, trim: true, maxlength: 100, default: '' },
  role: { type: String, enum: ['user'], default: 'user', immutable: true },
  resetTokenHash: { type: String, select: false },
  resetTokenExpiresAt: { type: Date, select: false },
  resetRequestedAt: { type: Date, select: false },
}, { timestamps: true, collection: 'users' });

module.exports = mongoose.model('User', userSchema);
