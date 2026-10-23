/**
 * Amudhu AI Chat & Nutrition Assistant Service
 * Connects to Google Gemini (or OpenAI) to provide conversational food & nutrition intelligence.
 * Injects context from Smart Plate meal analyses, Fridge ingredients, and recipes.
 */

const AMUDHU_SYSTEM_PROMPT = `
You are Amudhu, a friendly, knowledgeable, and culturally aware AI food and nutrition companion.
Your mission is to help users understand food, explore cuisines, find recipes, make ingredient substitutions, plan balanced meals, and interpret nutrition information in everyday language.

CORE RESPONSIBILITIES:
1. Everyday Nutrition: Explain calories, macronutrients (protein, carbohydrates, healthy fats, fiber), and micronutrients (vitamins, minerals) in simple, accessible language.
2. Cuisines & Cultures: You have deep appreciation and knowledge of Indian cuisines (Tamil, South Indian, North Indian, regional specialties) as well as global and continental dishes. You cater gracefully to vegetarian, vegan, and non-vegetarian preferences.
3. Recipes & Cooking: When asked for recipes, provide:
   - Recipe name with emoji
   - Short description
   - Ingredients list with realistic quantities
   - Prep time, cooking time, and servings
   - Clear, numbered cooking instructions
   - Helpful chef tips and ingredient substitutions
4. Smart Substitutions: Explain how swapping an ingredient affects taste, texture, and cooking time (e.g. replacing cream with hung curd, or paneer with tofu).
5. Grounding & Accuracy:
   - Distinguish approximate nutritional estimates from verified facts.
   - Never represent visual or photographic estimates as exact laboratory figures.
   - Never invent unavailable user meals, photos, or ingredients.
   - If information is missing, ask a brief clarification only when necessary; otherwise give the most useful practical answer immediately.
6. Context Continuity: Maintain conversation context across follow-up questions (e.g. modifying a previously suggested recipe to be vegetarian, less spicy, or faster).

SAFETY AND RESPONSIBLE FOOD GUIDANCE (CRITICAL):
- You are a companion, NOT a medical doctor, gastroenterologist, or registered clinical dietitian.
- Do NOT diagnose medical conditions or claim that any food cures diseases or chronic illnesses.
- Do NOT recommend dangerous calorie restrictions, starvation diets, or extreme weight loss habits.
- For food allergies: Always caution users to check product labels and beware of cross-contamination; NEVER declare a dish 100% safe merely because an allergen is not listed in a recipe.
- If a user mentions severe allergic reactions, eating disorders, or acute symptoms, immediately direct them to emergency healthcare professionals.
`;

/**
 * Formats app context (Smart Plate analysis, Fridge items, or Recipe details)
 * into a structured block for the model.
 */
function buildContextPrompt(context) {
  if (!context || typeof context !== 'object') return '';
  const lines = [];

  if (context.mealAnalysis) {
    const meal = context.mealAnalysis;
    lines.push('\n[ATTACHED SMART PLATE MEAL ANALYSIS]');
    if (meal.mealName) lines.push(`Meal Name: ${meal.mealName}`);
    if (Array.isArray(meal.foods) && meal.foods.length > 0) {
      lines.push('Foods Detected:');
      meal.foods.forEach((f) => {
        lines.push(` - ${f.name || 'Unknown food'}: ${f.estimatedGrams ? `${f.estimatedGrams}g` : (f.quantity || '1 serving')}`);
      });
    }
    if (meal.total) {
      const t = meal.total;
      lines.push(`Estimated Nutrients: ${t.calories || 0} kcal | ${t.protein || 0}g protein | ${t.carbs || 0}g carbs | ${t.fat || 0}g fat | ${t.fiber || 0}g fiber`);
    }
    if (meal.uncertaintyNotes) lines.push(`Notes: ${meal.uncertaintyNotes}`);
  }

  if (Array.isArray(context.fridgeIngredients) && context.fridgeIngredients.length > 0) {
    lines.push('\n[AVAILABLE FRIDGE / PANTRY INGREDIENTS]');
    const ingList = context.fridgeIngredients.map((i) => (typeof i === 'string' ? i : `${i.name || ''} ${i.quantity ? `(${i.quantity})` : ''}`.trim())).join(', ');
    lines.push(`Ingredients: ${ingList}`);
  }

  if (context.recipe) {
    const r = context.recipe;
    lines.push('\n[CURRENT RECIPE BEING VIEWED]');
    if (r.name) lines.push(`Recipe: ${r.name}`);
    if (r.cuisine) lines.push(`Cuisine: ${r.cuisine}`);
    if (r.totalTime) lines.push(`Time: ${r.totalTime}`);
    if (Array.isArray(r.ingredients) && r.ingredients.length > 0) {
      lines.push(`Ingredients: ${r.ingredients.map((i) => `${i.name} (${i.quantity || ''})`).join(', ')}`);
    }
  }

  if (context.userDietary) {
    lines.push(`\n[USER DIETARY PREFERENCE]: ${String(context.userDietary).slice(0, 300)}`);
  }

  if (context.userDisplayName) {
    lines.push(`\n[USER NAME]: ${String(context.userDisplayName).slice(0, 100)}`);
  }

  if (context.promptContext) {
    lines.push(`\n[ATTACHED APP CONTEXT]\n${String(context.promptContext).slice(0, 2000)}`);
  }

  return lines.join('\n');
}

