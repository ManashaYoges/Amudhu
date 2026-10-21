/**
 * Comprehensive Validation Test Suite for Amudhu Smart Plate
 * Verifies:
 * 1. Recognition and nutrition pipeline on 7 meal scenarios
 * 2. Cooked-food nutrient formulas: nutrient = (nutrient_per_100g * grams) / 100
 * 3. Portion scaling consistency
 * 4. Structured JSON response schemas
 * 5. Uncertainty and alternatives handling
 * 6. Error honesty (no disguised fake results)
 * 7. Recalculation after user edits and additions
 */

const assert = require('assert');
const {
  FOOD_DATABASE,
  findFoodMatch,
  calculateItemNutrients,
  calculateMealNutrition
} = require('./services/nutritionDatabase');
const { processFoodImage, VISION_SYSTEM_PROMPT } = require('./services/visionService');

let totalTests = 0;
let passedTests = 0;

function runTest(name, fn) {
  totalTests++;
  try {
    fn();
    console.log(`  ✓ [PASS] ${name}`);
    passedTests++;
  } catch (err) {
    console.error(`  ✗ [FAIL] ${name}`);
    console.error(`    Error: ${err.message}`);
  }
}

async function runAsyncTest(name, fn) {
  totalTests++;
  try {
    await fn();
    console.log(`  ✓ [PASS] ${name}`);
    passedTests++;
  } catch (err) {
    console.error(`  ✗ [FAIL] ${name}`);
    console.error(`    Error: ${err.message}`);
  }
}

