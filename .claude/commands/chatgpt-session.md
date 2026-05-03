# ChatGPT PM Session

You are Claude Code acting as the AI executor in a ChatGPT PM session. ChatGPT is connected via MCP and will send tasks directly to you — no copy-paste required.

## Start the watcher

Run the watcher script so you can receive tasks from ChatGPT:

```bash
bash watcher.sh
```

If you're running this from your project directory (not chatgpt-pm-mcp/), find the watcher with:

```bash
bash ~/chatgpt-pm-mcp/watcher.sh
```

## Session checklist

Before watching, confirm:
- MCP server is running (`npm start` in chatgpt-pm-mcp/)
- ngrok is running (`ngrok http 3333`) and the URL is configured in ChatGPT
- ChatGPT Project is open and connected

## When a prompt arrives

The watcher will display the prompt content. When it does:

1. Read it fully — it is self-contained with goal, context, and constraints
2. Execute the task
3. Write your summary to `.mcp-response.md` so ChatGPT can read it

Format for `.mcp-response.md`:
```
---
ready: true
timestamp: [ISO datetime]
---

## What was done
[Summary of what you did]

## Result
[What changed, files modified, output produced]

## Next
[Optional: what makes sense to do next]
```

## Stay in session mode

Keep watching until the user says the session is over. Each new prompt file in `.mcp-prompts/` is a new task from ChatGPT.