/**
 * Generate chat response using Google Gemini API
 */
async function generateWithGemini({ message, history = [], context = {}, apiKey, model = 'gemini-3.5-flash' }) {
  const contextText = buildContextPrompt(context);
  const fullSystemInstruction = `${AMUDHU_SYSTEM_PROMPT.trim()}\n${contextText}`.trim();

  // Format past turns for Gemini (alternating user / model)
  const contents = [];
  const boundedHistory = Array.isArray(history) ? history.slice(-10) : [];

  for (const item of boundedHistory) {
    if (!item || !item.content) continue;
    const role = item.role === 'assistant' || item.role === 'model' ? 'model' : 'user';
    contents.push({
      role,
      parts: [{ text: String(item.content).slice(0, 3000) }],
    });
  }

  // Append latest user message
  contents.push({
    role: 'user',
    parts: [{ text: String(message).slice(0, 3000) }],
  });

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  const response = await fetch(url, {
    method: 'POST',
    signal: AbortSignal.timeout(25000),
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{ text: fullSystemInstruction }],
      },
      contents,
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 1500,
      },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    let parsedMsg;
    try {
      const errJson = JSON.parse(errorText);
      parsedMsg = errJson.error?.message || errorText;
    } catch (_) {
      parsedMsg = errorText;
    }
    throw new Error(`Gemini API error (${response.status}): ${parsedMsg}`);
  }

  const data = await response.json();
  const replyText = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!replyText) {
    throw new Error('Gemini returned an empty reply. Please rephrase or try again.');
  }

  return replyText.trim();
}

/**
 * Generate chat response using OpenAI API
 */