async function main() {
  console.log('===============================================================');
  console.log('AMUDHU SMART PLATE: RECOGNITION & NUTRITION VERIFICATION SUITE');
  console.log('===============================================================\n');

  console.log('--- TEST GROUP 1: FOOD RECOGNITION & NUTRITION PIPELINE (7 SCENARIOS) ---');

  // Scenario 1: Rice and Dal
  runTest('Scenario 1: Rice and dal pipeline', () => {
    const rawItems = [
      { name: 'Cooked white rice', estimatedGrams: 180, confidence: 0.94 },
      { name: 'Cooked lentil dal', estimatedGrams: 120, confidence: 0.88, alternatives: ['Yellow dal'] }
    ];
    const result = calculateMealNutrition(rawItems);

    assert.strictEqual(result.foods.length, 2);
    // Rice: 130 * 1.8 = 234 kcal
    assert.strictEqual(result.foods[0].calories, 234);
    assert.strictEqual(result.foods[0].protein, 4.9);
    assert.strictEqual(result.foods[0].portionIsEstimated, true);
    // Dal: 116 * 1.2 = 139 kcal
    assert.strictEqual(result.foods[1].calories, 139);
    assert.strictEqual(result.foods[1].protein, 8.8);
    // Total calories = 234 + 139 = 373 kcal
    assert.strictEqual(result.total.calories, 373);
    assert.strictEqual(result.total.protein, 13.7);
    assert.ok(result.balance.score >= 40 && result.balance.score <= 95);
  });

  // Scenario 2: Idli with chutney or sambar
  runTest('Scenario 2: Idli with chutney or sambar', () => {
    const rawItems = [
      { name: 'Steamed Idli', estimatedGrams: 120, confidence: 0.95 },
      { name: 'Vegetable sambar', estimatedGrams: 100, confidence: 0.86 },
      { name: 'Coconut chutney', estimatedGrams: 30, confidence: 0.89 }
    ];
    const result = calculateMealNutrition(rawItems);

    assert.strictEqual(result.foods.length, 3);
    // Idli: 138 * 1.2 = 166 kcal
    assert.strictEqual(result.foods[0].calories, 166);
    // Sambar: 78 * 1.0 = 78 kcal
    assert.strictEqual(result.foods[1].calories, 78);
    // Chutney: 210 * 0.3 = 63 kcal
    assert.strictEqual(result.foods[2].calories, 63);
    // Sum = 166 + 78 + 63 = 307 kcal
    assert.strictEqual(result.total.calories, 307);
    assert.ok(result.total.carbs > 35);
  });

  // Scenario 3: Dosa with chutney and sambar
  runTest('Scenario 3: Dosa with chutney & sambar', () => {
    const rawItems = [
      { name: 'Plain Dosa', estimatedGrams: 100, confidence: 0.92 },
      { name: 'Tomato chutney', estimatedGrams: 40, confidence: 0.84 },
      { name: 'Vegetable sambar', estimatedGrams: 120, confidence: 0.88 }
    ];
    const result = calculateMealNutrition(rawItems);

    assert.strictEqual(result.foods.length, 3);
    assert.strictEqual(result.foods[0].name, 'Plain Dosa');
    assert.strictEqual(result.foods[0].calories, 168);
    assert.strictEqual(result.foods[1].calories, 34);
    assert.strictEqual(result.foods[2].calories, 94);
    assert.strictEqual(result.total.calories, 168 + 34 + 94);
  });

  // Scenario 4: Chapati with a visible curry
  runTest('Scenario 4: Chapati with Palak Paneer curry', () => {
    const rawItems = [
      { name: 'Whole wheat chapati', estimatedGrams: 70, confidence: 0.91 },
      { name: 'Palak Paneer', estimatedGrams: 140, confidence: 0.85 }
    ];
    const result = calculateMealNutrition(rawItems);

    assert.strictEqual(result.foods.length, 2);
    // Chapati: 264 * 0.7 = 185 kcal
    assert.strictEqual(result.foods[0].calories, 185);
    // Palak Paneer: 155 * 1.4 = 217 kcal
    assert.strictEqual(result.foods[1].calories, 217);
    // Rich in protein: 9.2 * 0.7 + 8.2 * 1.4 = 6.4 + 11.5 = 17.9g
    assert.strictEqual(result.total.protein, 17.9);
    assert.strictEqual(result.total.calories, 402);
  });

  // Scenario 5: Multi-item plate (South Indian Thali)
  runTest('Scenario 5: Multi-item plate (Rice, Dal, Sambar, Poriyal, Curd, Papad)', () => {
    const rawItems = [
      { name: 'Cooked white rice', estimatedGrams: 180, confidence: 0.95 },
      { name: 'Cooked lentil dal', estimatedGrams: 100, confidence: 0.90 },
      { name: 'Vegetable sambar', estimatedGrams: 120, confidence: 0.88 },
      { name: 'Beans Poriyal', estimatedGrams: 90, confidence: 0.87 },
      { name: 'Curd / Yogurt', estimatedGrams: 100, confidence: 0.92 },
      { name: 'Papad / Papadum', estimatedGrams: 15, confidence: 0.91 }
    ];
    const result = calculateMealNutrition(rawItems);

    assert.strictEqual(result.foods.length, 6);
    assert.ok(result.total.calories > 500 && result.total.calories < 650);
    assert.ok(result.total.protein >= 20.0);
    assert.ok(result.total.fiber >= 10.0);
    // Balanced score should be high for this diverse thali
    assert.ok(result.balance.score >= 80);
    assert.strictEqual(result.balance.status, 'Well Balanced!');
  });

  // Scenario 6: Mixed dish (Vegetable biryani + Raita)
  runTest('Scenario 6: Mixed dish (Vegetable biryani with Raita)', () => {
    const rawItems = [
      { name: 'Vegetable biryani', estimatedGrams: 220, confidence: 0.91 },
      { name: 'Cucumber & Onion Raita', estimatedGrams: 80, confidence: 0.88 }
    ];
    const result = calculateMealNutrition(rawItems);

    assert.strictEqual(result.foods.length, 2);
    // Biryani: 152 * 2.2 = 334 kcal
    assert.strictEqual(result.foods[0].calories, 334);
    // Raita: 52 * 0.8 = 42 kcal
    assert.strictEqual(result.foods[1].calories, 42);
    assert.strictEqual(result.total.calories, 376);
  });

  // Scenario 7: Blurry / low evidence meal with uncertainty notes
  runTest('Scenario 7: Uncertain meal with low confidence & notes', () => {
    const rawItems = [
      {
        name: 'Vegetable sambar',
        estimatedGrams: 120,
        confidence: 0.58,
        alternatives: ['Tomato rasam', 'Dal tadka'],
        notes: 'Photo is poorly lit. Gravy appears red-orange with possible vegetables.'
      }
    ];
    const result = calculateMealNutrition(rawItems);

    assert.strictEqual(result.foods.length, 1);
    assert.strictEqual(result.foods[0].confidence, 0.58);
    assert.deepStrictEqual(result.foods[0].alternatives, ['Tomato rasam', 'Dal tadka']);
    assert.ok(result.foods[0].notes.includes('poorly lit'));
  });

  console.log('\n--- TEST GROUP 2: COOKED FOODS VS RAW FOOD NUTRITION ---');

  runTest('Cooked rice uses cooked nutrition (~130 kcal/100g), not raw rice (~365 kcal)', () => {
    const match = findFoodMatch('Cooked white rice');
    assert.strictEqual(match.caloriesPer100g, 130);
    assert.strictEqual(match.isCooked, true);
  });

  runTest('Cooked dal uses cooked nutrition (~116 kcal/100g), not raw dry lentils (~340 kcal)', () => {
    const match = findFoodMatch('Cooked lentil dal');
    assert.strictEqual(match.caloriesPer100g, 116);
    assert.strictEqual(match.isCooked, true);
  });

  console.log('\n--- TEST GROUP 3: SYSTEM PROMPT & ANTI-HALLUCINATION RULES ---');

  runTest('Prompt explicitly forbids inventing eggs, meat, invisible oils, or hidden spices', () => {
    assert.ok(VISION_SYSTEM_PROMPT.includes('NO HALLUCINATION'));
    assert.ok(VISION_SYSTEM_PROMPT.includes('do NOT invent boiled egg, meat'));
    assert.ok(VISION_SYSTEM_PROMPT.includes('Do NOT list invisible hidden ingredients, cooking oils'));
    assert.ok(VISION_SYSTEM_PROMPT.includes('South Indian and Indian cuisine'));
    assert.ok(VISION_SYSTEM_PROMPT.includes('portion estimates'));
  });

  console.log('\n--- TEST GROUP 4: ERROR HONESTY & RESILIENCE ---');

  await runAsyncTest('Vision service throws without fake fallback when image buffer is empty', async () => {
    let threw = false;
    try {
      await processFoodImage({ buffer: Buffer.alloc(0), apiKey: 'test' });
    } catch (err) {
      threw = true;
      assert.ok(err.message.includes('No image data'));
    }
    assert.strictEqual(threw, true);
  });

  console.log('\n--- TEST GROUP 5: RECALCULATION & DYNAMIC USER CORRECTION ---');

  runTest('User edit recalculates total nutrients accurately', () => {
    const initial = [
      { name: 'Cooked white rice', estimatedGrams: 100 }
    ];
    const res1 = calculateMealNutrition(initial);
    assert.strictEqual(res1.total.calories, 130);

    // User updates portion from 100g to 250g
    const updated = [
      { name: 'Cooked white rice', estimatedGrams: 250 }
    ];
    const res2 = calculateMealNutrition(updated);
    // 130 * 2.5 = 325 kcal
    assert.strictEqual(res2.total.calories, 325);
    assert.strictEqual(res2.total.protein, 6.8);
    assert.strictEqual(res2.total.carbs, 70.5);
  });

  runTest('User adding food item increases calories and protein consistently', () => {
    const initial = [
      { name: 'Whole wheat chapati', estimatedGrams: 70 } // 185 kcal, 6.4g protein
    ];
    const res1 = calculateMealNutrition(initial);

    // User adds 1 boiled egg (50g)
    const withEgg = [
      ...initial,
      { name: 'Boiled Egg', estimatedGrams: 50 } // 78 kcal, 6.3g protein
    ];
    const res2 = calculateMealNutrition(withEgg);

    assert.strictEqual(res2.foods.length, 2);
    assert.strictEqual(res2.total.calories, res1.total.calories + 78);
    assert.strictEqual(res2.total.protein, parseFloat((res1.total.protein + 6.3).toFixed(1)));
  });

  runTest('User removing food item decreases meal totals', () => {
    const foods = [
      { name: 'Cooked white rice', estimatedGrams: 180 },
      { name: 'Curd / Yogurt', estimatedGrams: 100 }
    ];
    const res1 = calculateMealNutrition(foods);

    // User removes curd
    const afterRemoval = [foods[0]];
    const res2 = calculateMealNutrition(afterRemoval);

    assert.strictEqual(res2.foods.length, 1);
    assert.strictEqual(res2.total.calories, 234);
    assert.ok(res2.total.calories < res1.total.calories);
  });

  console.log('\n===============================================================');
  console.log(`RESULTS: ${passedTests} / ${totalTests} TESTS PASSED`);
  console.log('===============================================================');

  if (passedTests !== totalTests) {
    process.exit(1);
  }
}

main().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
