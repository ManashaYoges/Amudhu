const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema({
  role: { type: String, enum: ['user', 'assistant', 'system'], required: true },
  content: { type: String, required: true, maxlength: 6000 },
  timestamp: { type: Date, default: Date.now },
  context: { type: mongoose.Schema.Types.Mixed },
  isError: { type: Boolean, default: false },
}, { _id: false });

const conversationSchema = new mongoose.Schema({
  sessionId: { type: String, required: true, index: true },
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true, default: null },
  messages: { type: [chatMessageSchema], default: [] },
  summary: { type: String, maxlength: 500 },
}, { timestamps: true, collection: 'conversations' });

conversationSchema.index({ owner: 1, updatedAt: -1 });

module.exports = mongoose.model('Conversation', conversationSchema);