async function generateWithOpenAI({ message, history = [], context = {}, apiKey, model = 'gpt-4o' }) {
  const contextText = buildContextPrompt(context);
  const systemContent = `${AMUDHU_SYSTEM_PROMPT.trim()}\n${contextText}`.trim();

  const messages = [{ role: 'system', content: systemContent }];
  const boundedHistory = Array.isArray(history) ? history.slice(-10) : [];

  for (const item of boundedHistory) {
    if (!item || !item.content) continue;
    const role = item.role === 'assistant' || item.role === 'model' ? 'assistant' : 'user';
    messages.push({ role, content: String(item.content).slice(0, 3000) });
  }

  messages.push({ role: 'user', content: String(message).slice(0, 3000) });

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    signal: AbortSignal.timeout(25000),
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.7,
      max_tokens: 1500,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`OpenAI API error (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  const replyText = data.choices?.[0]?.message?.content;
  if (!replyText) throw new Error('OpenAI returned an empty reply.');
  return replyText.trim();
}

/**
 * Deterministic offline fallback when AI API keys are not supplied.
 */
function generateOfflineFallback(message, context = {}) {
  const q = (message || '').toLowerCase();
  const contextNote = context.mealAnalysis ? '\n\n*(Note: Attached Smart Plate meal detected)*' : '';

  if (q.includes('protein')) {
    return 'Protein is an essential macronutrient for building muscles, tissues, and enzymes. Excellent sources include lentils, eggs, paneer, tofu, chicken, fish, chickpeas, and Greek yogurt. For most active adults, aiming for 0.8g to 1.6g of protein per kg of body weight daily supports muscle repair and sustained fullness.' + contextNote;
  }
  if (q.includes('carb') || q.includes('carbohydrate')) {
    return 'Carbohydrates are your body and brain’s primary source of energy. Focus on complex carbohydrates rich in fiber such as whole grains, millets, oats, brown rice, and vegetables, which digest slowly and help maintain steady blood sugar levels.' + contextNote;
  }
  if (q.includes('breakfast')) {
    return 'A balanced breakfast combines complex carbohydrates, lean protein, and fiber. Quick wholesome ideas include:\n1. **Paneer or Egg Bhurji** with 2 whole wheat rotis.\n2. **Steamed Idlis or Dosa** with a vegetable-packed sambar.\n3. **Rolled Oats** cooked with milk/water, topped with chia seeds, nuts, and fresh banana slices.' + contextNote;
  }
  if (q.includes('paneer')) {
    return 'Paneer (Indian cottage cheese) is a fantastic source of vegetarian protein and calcium (~18g protein per 100g). You can prepare Palak Paneer, Paneer Bhurji, or grilled paneer cubes with bell peppers and mild spices for a quick, filling dish.' + contextNote;
  }
  if (context.mealAnalysis) {
    const m = context.mealAnalysis;
    return `Looking at your Smart Plate meal (${m.mealName || 'Scanned Meal'}), it contains an estimated ${m.total?.calories || 0} kcal with ${m.total?.protein || 0}g protein and ${m.total?.carbs || 0}g carbohydrates. To make it more balanced, consider adding a fresh vegetable salad or a side of curd for extra micronutrients and probiotics.`;
  }
  return 'Hi there! I am Amudhu, your food and nutrition assistant. For live AI conversational responses, please ensure a valid GEMINI_API_KEY is configured in your server backend .env file. Feel free to ask about recipes, macronutrients, Smart Plate meals, or healthy eating ideas!';
}

/**
 * Main chat handler orchestrating real AI generation with fallbacks
 */
async function processChatMessage({ message, history = [], context = {} }) {
  if (!message || typeof message !== 'string' || message.trim().length === 0) {
    throw new Error('Message cannot be empty.');
  }

  const geminiKey = (process.env.GEMINI_API_KEY || '').trim();
  const openaiKey = (process.env.OPENAI_API_KEY || '').trim();
  const provider = (process.env.AI_PROVIDER || (geminiKey ? 'gemini' : openaiKey ? 'openai' : 'smart_local')).toLowerCase();
  const geminiModel = (process.env.GEMINI_MODEL || 'gemini-3.5-flash').trim();

  if (geminiKey && provider === 'gemini') {
    try {
      const reply = await generateWithGemini({
        message,
        history,
        context,
        apiKey: geminiKey,
        model: geminiModel,
      });
      return { reply, isAiGenerated: true, provider: 'gemini', model: geminiModel };
    } catch (err) {
      // If preferred model fails with 404, attempt fallback to gemini-3.5-flash-lite
      if (/404|not found/i.test(err.message) && geminiModel !== 'gemini-3.5-flash-lite') {
        try {
          const fallbackReply = await generateWithGemini({
            message,
            history,
            context,
            apiKey: geminiKey,
            model: 'gemini-3.5-flash-lite',
          });
          return { reply: fallbackReply, isAiGenerated: true, provider: 'gemini', model: 'gemini-3.5-flash-lite' };
        } catch (_) {}
      }
      throw err;
    }
  }

  if (openaiKey && provider === 'openai') {
    const reply = await generateWithOpenAI({
      message,
      history,
      context,
      apiKey: openaiKey,
    });
    return { reply, isAiGenerated: true, provider: 'openai', model: 'gpt-4o' };
  }

  // Graceful fallback for offline / development without API keys
  const reply = generateOfflineFallback(message, context);
  return { reply, isAiGenerated: false, provider: 'offline_guide' };
}

module.exports = {
  processChatMessage,
  buildContextPrompt,
  AMUDHU_SYSTEM_PROMPT,
};
