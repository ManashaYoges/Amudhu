const { test } = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../app');
const { searchRecipes, searchCatalog } = require('../services/recipeSearchService');

test('Recipe Search: Finds recipes and videos for "bread"', async () => {
  const result = await searchRecipes({ query: 'bread' });
  assert.equal(result.query, 'bread');
  assert.ok(result.recipes.length > 0);
  assert.ok(result.recipes.some((r) => r.name.toLowerCase().includes('bread') || r.name.toLowerCase().includes('toast')));
  assert.ok(result.videos.length > 0);
  assert.ok(result.cuisines.length > 0);
  assert.ok(result.recommendations.length > 0);
});

test('Recipe Search: Finds recipes for "paneer" and filters by Vegetarian diet', async () => {
  const result = await searchRecipes({ query: 'paneer', diet: 'Vegetarian' });
  assert.ok(result.recipes.length > 0);
  assert.ok(result.recipes.every((r) => r.isVegetarian === true));
  assert.ok(result.recipes.some((r) => r.name.toLowerCase().includes('paneer')));
});

test('Recipe Search: Filters recipes by cuisine "Italian"', async () => {
  const result = await searchRecipes({ query: 'pasta', cuisine: 'Italian' });
  assert.ok(result.recipes.length > 0);
  assert.ok(result.recipes.every((r) => r.cuisine.toLowerCase() === 'italian'));
});

test('GET /api/recipes/search endpoint returns structured search results over HTTP', async () => {
  const res = await request(app)
    .get('/api/recipes/search?q=biryani')
    .expect(200);

  assert.equal(res.body.query, 'biryani');
  assert.ok(Array.isArray(res.body.recipes));
  assert.ok(res.body.recipes.length > 0);
  assert.ok(Array.isArray(res.body.videos));
  assert.ok(res.body.videos.length > 0);
  assert.ok(Array.isArray(res.body.cuisines));
  assert.ok(Array.isArray(res.body.recommendations));
});

test('GET /api/recipes/search with empty query returns popular discovery specials', async () => {
  const res = await request(app)
    .get('/api/recipes/search')
    .expect(200);

  assert.ok(Array.isArray(res.body.recipes));
  assert.ok(res.body.recipes.length > 0);
});
