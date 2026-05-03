# Example Prompt: Add a Feature

Goal:
Add rate limiting to POST /auth/login to prevent brute force attacks.

Context:
Express API at /home/user/my-project. Login route is in routes/auth.js at POST /login.
No rate limiting exists. express-rate-limit is not installed.

Constraints:
- Only modify routes/auth.js and add a new middleware file
- Do not change successful login response format
- Use express-rate-limit: 10 requests per 15 minutes per IP
- Return HTTP 429 with JSON error on limit exceeded

Verification:
- routes/auth.js imports and applies the limiter to POST /login
- New middleware/rateLimiter.js file exists with the config
- package.json includes express-rate-limit
- 11th request within 15 min returns 429

Response:
When done, write your summary to .mcp-response.md with sections: What was done, Result, Files changed, Next.
