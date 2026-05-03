# chatgpt-pm-mcp

Connect ChatGPT to Claude Code via MCP. ChatGPT acts as your AI project manager — reading your project files, planning tasks, and submitting them directly to Claude Code. No copy-paste. No manual context passing.

**Free guide:** [gmgnrepeat.com/chatgpt-pm-mcp](https://gmgnrepeat.com/chatgpt-pm-mcp)

## What This Does

- ChatGPT reads your project files in real time via MCP tools
- ChatGPT submits tasks directly to Claude Code via `submit_prompt()`
- Claude Code executes and writes results to `.mcp-response.md`
- ChatGPT reads the result via `get_response()`
- You are out of the middle

## Setup

Clone this repo, then open it in Claude Code:

```bash
git clone https://github.com/gmgnrepeat/chatgpt-pm-mcp
cd chatgpt-pm-mcp
claude
```

Claude Code will read `CLAUDE.md` and walk you through the full setup interactively — project path, ngrok, ChatGPT configuration, and your first session.

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
6. /send                                  # ChatGPT calls submit_prompt() — no copy-paste
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
| `submit_prompt` | Send a task directly to Claude Code |
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

The workflow is powerful but not perfectly deterministic — tool calls pass through ChatGPT's platform, your MCP server, ngrok, and the Claude Code watcher. Any layer can hiccup.

| Symptom | What to do |
|---------|-----------|
| `/check` fails or returns no tools | MCP connection is down — restart `bash start.sh` and reconnect the MCP app in ChatGPT project settings |
| Approval popup appears | Normal — approve it and continue |
| Tool call blocked by platform | Simplify/shorten the prompt, remove special characters from file paths, retry |
| `get_response` times out | Do NOT resubmit — the prompt may have landed. Check `.mcp-prompts/` for a new file, then poll `get_response` again |
| Duplicate execution | Check status before sending — if Claude is still running, wait |
| Connector goes stale after restart | In ChatGPT project settings: delete and re-add the MCP app |
| Nothing works | **Manual fallback:** copy the prompt ChatGPT structured and paste it directly into Claude Code. Summarize the result back to ChatGPT. This always works. |

> Long waits (up to 600s) depend on your MCP client and platform supporting them. The workflow is not guaranteed to send every time — it's a powerful pattern with real-world rough edges.

## License

MIT
