# Example Prompt: Fix a Bug

Goal:
Fix GET /users/:id so it returns a 404 JSON error when the user is not found instead of crashing.

Context:
Express API at /home/user/my-project. Route is in routes/users.js at GET /:id.
Current behavior: if the user ID doesn't exist in the database, the handler throws an unhandled error and the server returns a 500 with an HTML stack trace.

Constraints:
- Only modify routes/users.js
- Do not change the response format for successful lookups
- Return HTTP 404 with body: { "error": "User not found" }
- Do not add any new dependencies

Verification:
- GET /users/nonexistent-id returns HTTP 404 with JSON body
- GET /users/valid-id still returns the user correctly
- No unhandled promise rejections in server logs

Response:
When done, write your summary to .mcp-response.md with sections: What was done, Result, Files changed, Next.
