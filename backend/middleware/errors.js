function notFound(req, res) {
  res.status(404).json({ error: 'Route not found', code: 'NOT_FOUND' });
}

function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: 'Invalid input', code: 'VALIDATION_ERROR' });
  }
  if (err.name === 'CastError') {
    return res.status(400).json({ error: 'Invalid record ID', code: 'INVALID_ID' });
  }
  if (err.code === 11000) {
    return res.status(409).json({ error: 'An account with this email already exists', code: 'EMAIL_EXISTS' });
  }
  if (err.name === 'MulterError' || err.message?.startsWith('Only image files')) {
    return res.status(400).json({ error: 'Invalid image upload', code: 'INVALID_UPLOAD' });
  }
  if (err.type === 'entity.too.large') {
    return res.status(413).json({ error: 'Request is too large', code: 'PAYLOAD_TOO_LARGE' });
  }
  console.error('Request failed:', err.message);
  return res.status(500).json({ error: 'Internal server error', code: 'SERVER_ERROR' });
}

module.exports = { notFound, errorHandler };
