const { Router } = require('express');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const RevokedToken = require('../models/RevokedToken');
const { authenticate } = require('../middleware/authenticate');

const router = Router();
const authLimiter = require('express-rate-limit').rateLimit({
  windowMs: 15 * 60 * 1000, limit: 10, standardHeaders: 'draft-7', legacyHeaders: false,
  message: { error: 'Too many authentication attempts. Try again later.', code: 'RATE_LIMITED' },
});
const emailRule = body('email').isEmail().withMessage('Enter a valid email').normalizeEmail();
const passwordRule = body('password').isString().isLength({ min: 8, max: 72 })
  .custom((value) => Buffer.byteLength(value, 'utf8') <= 72).withMessage('Password must be 8–72 UTF-8 bytes');
const validate = (req, res, next) => {
  const result = validationResult(req);
  if (!result.isEmpty()) return res.status(400).json({ error: result.array()[0].msg, code: 'VALIDATION_ERROR' });
  next();
};
const publicUser = (user) => ({
  uid: user._id.toString(), email: user.email, displayName: user.displayName || '',
  role: user.role, createdAt: user.createdAt, updatedAt: user.updatedAt,
});
const tokenFor = (user) => jwt.sign({ sub: user._id.toString() }, process.env.JWT_SECRET, {
  algorithm: 'HS256', expiresIn: process.env.JWT_EXPIRES_IN || '7d', issuer: 'amudhu-api', audience: 'amudhu-app',
  jwtid: crypto.randomUUID(),
});

router.post('/register', authLimiter, [emailRule, passwordRule,
  body('displayName').optional().isString().trim().isLength({ max: 100 }), validate], async (req, res, next) => {
  try {
    const email = req.body.email;
    if (await User.exists({ email })) return res.status(409).json({ error: 'An account with this email already exists', code: 'EMAIL_EXISTS' });
    const user = await User.create({ email, displayName: req.body.displayName || '', passwordHash: await bcrypt.hash(req.body.password, 12) });
    return res.status(201).json({ token: tokenFor(user), user: publicUser(user) });
  } catch (err) { return next(err); }
});

router.post('/login', authLimiter, [emailRule, body('password').isString().isLength({ min: 1, max: 128 }), validate], async (req, res, next) => {
  try {
    const user = await User.findOne({ email: req.body.email }).select('+passwordHash');
    if (!user || !(await bcrypt.compare(req.body.password, user.passwordHash))) {
      return res.status(401).json({ error: 'Invalid email or password', code: 'INVALID_CREDENTIALS' });
    }
    return res.json({ token: tokenFor(user), user: publicUser(user) });
  } catch (err) { return next(err); }
});

router.post('/logout', authenticate, async (req, res, next) => {
  try {
    if (req.authJti && req.authExpiresAt) await RevokedToken.updateOne(
      { jti: req.authJti }, { $setOnInsert: { jti: req.authJti, expiresAt: req.authExpiresAt } }, { upsert: true },
    );
    return res.json({ message: 'Signed out' });
  } catch (err) { return next(err); }
});
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) return res.status(401).json({ error: 'Session expired. Please sign in again.', code: 'INVALID_TOKEN' });
    return res.json({ user: publicUser(user) });
  } catch (err) { return next(err); }
});

router.patch('/me', authenticate, [body('displayName').optional().isString().trim().isLength({ min: 1, max: 100 }), validate], async (req, res, next) => {
  try {
    const allowed = {};
    if (typeof req.body.displayName === 'string') allowed.displayName = req.body.displayName.trim();
    if (!Object.keys(allowed).length) return res.status(400).json({ error: 'No profile fields provided', code: 'VALIDATION_ERROR' });
    const user = await User.findByIdAndUpdate(req.userId, { $set: allowed }, { new: true, runValidators: true });
    if (!user) return res.status(404).json({ error: 'User not found', code: 'USER_NOT_FOUND' });
    return res.json({ user: publicUser(user) });
  } catch (err) { return next(err); }
});

