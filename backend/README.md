# Amudhu Smart Plate — Backend Server

A secure, high-performance Node.js backend providing AI Vision food recognition and standardized nutritional analysis for the Amudhu Flutter application.

## Key Features

- **Real Vision AI Integration**: Connects to Google Gemini Vision (`gemini-1.5-flash` or `gemini-2.0-flash`) and OpenAI GPT-4o Vision to inspect actual meal photographs.
- **Strict Anti-Hallucination Prompting**: Instructs the vision model to detect only visibly present foods, separate components (rice, dal, sambar, poriyal), and identify common South Indian, Indian, and international meals without guessing invisible ingredients.
- **Standardized Food Composition Database**: Computes nutrition using verified cooked values per 100g:
  $$\text{Nutrient} = \frac{\text{Nutrient per } 100\text{g} \times \text{estimated grams}}{100}$$
- **Portion Estimation**: Realistic gram estimates based on visible plate area and standard serving references.
- **Zero Mock Fallbacks**: Returns clear errors if the image cannot be analyzed or if API keys are missing, instead of faking results.

---

## Quick Start

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Your API Key
Open `.env` (or copy from `.env.example`) and add your Google Gemini API key:
```env
PORT=3000
GEMINI_API_KEY=AIzaSy...your_gemini_key_here
GEMINI_MODEL=gemini-1.5-flash
AI_PROVIDER=gemini
```
> *Get a free Gemini API key from [Google AI Studio](https://aistudio.google.com).*

### 3. Start the Server
```bash
npm start
```
The server will start at:
- Local desktop/browser: `http://localhost:3000`
- Android Emulator: `http://10.0.2.2:3000`
- Physical phone: `http://<your-computer-ip>:3000`

---

## API Endpoints

### 1. `GET /api/health`
Checks server status and whether the AI API key is configured.
```json
{
  "status": "online",
  "service": "Amudhu Smart Plate AI Vision Server",
  "provider": "gemini",
  "apiKeyConfigured": true,
  "foodCatalogCount": 38
}
```

### 2. `POST /api/analyze-plate`
Accepts `multipart/form-data` with `image` file or JSON body with `{"image": "<base64>"}`.

**Response format:**
```json
{
  "success": true,
  "isFood": true,
  "mealName": "Steamed Rice with Dal and Poriyal",
  "foods": [
    {
      "name": "Cooked white rice",
      "quantity": "180 g",
      "calories": 234,
      "protein": 4.9,
      "carbs": 50.8,
      "fat": 0.5,
      "fiber": 0.7,
      "sugar": 0.2,
      "emoji": "🍚",
      "confidence": 0.92,
      "estimatedGrams": 180,
      "portionIsEstimated": true,
      "alternatives": ["Brown rice"],
      "notes": null
    }
  ],
  "total": {
    "calories": 420,
    "protein": 14.2,
    "carbs": 68.5,
    "fat": 6.8,
    "fiber": 7.4,
    "sugar": 3.2
  },
  "balance": {
    "score": 82,
    "status": "Well Balanced!",
    "tip": "Adding raw salad or steamed greens will boost fiber further.",
    "amudhuNote": "Approximate nutritional balance indicator based on detected foods and portions. Not a medical assessment."
  },
  "analysisSource": "real_ai",
  "isEstimate": true
}
```

### 3. `POST /api/recalculate`
Recalculates meal totals when the user adjusts portions or adds/removes foods.
