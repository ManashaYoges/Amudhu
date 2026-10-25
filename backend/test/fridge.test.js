const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../app');
const {
  analyzeFridgeImage,
  generateRecipesFromIngredients,
  SMART_FRIDGE_PRESETS,
  CURATED_RECIPE_CATALOG,
} = require('../services/fridgeService');

test('Fridge Service: Fallback analyzes image buffer without crash and returns valid presets', async () => {
  const dummyBuffer = Buffer.from('test-fake-fridge-image-data-1234567890');
  const result = await analyzeFridgeImage({ buffer: dummyBuffer, mimeType: 'image/jpeg' });

  assert.equal(result.success, true);
  assert.equal(result.isFridgeOrFood, true);
  assert.ok(Array.isArray(result.ingredients));
  assert.ok(result.ingredients.length > 0);
  assert.ok(result.ingredients[0].name);
  assert.ok(result.ingredients[0].emoji);
});

test('Fridge Service: Generates ranked recipes from available user ingredients', async () => {
  const ingredients = [
    { name: 'Eggs', quantity: '4 eggs', emoji: '🥚' },
    { name: 'Tomatoes', quantity: '2 ripe', emoji: '🍅' },
    { name: 'Spinach', quantity: '1 bunch', emoji: '🥬' },
  ];

  const result = await generateRecipesFromIngredients({ ingredients });

  assert.equal(result.success, true);
  assert.ok(Array.isArray(result.recipes));
  assert.ok(result.recipes.length > 0);

  // Top recipe should have matched ingredients
  const top = result.recipes[0];
  assert.ok(top.name);
  assert.ok(top.matchedCount > 0);
  assert.ok(top.ingredients.some((i) => i.isFromFridge === true));
  assert.ok(top.steps.length > 0);
  assert.ok(top.nutrition.calories > 0);
  assert.ok(top.videoUrl.includes('youtube.com'));
});

test('POST /api/analyze-fridge endpoint accepts image upload and returns ingredients', async () => {
  const fakeImageBuffer = Buffer.from('fake-jpeg-binary-stream-for-testing-only');

  const res = await request(app)
    .post('/api/analyze-fridge')
    .attach('image', fakeImageBuffer, 'fridge_test.jpg')
    .expect(200);

  assert.equal(res.body.success, true);
  assert.ok(Array.isArray(res.body.ingredients));
  assert.ok(res.body.ingredients.length >= 4);
});

test('POST /api/generate-recipes endpoint generates matching recipes for ingredients array', async () => {
  const res = await request(app)
    .post('/api/generate-recipes')
    .send({
      ingredients: [
        { name: 'Paneer', quantity: '200g' },
        { name: 'Spinach', quantity: '1 bunch' },
      ],
    })
    .expect(200);

  assert.equal(res.body.success, true);
  assert.ok(Array.isArray(res.body.recipes));
  assert.ok(res.body.recipes.length > 0);
  // Recipe should match Palak Paneer or Paneer Bhurji
  assert.ok(res.body.recipes.some((r) => r.name.toLowerCase().includes('paneer')));
});
