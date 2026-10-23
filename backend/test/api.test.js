const { before, test } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const request = require('supertest');

let app;
let User;
let Meal;
let RevokedToken;
let firstToken;
let secondToken;
let mealId;
const users = new Map();
const meals = new Map();
const revoked = new Set();

function makeUser(data) {
  const user = { _id: new mongoose.Types.ObjectId(), role: 'user', createdAt: new Date(), updatedAt: new Date(), ...data };
  user.save = async () => { users.set(user.email, user); return user; };
  return user;
}

before(() => {
  process.env.JWT_SECRET = 'test-secret-that-is-long-enough-for-local-tests-only';
  process.env.NODE_ENV = 'test';
  app = require('../app');
  User = require('../models/User');
  Meal = require('../models/Meal');
  RevokedToken = require('../models/RevokedToken');

  User.exists = async ({ email }) => users.has(email) ? { _id: users.get(email)._id } : null;
  User.create = async (data) => { const user = makeUser(data); users.set(user.email, user); return user; };
  User.findOne = (query) => ({ select: async () => [...users.values()].find((user) =>
    (!query.email || user.email === query.email) && (!query.resetTokenHash || user.resetTokenHash === query.resetTokenHash) &&
    (!query.resetTokenExpiresAt || user.resetTokenExpiresAt > query.resetTokenExpiresAt.$gt)) || null });
  User.findById = async (id) => [...users.values()].find((user) => String(user._id) === String(id)) || null;
  User.findByIdAndUpdate = async (id, update) => {
    const user = [...users.values()].find((candidate) => String(candidate._id) === String(id));
    if (!user) return null;
    Object.assign(user, update.$set, { updatedAt: new Date() });
    return user;
  };

  Meal.find = (filter) => ({ sort() { return this; }, limit() { return this; }, lean: async () =>
    [...meals.values()].filter((meal) => String(meal.owner) === String(filter.owner)).map(({ owner, ...meal }) => ({ ...meal, owner })) });
  Meal.create = async (data) => {
    const meal = { _id: new mongoose.Types.ObjectId(), createdAt: new Date(), updatedAt: new Date(), ...data,
      toObject() { return { ...this }; } };
    meals.set(String(meal._id), meal);
    return meal;
  };
  Meal.findOneAndUpdate = async (filter, update) => {
    const meal = meals.get(String(filter._id));
    if (!meal || String(meal.owner) !== String(filter.owner)) return null;
    Object.assign(meal, update.$set, { updatedAt: new Date() });
    return meal;
  };
  Meal.findOneAndDelete = async (filter) => {
    const meal = meals.get(String(filter._id));
    if (!meal || String(meal.owner) !== String(filter.owner)) return null;
    meals.delete(String(filter._id));
    return meal;
  };
  RevokedToken.exists = async ({ jti }) => revoked.has(jti) ? { jti } : null;
  RevokedToken.updateOne = async (filter) => { revoked.add(filter.jti); return { acknowledged: true }; };
});

test('health check reports API and database status without credentials', async () => {
  const response = await request(app).get('/api/health').expect(200);
  assert.equal(response.body.status, 'online');
  assert.equal(response.body.database, 'disconnected');
  assert.equal('MONGODB_URI' in response.body, false);
});

test('authentication requires a bearer token and validates registration input', async () => {
  await request(app).get('/api/auth/me').expect(401);
  await request(app).post('/api/auth/register').send({ email: 'bad-email', password: 'short' }).expect(400);
  await request(app).post('/api/auth/register').send({ email: 'test@example.com', password: 'SecurePass123', displayName: 'Amudhu User' }).expect(201)
    .expect(({ body }) => {
      firstToken = body.token;
      assert.equal(body.user.email, 'test@example.com');
      assert.equal('passwordHash' in body.user, false);
    });
  const stored = users.get('test@example.com');
  assert.notEqual(stored.passwordHash, 'SecurePass123');
  assert.ok(stored.passwordHash.startsWith('$2'));
  await request(app).post('/api/auth/register').send({ email: 'test@example.com', password: 'SecurePass123' }).expect(409);
});

