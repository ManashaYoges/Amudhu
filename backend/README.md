# Amudhu API server

Node.js and Express API for the Flutter app. MongoDB Atlas is configured only on the server; the backend always selects database `amudhu` when connecting.

## Run locally

```powershell
cd backend
npm install
Copy-Item .env.example .env
# Edit .env with MONGODB_URI and a random JWT_SECRET (32+ characters)
npm run dev
```

The process does not listen until MongoDB connects. It prints development URLs for desktop, Android emulator (`10.0.2.2`) and a physical Android phone (the computer’s LAN IPv4 address). For the phone, use that LAN address in the app and keep the devices on the same network.

## Security configuration

Required: `MONGODB_URI`, `JWT_SECRET`, and optionally `PORT`. Use an Atlas database user with read/write access scoped to `amudhu`; allow-list only required client/server IPs in Atlas. Never put the URI, JWT secret, SMTP credentials or AI keys in Flutter or source control.

Password reset remains disabled until a working SMTP provider and `MAIL_FROM` are configured. The API returns an explicit configuration error when reset mail is not enabled. Auth endpoints are rate limited; passwords are bcrypt-hashed and reset tokens are SHA-256 hashed with one-time use and a 30-minute expiry.

## Tests and API reference

- `npm test`: API/auth/ownership tests with mocked persistence.
- `npm run test:analyze`: existing meal nutrition analysis tests.
- `API.md`: endpoint contract, authentication and current demo endpoint behavior.

Run an actual database connectivity check with `GET /api/health` after configuring Atlas; it reports `database: connected` only when the live connection is established.
