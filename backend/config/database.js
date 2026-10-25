const mongoose = require('mongoose');

async function connectDatabase(uri = process.env.MONGODB_URI) {
  if (!uri) throw new Error('MONGODB_URI is required');
  if (mongoose.connection.readyState === 1) {
    return mongoose.connection;
  }
  await mongoose.connect(uri, { dbName: 'amudhu', serverSelectionTimeoutMS: 5000 });
  if (mongoose.connection.readyState !== 1) {
    throw new Error(`Database connection not ready (readyState=${mongoose.connection.readyState})`);
  }
  await mongoose.connection.db.admin().ping();
  return mongoose.connection;
}

module.exports = { connectDatabase };
