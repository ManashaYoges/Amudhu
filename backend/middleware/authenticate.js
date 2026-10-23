const jwt = require('jsonwebtoken');
const RevokedToken = require('../models/RevokedToken');

async function authenticate(req, res, next) {
  const header = req.get('authorization') || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Authentication required', code: 'AUTH_REQUIRED' });
  }
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET, {
      algorithms: ['HS256'], issuer: 'amudhu-api', audience: 'amudhu-app',
    });
    if (payload.jti && await RevokedToken.exists({ jti: payload.jti, expiresAt: { $gt: new Date() } })) {
      return res.status(401).json({ error: 'Session expired. Please sign in again.', code: 'INVALID_TOKEN' });
    }
    req.userId = payload.sub;
    req.authJti = payload.jti;
    req.authExpiresAt = payload.exp ? new Date(payload.exp * 1000) : undefined;
    next();
  } catch (_) {
    return res.status(401).json({ error: 'Session expired. Please sign in again.', code: 'INVALID_TOKEN' });
  }
}

module.exports = { authenticate };
