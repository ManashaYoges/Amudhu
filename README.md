# Amudhu

Flutter food and nutrition companion with an Express API and MongoDB Atlas persistence for account profiles and saved meal history. The Flutter app never connects to MongoDB directly.

## Backend setup

1. Install Node.js 20 or later.
2. In `backend/`, run `npm install`.
3. Copy `backend/.env.example` to `backend/.env` and set `MONGODB_URI` for the Atlas database `amudhu`, plus a random `JWT_SECRET` of at least 32 characters.
4. Start with `npm run dev` or `npm start`.

The Atlas database user should have read/write access only to the `amudhu` database. Keep `.env` private. Optional meal image analysis requires a server-side `GEMINI_API_KEY` or `OPENAI_API_KEY`. Password reset requires working SMTP settings; without them the API returns a configuration error and does not claim an email was sent.

## Flutter setup

From this directory, run `flutter pub get`, then `flutter run`. Development API URLs can be supplied with Dart defines:

- Android emulator: `--dart-define=API_BASE_URL_DEV=http://10.0.2.2:3000`
- Physical Android phone: `--dart-define=API_BASE_URL_DEV=http://<computer-LAN-IP>:3000` (phone and computer must be on the same network; do not use `localhost` on the phone)
- Windows desktop or local web: `--dart-define=API_BASE_URL_DEV=http://localhost:3000`
- Production: build with `--dart-define=APP_ENV=production --dart-define=API_BASE_URL_PROD=https://<your-api-host>`

The Settings screen can also override the API address during the current app session. Production must use HTTPS.

## MongoDB collections

- `users`: unique normalized email, bcrypt password hash (excluded from queries and responses), display name, role and timestamps. Password-reset hashes and expiry metadata are transient fields on the user document.
- `meals`: owner reference, meal analysis result, nutrition totals and timestamp; compound index on owner and timestamp.
- `revoked_tokens`: JWT IDs revoked at logout, removed by a MongoDB TTL index after expiry.

## Tests and verification

- Backend API/auth tests: `cd backend && npm test` (uses mocked persistence; Atlas credentials are not required).
- Existing nutrition verification suite: `cd backend && npm run test:analyze`.
- Flutter tests: `flutter test`.
- Flutter static analysis: `flutter analyze`.
- Android build: `flutter build apk --debug`.

These commands require the indicated runtimes. API tests verify routes, authentication, password hashing, validation and user ownership with mocked persistence; a live Atlas check requires your private `MONGODB_URI`.

## Firebase removal and external services

Firebase Authentication, Firestore, Firebase initialization, Google Services Gradle configuration, and Firebase configuration files have been removed. No Storage or Messaging calls were found in the inspected source. Images are sent to the analysis API for processing and are not persisted by this app. Gemini/OpenAI analysis and SMTP password-reset email are optional separately configured services. Fridge and recipe screens retain their existing local/demo data behavior.

## API documentation

See [`backend/API.md`](backend/API.md) for request paths, authentication requirements and current service limitations. Backend environment variables are documented in [`backend/.env.example`](backend/.env.example).
