# chatgpt-pm-mcp

Connect ChatGPT to Claude Code via MCP. ChatGPT acts as your AI project manager — reading project context, planning scoped tasks, checking the bridge, and sending work to Claude Code when the handoff is healthy. Less copy-paste. Less manual context passing. Clear fallbacks when tools need help.

**Free guide:** [gmgnrepeat.com/chatgpt-pm-mcp](https://gmgnrepeat.com/chatgpt-pm-mcp)

## What This Does

- ChatGPT reads your project files in real time via MCP tools
- ChatGPT sends scoped tasks to Claude Code via MCP using `submit_prompt()`
- Claude Code executes and writes results to `.mcp-response.md`
- ChatGPT reads the result via `get_response()`
- You are out of the middle

## Setup

**Step 1 — Clone and install:**

```bash
git clone https://github.com/SRHSoulja/chatgpt-pm-mcp
cd chatgpt-pm-mcp
bash install.sh
```

`install.sh` copies the `/chatgpt-pm-setup` and `/chatgpt-session` slash commands into Claude Code globally.

**Step 2 — Go to your project and run the setup wizard:**

```bash
cd /path/to/your/project   # your existing project
# OR: cd ~/chatgpt-pm-mcp/demo   # included demo if you have no project yet
claude
/chatgpt-pm-setup
```

The `/chatgpt-pm-setup` wizard walks you through everything — dependencies, .env, CLAUDE.md safety check, ChatGPT Project setup, ngrok, and your first session.

**Which folder to use:**
- **Have an existing project?** `cd` into it, then run `claude` and `/chatgpt-pm-setup`
- **No project / just testing?** Use `demo/` — a generic Express API with sample tasks and prompts included in this repo

## Requirements

- ChatGPT Plus or Pro (developer mode requires a paid plan)
- Claude Code (`npm install -g @anthropic-ai/claude-code`)
- Node.js 18+
- ngrok (free tier works)

## ChatGPT Project Setup

Once your MCP server is running and exposed via ngrok:

1. **Enable Developer Mode** — ChatGPT Settings → Apps → Advanced Mode → Advanced Settings → Developer Mode ON
2. **Create a new Project** — click + New Project. **Set memory to "Project only" during creation** — this option disappears after.
3. **Add your MCP app** — Project Settings → Apps → Create App → paste your ngrok URL + `/sse` → Authentication: None → Save
4. **Paste the project instructions** — copy everything after the divider in `chatgpt-instructions.md` into your ChatGPT Project instructions
5. **Verify the connection** — in your ChatGPT Project, type: `Check the MCP tools available for this project and tell me what you can do.` ChatGPT will call `get_commands()` and report back. You may not see the tools listed in the UI — that's normal, ChatGPT verifies internally.
6. **Start your session** — type `/resume` and ChatGPT will read your project context

## Your First Session

```
1. bash ~/chatgpt-pm-mcp/start.sh        # server + ngrok
2. cd /your/project && claude             # open Claude Code
   /chatgpt-session                       # start watcher + executor mode
3. In ChatGPT: /resume                    # ChatGPT reads your project
4. Tell ChatGPT what you want to work on
5. /plan [task]                           # ChatGPT reads files, structures task, asks to confirm
6. /send                                  # ChatGPT calls submit_prompt() via MCP
7. Claude Code picks it up, executes, writes .mcp-response.md
8. ChatGPT reads the result automatically (polls up to 10 min)
9. Repeat
```

## Tools Exposed to ChatGPT

| Tool | What it does |
|------|-------------|
| `get_commands` | List all tools and verify the MCP connection is working |
| `read_file` | Read any project file |
| `list_directory` | List files in a directory |
| `get_project_context` | Load .chatgpt-resume.md / CLAUDE.md / README |
| `get_git_log` | Recent git commits |
| `submit_prompt` | Send a scoped task to Claude Code via the MCP bridge |
| `get_response` | Poll for Claude Code's response (waits up to 10 min) |
| `write_task` | Add a task to TASKS.md backlog (does not execute) |

## Slash Commands (in ChatGPT)

Once you paste `chatgpt-instructions.md` into your ChatGPT Project:

| Command | What happens |
|---------|-------------|
| `/check` | ChatGPT calls get_commands() and reports available tools |
| `/resume` | ChatGPT reads .chatgpt-resume.md and orients itself |
| `/plan [task]` | ChatGPT reads context, structures the task, asks to confirm |
| `/send` | ChatGPT calls submit_prompt() with the last plan |
| `/response` | ChatGPT reads .mcp-response.md immediately |
| `/context` | ChatGPT reloads project files |
| `/task [text]` | Saves to TASKS.md backlog |

## Troubleshooting

The workflow passes through four stages. A prompt can fail at any one — use `check_handoff_status()` to see exactly where things stand before resubmitting.

**The four handoff stages:**
1. **Platform dispatch** — ChatGPT sent the tool call (approval popup = normal; block = fail here)
2. **Prompt file written** — MCP server wrote to `.mcp-prompts/` (verifiable via `check_handoff_status`)
3. **Claude picked it up** — file watcher in Claude Code noticed the file (can fail if watcher stopped)
4. **Response produced** — Claude executed and wrote `.mcp-response.md`

`safe_to_send: true` only means no prompt file is pending — it does **not** mean Claude received anything.

Ask ChatGPT: `Check handoff status. Did my last prompt reach Claude Code?`

| Symptom | What to do |
|---------|-----------|
| `/check` fails | MCP connection down — restart `bash start.sh`, reconnect MCP app in ChatGPT project settings |
| Approval popup appears | Normal — approve and continue |
| Tool call blocked by platform | Simplify the prompt, remove special characters, retry |
| Prompt approved but nothing in Claude | Call `check_handoff_status` — if prompt file exists but no response, the watcher may have stopped. In Claude Code: `/chatgpt-session` |
| `get_response` times out | Do NOT resubmit — call `check_handoff_status` first. If prompt file exists, Claude may still be working; keep polling |
| Status says running / safe_to_send false | Wait — Claude is executing. Poll `get_response`, do not send again |
| Duplicate execution risk | Always call `check_handoff_status` before sending — if pending_prompt_count > 0, wait |
| Connector stale after restart | Delete and re-add the MCP app in ChatGPT project settings |
| Nothing works | **Manual fallback:** copy ChatGPT's structured prompt into Claude Code directly. Summarize result back. Always works. |

> Long waits (up to 600s) depend on platform support. This is a powerful pattern with real-world rough edges — the checklist above covers the common ones.

## License

MIT
