# Amudhu REST API

Base path: `http://<host>:3000/api`. Responses use JSON. Protected requests send `Authorization: Bearer <token>`. Error responses have `{ "error": "...", "code": "..." }` and never include stack traces, hashes, or database credentials.

## Authentication and profile

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/auth/register` | No | Create account. Body: `email`, `password` (8–128 chars), optional `displayName`. Returns bearer token and public user. |
| POST | `/auth/login` | No | Sign in with `email` and `password`; invalid credentials use one generic response. |
| POST | `/auth/logout` | Yes | Revoke the current JWT until its expiry. |
| GET | `/auth/me` | Yes | Get the current public profile. |
| PATCH | `/auth/me` | Yes | Update `displayName`. User ID is taken from the token. |
| POST | `/auth/change-password` | Yes | Body: `currentPassword`, `newPassword`. |
| POST | `/auth/password-reset/request` | No | Body: `email`. Requires SMTP configuration; response does not reveal whether the account exists. |
| POST | `/auth/password-reset/confirm` | No | Body: `email`, `token`, `newPassword`. Token is single use, hashed at rest, and expires after 30 minutes. |

Auth and reset requests are rate limited. The reset request additionally has a one-minute per-account cooldown.

## Meal history

All paths below require authentication. Records are always filtered by the token owner.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/meals` | List up to 200 of the signed-in user’s meals, newest first. |
| POST | `/meals` | Save a meal. Body includes `mealName`, `foods`, `total` and optional balance, vitamins/minerals, estimate metadata and timestamp. |
| PATCH | `/meals/:id` | Update a saved meal. |
| DELETE | `/meals/:id` | Delete a saved meal. |

## AI Food & Nutrition Chat

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/api/chat` | Optional | Send question with conversation history and context (`mealAnalysis`, `fridgeIngredients`, `recipe`). Returns dynamic AI answer. |
| GET | `/api/chat/history/:conversationId?` | Optional | Retrieve stored messages for this conversation session. |
| DELETE | `/api/chat/history/:conversationId` | Optional | Clear conversation history from MongoDB. |

## Existing application services

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` or `/api/health` | API and MongoDB connection status. |
| POST | `/api/analyze-plate` | Existing multipart image or base64 meal-analysis request. AI credentials stay server-side. |
| POST | `/api/recalculate` | Recalculate nutrition from a `foods` array. |
| POST | `/api/analyze-fridge` | Scan fridge/pantry photo with AI Vision (or smart local presets) to detect available ingredients. |
| POST | `/api/generate-recipes` | Generate tailored recipes based on provided ingredients with steps, nutrition, match counts, and video tutorial links. |
| GET | `/api/recipes/search?q=...` | Existing recipe-search endpoint; currently returns no remote results. |

The fridge analysis and recipe generation services use Google Gemini AI when GEMINI_API_KEY is configured, or high-accuracy smart local catalog engines when operating offline.
