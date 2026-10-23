const express = require('express');
const { body, validationResult } = require('express-validator');
const rateLimit = require('express-rate-limit');
const mongoose = require('mongoose');
const { processChatMessage } = require('../services/chatService');
const { optionalAuthenticate } = require('../middleware/authenticate');
const Conversation = require('../models/Conversation');

const router = express.Router();

const chatLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many messages sent. Please pause and try again in a few minutes.', code: 'RATE_LIMIT_EXCEEDED' },
});

/**
 * POST /api/chat
 * Primary endpoint for conversational AI answers
 */
router.post(
  '/',
  chatLimiter,
  optionalAuthenticate,
  [
    body('message').isString().trim().isLength({ min: 1, max: 2000 }).withMessage('Message must be between 1 and 2000 characters.'),
    body('conversationId').optional().isString().trim().isLength({ max: 120 }),
    body('history').optional().isArray({ max: 50 }).withMessage('History must be an array of at most 50 messages.'),
    body('history.*.role').optional().isIn(['user', 'assistant', 'model', 'system']),
    body('history.*.content').optional().isString().isLength({ max: 4000 }),
    body('context').optional().isObject(),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: errors.array()[0].msg, code: 'VALIDATION_ERROR' });
    }

    const { message, context = {} } = req.body;
    let { conversationId } = req.body;
    const history = Array.isArray(req.body.history) ? req.body.history : [];

    if (!conversationId) {
      conversationId = `chat_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
    }

    // Attach user profile display name if logged in
    if (req.userId && !context.userDisplayName) {
      try {
        const User = mongoose.model('User');
        const user = await User.findById(req.userId).select('displayName');
        if (user?.displayName) context.userDisplayName = user.displayName;
      } catch (_) {}
    }

    try {
      const result = await processChatMessage({
        message,
        history,
        context,
      });

      // Persist to MongoDB if connected
      if (mongoose.connection.readyState === 1) {
        try {
          await Conversation.findOneAndUpdate(
            { sessionId: conversationId },
            {
              $setOnInsert: { sessionId: conversationId, owner: req.userId || null },
              $push: {
                messages: [
                  { role: 'user', content: message, timestamp: new Date(), context },
                  { role: 'assistant', content: result.reply, timestamp: new Date() },
                ],
              },
            },
            { upsert: true, new: true }
          );
        } catch (dbErr) {
          // Non-blocking: chat shouldn't fail if persistence encounters an error
          console.warn('[Chat] Failed to persist conversation history to database:', dbErr.message);
        }
      }

      return res.json({
        success: true,
        reply: result.reply,
        conversationId,
        isAiGenerated: result.isAiGenerated,
        provider: result.provider,
        model: result.model,
      });
    } catch (err) {
      const isRateLimit = /quota|rate/i.test(err.message);
      const isTimeout = /timeout|abort/i.test(err.message);
      const status = isRateLimit ? 429 : isTimeout ? 504 : 502;

      console.error('[Chat Error]:', err.message);
      return res.status(status).json({
        error: isRateLimit
          ? 'AI rate limit reached. Please wait a moment before asking again.'
          : isTimeout
          ? 'Request to AI assistant timed out. Please try again.'
          : 'Could not generate an AI response right now. Please try again.',
        code: isRateLimit ? 'RATE_LIMIT_EXCEEDED' : isTimeout ? 'GATEWAY_TIMEOUT' : 'AI_SERVICE_ERROR',
      });
    }
  }
);

/**
 * GET /api/chat/history/:conversationId?
 * Retrieves conversation history from MongoDB
 */
router.get('/history/:conversationId?', optionalAuthenticate, async (req, res) => {
  if (mongoose.connection.readyState !== 1) {
    return res.json({ success: true, messages: [] });
  }

  const { conversationId } = req.params;
  try {
    const query = conversationId
      ? { sessionId: conversationId }
      : req.userId
      ? { owner: req.userId }
      : null;

    if (!query) return res.json({ success: true, messages: [] });

    const conversation = await Conversation.findOne(query).sort({ updatedAt: -1 }).lean();
    return res.json({
      success: true,
      conversationId: conversation?.sessionId || conversationId || null,
      messages: conversation?.messages || [],
    });
  } catch (err) {
    return res.status(500).json({ error: 'Could not load conversation history', code: 'DATABASE_ERROR' });
  }
});

/**
 * DELETE /api/chat/history/:conversationId
 * Clears a conversation session
 */
router.delete('/history/:conversationId', optionalAuthenticate, async (req, res) => {
  if (mongoose.connection.readyState !== 1) {
    return res.json({ success: true, cleared: true });
  }

  const { conversationId } = req.params;
  try {
    const query = { sessionId: conversationId };
    if (req.userId) query.$or = [{ owner: req.userId }, { owner: null }];
    await Conversation.deleteOne(query);
    return res.json({ success: true, cleared: true });
  } catch (err) {
    return res.status(500).json({ error: 'Could not clear conversation history', code: 'DATABASE_ERROR' });
  }
});

module.exports = router;
