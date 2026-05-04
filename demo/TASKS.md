# Task Backlog — Demo Project

These are sample tasks for testing the ChatGPT PM MCP workflow.
Use `/plan [task description]` in your ChatGPT Project to have ChatGPT read the code and structure a prompt for Claude Code.

---

## Task 1 — Add rate limiting to POST /auth/login
Add rate limiting to prevent brute force attacks on the login endpoint.
File: routes/auth.js — POST /login
Use express-rate-limit: max 10 requests per 15 minutes per IP, return 429 on exceeded.

## Task 2 — Fix null crash on GET /users/:id
The users route returns null when a user ID doesn't exist, causing a 500 error.
File: routes/users.js — GET /:id
Should return HTTP 404 with { "error": "User not found" } when not found.

## Task 3 — Add a test for the rate limiter
Write a basic integration test for the auth rate limiting using supertest.
Verify the 11th request within 15 minutes returns HTTP 429.
