Goal:
Add rate limiting to the POST /auth/login endpoint to prevent brute force attacks.

Context:
Express API at /home/user/my-project. The login route is in routes/auth.js at POST /login.
There is no rate limiting currently — any number of login attempts are allowed.
express-rate-limit is not yet installed.

Constraints:
- Do not modify any other routes
- Do not change the response format for successful logins
- Use express-rate-limit (npm package)
- Limit: 10 requests per 15 minutes per IP
- Return 429 with a plain JSON error message on limit exceeded

Verification:
- routes/auth.js applies the limiter to POST /login
- A new middleware file exists with the rate limit config
- package.json includes express-rate-limit
- Manual test: 11th request within 15 min returns HTTP 429

Response:
When done, write your summary to .mcp-response.md with sections: What was done, Result, Files changed, Next.