test('login returns a token and invalid credentials reveal no account details', async () => {
  await request(app).post('/api/auth/login').send({ email: 'test@example.com', password: 'wrong-password' })
    .expect(401).expect(({ body }) => assert.equal(body.code, 'INVALID_CREDENTIALS'));
  const response = await request(app).post('/api/auth/login').send({ email: 'test@example.com', password: 'SecurePass123' }).expect(200);
  firstToken = response.body.token;
  assert.ok(firstToken);
});

test('current profile is protected and only accepts public profile fields', async () => {
  const profile = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${firstToken}`).expect(200);
  assert.equal(profile.body.user.displayName, 'Amudhu User');
  const update = await request(app).patch('/api/auth/me').set('Authorization', `Bearer ${firstToken}`)
    .send({ displayName: 'Updated Name', role: 'admin' }).expect(200);
  assert.equal(update.body.user.displayName, 'Updated Name');
  assert.equal(update.body.user.role, 'user');
});

test('password reset reports missing SMTP configuration instead of claiming email delivery', async () => {
  delete process.env.SMTP_HOST;
  delete process.env.SMTP_USER;
  delete process.env.SMTP_PASSWORD;
  delete process.env.MAIL_FROM;
  await request(app).post('/api/auth/password-reset/request').send({ email: 'test@example.com' }).expect(503)
    .expect(({ body }) => assert.equal(body.code, 'EMAIL_NOT_CONFIGURED'));
});

test('meal CRUD is owner-scoped and rejects invalid input', async () => {
  const second = await request(app).post('/api/auth/register').send({ email: 'other@example.com', password: 'OtherPass123' }).expect(201);
  secondToken = second.body.token;
  await request(app).post('/api/meals').set('Authorization', `Bearer ${firstToken}`).send({ mealName: '', foods: [] }).expect(400);
  const created = await request(app).post('/api/meals').set('Authorization', `Bearer ${firstToken}`).send({
    mealName: 'Rice and dal', foods: [{ name: 'Rice' }], total: { calories: 350 }, timestamp: new Date().toISOString(),
  }).expect(201);
  mealId = created.body.meal.id;
  assert.equal('owner' in created.body.meal, false);
  await request(app).get('/api/meals').set('Authorization', `Bearer ${firstToken}`).expect(200)
    .expect(({ body }) => assert.equal(body.meals.length, 1));
  await request(app).get('/api/meals').set('Authorization', `Bearer ${secondToken}`).expect(200)
    .expect(({ body }) => assert.equal(body.meals.length, 0));
  const payload = { mealName: 'Taken over', foods: [{ name: 'Rice' }], total: {} };
  await request(app).patch(`/api/meals/${mealId}`).set('Authorization', `Bearer ${secondToken}`).send(payload).expect(404);
  await request(app).patch(`/api/meals/${mealId}`).set('Authorization', `Bearer ${firstToken}`).send({ ...payload, mealName: 'Updated meal' }).expect(200);
  await request(app).delete(`/api/meals/${mealId}`).set('Authorization', `Bearer ${secondToken}`).expect(404);
  await request(app).delete(`/api/meals/${mealId}`).set('Authorization', `Bearer ${firstToken}`).expect(204);
});

test('logout revokes the bearer token', async () => {
  await request(app).post('/api/auth/logout').set('Authorization', `Bearer ${firstToken}`).expect(200);
  await request(app).get('/api/auth/me').set('Authorization', `Bearer ${firstToken}`).expect(401);
});

test('nutrition recalculation endpoint remains available and validates input', async () => {
  await request(app).post('/api/recalculate').send({ foods: 'not-an-array' }).expect(400);
  const response = await request(app).post('/api/recalculate').send({ foods: [{ name: 'Cooked white rice', estimatedGrams: 100 }] }).expect(200);
  assert.equal(response.body.total.calories, 130);
  assert.equal(response.body.analysisSource, 'user_edited');
});
