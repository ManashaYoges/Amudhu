const dns = require("node:dns");
dns.setServers(["1.1.1.1", "8.8.8.8"]);
require('dotenv').config();
const os = require('os');
const app = require('./app');
const { connectDatabase } = require('./config/database');

const port = Number(process.env.PORT || 3000);
function localAddress() {
  for (const group of Object.values(os.networkInterfaces())) {
    for (const iface of group || []) if (iface.family === 'IPv4' && !iface.internal) return iface.address;
  }
  return 'localhost';
}

async function start() {
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    throw new Error('JWT_SECRET must contain at least 32 characters');
  }

  app.listen(port, () => {
    console.log(`Amudhu API listening on port ${port}`);
    console.log(`Desktop: http://localhost:${port}`);
    console.log(`Android emulator: http://10.0.2.2:${port}`);
    console.log(`Physical Android phone: http://${localAddress()}:${port}`);
  });

  try {
    await connectDatabase();
    console.log('[Database] Connected to MongoDB Atlas successfully.');
  } catch (err) {
    console.warn(`[Database] Notice: Initial MongoDB Atlas connection failed (${err.message}). Ensure your IP is whitelisted in Atlas. The server will continue running and retry.`);
    const retryInterval = setInterval(async () => {
      try {
        await connectDatabase();
        console.log('[Database] Connected to MongoDB Atlas successfully on retry!');
        clearInterval(retryInterval);
      } catch (_) {}
    }, 15000);
  }
}

if (require.main === module) {
  start().catch((err) => { console.error(`Startup failed: ${err.message}`); process.exit(1); });
}

module.exports = { start };
