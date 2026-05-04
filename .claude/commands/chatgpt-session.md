# ChatGPT PM Session

You are Claude Code acting as the AI executor in a ChatGPT PM session. ChatGPT sends tasks via MCP — your job is to watch for them and execute automatically without waiting to be prompted.

**Both the MCP server and the watcher must be running. This skill starts both.**

---

## Step 1 — Verify the MCP server

```bash
bash $(cat ~/.chatgpt-pm-mcp/repo-path)/start.sh status
```

If STOPPED, start it:
```bash
bash $(cat ~/.chatgpt-pm-mcp/repo-path)/start.sh
```

Do not continue until the server is confirmed running.

---

## Step 2 — Start the watcher in background

```bash
MCP_REPO=$(cat ~/.chatgpt-pm-mcp/repo-path)
EVENTS_LOG="${PROJECT_ROOT:-.}/.mcp-events.log"
touch "$EVENTS_LOG"
bash "$MCP_REPO/watcher.sh" &
echo "Watcher started (pid $!). Monitoring $EVENTS_LOG for incoming prompts..."
```

---

## Step 3 — Monitor the events log and auto-execute

Use the Monitor tool to tail the events log:
```
tail -f ${PROJECT_ROOT:-.}/.mcp-events.log
```

**Each new line that appears is the full path to a prompt file from ChatGPT.**

When Monitor fires with a new line:
1. Read the prompt file at that path immediately — do not wait for the user
2. Execute the task fully
3. Write your response to `.mcp-response.md` in the project root:

```
---
ready: true
timestamp: [ISO datetime]
---

## What was done
[Summary]

## Result
[What changed, files modified, output]

## Files changed
[List]

## Next
[What makes sense next]
```

4. **Delete the prompt file** so `safe_to_send` returns to true:
```bash
rm "[path to prompt file]"
```

5. Return to monitoring — the next line from Monitor is the next task.

**Do not ask for confirmation. Do not wait for the user to speak. When a line arrives, execute immediately.**

---

## Stay in session mode

Keep the Monitor running until the user explicitly ends the session. Every new line = new task from ChatGPT. Execute each one automatically and write the response so ChatGPT can read it back.

Tell the user: "Watcher active — waiting for prompts from ChatGPT. Send a task from your ChatGPT Project and I'll execute it automatically."
