---
ready: true
timestamp: 2026-05-03T10:15:00.000Z
---

## What was done
Added rate limiting to POST /auth/login using express-rate-limit.

## Result
- Installed `express-rate-limit` (added to package.json)
- Created `middleware/rateLimiter.js` with 10 req/15min per IP config
- Applied limiter to `routes/auth.js` on the login route
- Tested manually: 11th request within 15 min returns 429 Too Many Requests

## Files changed
- `package.json` — added express-rate-limit ^7.0.0
- `middleware/rateLimiter.js` — new file
- `routes/auth.js` — imported and applied limiter to POST /login

## Next
Run `npm install` to install the new dependency. Consider adding a test with supertest to verify the 429 response.
