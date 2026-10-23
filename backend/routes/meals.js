const { Router } = require('express');
const mongoose = require('mongoose');
const Meal = require('../models/Meal');
const { authenticate } = require('../middleware/authenticate');

const router = Router();
router.use(authenticate);

function validateMeal(body) {
  return body && typeof body.mealName === 'string' && body.mealName.trim().length > 0 &&
    body.mealName.length <= 160 && Array.isArray(body.foods) && body.foods.length <= 100 &&
    (body.total === undefined || (body.total && typeof body.total === 'object' && !Array.isArray(body.total)));
}

router.get('/', async (req, res, next) => {
  try {
    const meals = await Meal.find({ owner: req.userId }).sort({ timestamp: -1 }).limit(200).lean();
    res.json({ meals: meals.map(({ owner, __v, ...meal }) => ({ ...meal, id: meal._id.toString() })) });
  } catch (err) { next(err); }
});

router.post('/', async (req, res, next) => {
  try {
    if (!validateMeal(req.body)) return res.status(400).json({ error: 'Meal name and foods are required', code: 'VALIDATION_ERROR' });
    const { mealName, foods, total, vitaminsAndMinerals, balance, uncertaintyNotes, analysisSource, isEstimate, timestamp } = req.body;
    const meal = await Meal.create({ owner: req.userId, mealName: mealName.trim(), foods, total, vitaminsAndMinerals,
      balance, uncertaintyNotes, analysisSource, isEstimate: isEstimate !== false,
      timestamp: timestamp && Number.isFinite(Date.parse(timestamp)) ? new Date(timestamp) : new Date() });
    res.status(201).json({ meal: { ...meal.toObject(), owner: undefined, id: meal._id.toString() } });
  } catch (err) { next(err); }
});

router.patch('/:id', async (req, res, next) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Invalid record ID', code: 'INVALID_ID' });
    if (!validateMeal(req.body)) return res.status(400).json({ error: 'Meal name and foods are required', code: 'VALIDATION_ERROR' });
    const { mealName, foods, total, vitaminsAndMinerals, balance, uncertaintyNotes, analysisSource, isEstimate, timestamp } = req.body;
    const meal = await Meal.findOneAndUpdate({ _id: req.params.id, owner: req.userId }, { $set: {
      mealName: mealName.trim(), foods, total, vitaminsAndMinerals, balance, uncertaintyNotes, analysisSource,
      isEstimate: isEstimate !== false, ...(timestamp ? { timestamp } : {}),
    } }, { new: true, runValidators: true });
    if (!meal) return res.status(404).json({ error: 'Meal not found', code: 'MEAL_NOT_FOUND' });
    res.json({ meal: { ...meal.toObject(), owner: undefined, id: meal._id.toString() } });
  } catch (err) { next(err); }
});

router.delete('/:id', async (req, res, next) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) return res.status(400).json({ error: 'Invalid record ID', code: 'INVALID_ID' });
    const meal = await Meal.findOneAndDelete({ _id: req.params.id, owner: req.userId });
    if (!meal) return res.status(404).json({ error: 'Meal not found', code: 'MEAL_NOT_FOUND' });
    res.status(204).end();
  } catch (err) { next(err); }
});

module.exports = router;
