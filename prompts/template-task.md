# Claude Code Task Template

Use this structure for every prompt sent via `submit_prompt()`. Claude Code has no memory of your ChatGPT conversation — every prompt must be completely self-contained.

---

Goal:
[The desired end state in one sentence. What should be true when this is done?]

Context:
[Current state. Relevant file paths. Why this matters. What exists already.]

Constraints:
[What NOT to touch. What to preserve. Behavior that must not change.]

Verification:
[How to confirm it worked. What to check, run, or read.]

Response:
When done, write your summary to .mcp-response.md with sections: What was done, Result, Files changed, Next.

---

## Tips for good prompts

**Be specific about files.** "The auth route" is vague. "routes/auth.js POST /login" is not.

**State the current behavior.** Claude Code can't see what you see. Describe what exists now, not just what you want.

**One task per prompt.** Don't ask for rate limiting AND tests AND refactoring in one shot. Send them separately.

**Include the verification step.** This tells Claude Code how to know it's done. It also helps you verify the response.

**Don't include secrets.** Never put API keys, passwords, or tokens in a prompt. Reference env vars by name.