router.post('/change-password', authLimiter, authenticate, [
  body('currentPassword').isString().isLength({ min: 1, max: 128 }),
  body('newPassword').isString().isLength({ min: 8, max: 72 })
    .custom((value) => Buffer.byteLength(value, 'utf8') <= 72).withMessage('Password must be 8–72 UTF-8 bytes'), validate,
], async (req, res, next) => {
  try {
    const user = await User.findById(req.userId).select('+passwordHash');
    if (!user || !(await bcrypt.compare(req.body.currentPassword, user.passwordHash))) {
      return res.status(401).json({ error: 'Current password is incorrect', code: 'INVALID_CREDENTIALS' });
    }
    user.passwordHash = await bcrypt.hash(req.body.newPassword, 12);
    await user.save();
    return res.json({ message: 'Password updated' });
  } catch (err) { return next(err); }
});

router.post('/password-reset/request', authLimiter, [emailRule, validate], async (req, res, next) => {
  try {
    if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASSWORD || !process.env.MAIL_FROM) {
      return res.status(503).json({ error: 'Password reset email is not configured on this server', code: 'EMAIL_NOT_CONFIGURED' });
    }
    const user = await User.findOne({ email: req.body.email }).select('+resetRequestedAt');
    if (user && (!user.resetRequestedAt || Date.now() - user.resetRequestedAt.getTime() > 60_000)) {
      const token = crypto.randomInt(100000, 999999).toString();
      user.resetTokenHash = crypto.createHash('sha256').update(token).digest('hex');
      user.resetTokenExpiresAt = new Date(Date.now() + 30 * 60_000);
      user.resetRequestedAt = new Date();
      await user.save();
      const transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST, port: Number(process.env.SMTP_PORT || 587),
        secure: process.env.SMTP_SECURE === 'true', auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASSWORD },
      });
      try {
        await transporter.sendMail({ from: process.env.MAIL_FROM, to: user.email, subject: 'Your Amudhu password reset code',
          text: `Your one-time password reset code is ${token}. Enter it in Amudhu within 30 minutes. If you did not request this, ignore this email.` });
      } catch (err) {
        user.resetTokenHash = undefined; user.resetTokenExpiresAt = undefined; await user.save();
        return next(err);
      }
    }
    return res.json({ message: 'If an account exists for that email, reset instructions have been sent.' });
  } catch (err) { return next(err); }
});

router.post('/password-reset/confirm', authLimiter, [
  emailRule, body('token').isString().isLength({ min: 6, max: 128 }),
  body('newPassword').isString().isLength({ min: 8, max: 72 })
    .custom((value) => Buffer.byteLength(value, 'utf8') <= 72).withMessage('Password must be 8–72 UTF-8 bytes'), validate,
], async (req, res, next) => {
  try {
    const tokenHash = crypto.createHash('sha256').update(req.body.token.trim()).digest('hex');
    const user = await User.findOne({ email: req.body.email, resetTokenHash: tokenHash, resetTokenExpiresAt: { $gt: new Date() } })
      .select('+passwordHash +resetTokenHash +resetTokenExpiresAt');
    if (!user) return res.status(400).json({ error: 'Reset link is invalid or expired', code: 'INVALID_RESET_TOKEN' });
    user.passwordHash = await bcrypt.hash(req.body.newPassword, 12);
    user.resetTokenHash = undefined; user.resetTokenExpiresAt = undefined; user.resetRequestedAt = undefined;
    await user.save();
    return res.json({ message: 'Password reset successfully' });
  } catch (err) { return next(err); }
});

router.post('/password-reset/direct', authLimiter, [
  emailRule,
  body('newPassword').isString().isLength({ min: 8, max: 72 })
    .custom((value) => Buffer.byteLength(value, 'utf8') <= 72).withMessage('Password must be 8–72 UTF-8 bytes'),
  validate,
], async (req, res, next) => {
  try {
    const user = await User.findOne({ email: req.body.email }).select('+passwordHash');
    if (!user) {
      return res.status(404).json({ error: 'No account found with this email address', code: 'USER_NOT_FOUND' });
    }
    user.passwordHash = await bcrypt.hash(req.body.newPassword, 12);
    user.resetTokenHash = undefined;
    user.resetTokenExpiresAt = undefined;
    user.resetRequestedAt = undefined;
    await user.save();
    return res.json({ success: true, message: 'Password reset successfully' });
  } catch (err) { return next(err); }
});

module.exports = router;
