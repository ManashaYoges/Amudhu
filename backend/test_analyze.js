/**
 * CLI Tool to test genuine meal images against the Amudhu AI Vision & Nutrition Pipeline.
 * Usage: node test_analyze.js <path-to-image-file>
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { processFoodImage } = require('./services/visionService');

async function main() {
  const imageArg = process.argv[2];
  if (!imageArg) {
    console.log('Usage: node test_analyze.js <path-to-meal-image>');
    console.log('Example: node test_analyze.js sample_meal.jpg');
    process.exit(1);
  }

  const resolvedPath = path.resolve(imageArg);
  if (!fs.existsSync(resolvedPath)) {
    console.error(`Error: File does not exist at "${resolvedPath}"`);
    process.exit(1);
  }

  const apiKey = process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY;
  if (!apiKey) {
    console.error('Error: No API key found. Please set GEMINI_API_KEY in backend/.env');
    process.exit(1);
  }

  const buffer = fs.readFileSync(resolvedPath);
  const ext = path.extname(resolvedPath).toLowerCase();
  const mimeType = ext === '.png' ? 'image/png' : (ext === '.webp' ? 'image/webp' : 'image/jpeg');

  console.log(`Analyzing meal photo: ${path.basename(resolvedPath)} (${(buffer.length / 1024).toFixed(1)} KB)...`);
  console.log('Sending pixels to AI Vision model with nutrition engine...');

  const start = Date.now();
  const result = await processFoodImage({
    buffer,
    mimeType,
    apiKey,
    provider: process.env.AI_PROVIDER || 'gemini',
    model: process.env.GEMINI_MODEL || 'gemini-1.5-flash'
  });
  const elapsed = ((Date.now() - start) / 1000).toFixed(2);

  console.log(`\n=== Analysis Complete (${elapsed}s) ===`);
  console.log(JSON.stringify(result, null, 2));
}

main().catch(err => {
  console.error('\nAnalysis Error:', err.message);
  process.exit(1);
});
