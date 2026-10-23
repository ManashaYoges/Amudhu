const mongoose = require('mongoose');

async function connectDatabase(uri = process.env.MONGODB_URI) {
  if (!uri) throw new Error('MONGODB_URI is required');
  await mongoose.connect(uri, { dbName: 'amudhu' });
  return mongoose.connection;
}

module.exports = { connectDatabase };
