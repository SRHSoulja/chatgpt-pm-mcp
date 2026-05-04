# chatgpt-pm-mcp

Connect ChatGPT to Claude Code via MCP. ChatGPT acts as your AI project manager — reading project context, planning scoped tasks, checking the bridge, and sending work to Claude Code when the handoff is healthy. Less copy-paste. Less manual context passing. Clear fallbacks when tools need help.

**Free guide:** [gmgnrepeat.com/chatgpt-pm-mcp](https://gmgnrepeat.com/chatgpt-pm-mcp)

## What This Does

- ChatGPT reads your project files in real time via MCP tools
- ChatGPT sends scoped tasks to Claude Code via MCP using `submit_prompt()`
- Claude Code executes and writes results to `.mcp-response.md`
- ChatGPT reads the result via `get_response()`
- You are out of the middle

## Supported Environments

**Linux, macOS, Windows via WSL2.**

Native Windows PowerShell/CMD is not supported. If you are on Windows, install WSL2 (Ubuntu or Debian recommended), then run everything inside your WSL terminal.

## Setup

**Step 1 — Install prerequisites (skip anything you already have):**

```bash
# git and curl — skip if already installed
sudo apt update && sudo apt install -y git curl

# Claude Code — skip if already installed
curl -fsSL https://claude.ai/install.sh | bash
```

**Step 2 — Clone the repo and run the installer:**

```bash
git clone https://github.com/SRHSoulja/chatgpt-pm-mcp
cd chatgpt-pm-mcp
bash install.sh
```

`install.sh` does three things:
- Saves the repo path to `~/.chatgpt-pm-mcp/repo-path` so the setup wizard can find it later — no matter where you cloned it
- Copies `/chatgpt-pm-setup`, `/chatgpt-session`, and `/chatgpt-switch-project` into Claude Code globally (`~/.claude/commands/`)

**You only run `install.sh` once per machine.** The slash commands are then available in every Claude Code session globally. For each new project, just `cd` into it and run `/chatgpt-pm-setup` — takes about 2 minutes and connects that project to the bridge.

**Step 3 — Go to your project and run the setup wizard:**

```bash
cd /path/to/your/project      # your existing project
# OR use the included demo:
cd /path/where/you/cloned/chatgpt-pm-mcp/demo
claude
/chatgpt-pm-setup
```

The `/chatgpt-pm-setup` wizard walks you through everything — dependency check, .env setup, CLAUDE.md safety check (no silent overwrite), ChatGPT Project setup, ngrok, and your first session. It uses the saved repo path so it doesn't matter where you cloned the repo.

**Which folder to use:**
- **Have an existing project?** `cd` into it, then run `claude` and `/chatgpt-pm-setup`
- **No project / just testing?** Use the `demo/` folder inside this repo — a generic Express API with sample tasks and prompts

## Adding a Second Project

Already set up on one project and want to connect another? Use the `/chatgpt-switch-project` command — it skips all the first-time setup (deps, ngrok, ChatGPT connector) and only does the project-specific parts.

```bash
cd /path/to/your/other/project
claude
/chatgpt-switch-project
```

It will update `PROJECT_ROOT` in `.env`, create a `.chatgpt-resume.md` if needed, and tell you to restart the server. `PROJECT_ROOT` is what controls everything — all 9 tools read and write relative to that path, so changing it is all it takes to point the whole system at a new project.

After restarting the server, type `/context` or `/resume` in ChatGPT to reload the new project's files into context. Same ngrok URL, same MCP connector, same ChatGPT Project — ChatGPT just reads different files now.

To keep projects fully separate, create a dedicated ChatGPT Project for each one and paste the same `chatgpt-instructions.md` into each.

## Requirements

- ChatGPT Plus or Pro (developer mode requires a paid plan)
- Claude Code (`curl -fsSL https://claude.ai/install.sh | bash`)
- Node.js 18+
- ngrok (free tier works — install from ngrok.com/download, authenticate with `ngrok config add-authtoken YOUR_TOKEN`, token at dashboard.ngrok.com/authtokens)

## ChatGPT Project Setup

Once your MCP server is running and exposed via ngrok, `start.sh` prints the real tunnel URL in a box:

```
┌─────────────────────────────────────────────────────┐
│  ngrok tunnel URL:                                  │
│  https://abc123.ngrok-free.app                      │
│                                                     │
│  Use this in ChatGPT → Create App:                 │
│  MCP Server URL: https://abc123.ngrok-free.app/sse  │
└─────────────────────────────────────────────────────┘
```

**Use the URL printed by start.sh.** The `abc123` above is a placeholder — your real URL will be different. Copy the full `https://...` line and paste it into ChatGPT when creating the MCP app.

> **Note:** ngrok free tier generates a new URL every time you run `start.sh`. You cannot edit an existing MCP connector in ChatGPT — you have to delete it and create a new one with the new URL. It takes about 30 seconds.
>
> **To get a stable URL (so your connector never needs updating):**
>
> **Option A — ngrok free static domain** *(recommended for most users)*
> ngrok gives every free account one static domain. Go to [dashboard.ngrok.com/domains](https://dashboard.ngrok.com/domains), claim yours, then add it to `.env`:
> ```
> NGROK_DOMAIN=your-name.ngrok-free.app
> ```
> `start.sh` picks it up automatically — same URL every restart.
>
> **Option B — ngrok paid** ($10/mo) — reserved domains, higher connection limits.
>
> **Option C — Self-hosted reverse proxy** — if you already have a domain and hosting (e.g. via Porkbun, Cloudflare Tunnel, or a VPS), you can expose the MCP server through your own domain instead of ngrok entirely. Point your reverse proxy at `localhost:3333` and use that URL in ChatGPT. This is what we use for our own setup — no ngrok dependency at all.

1. **Create a ChatGPT Project** — click **+ New Project** in the ChatGPT sidebar. Give it a name. In the project settings (gear icon), set **Memory** to **"Project only"** to keep this isolated from your other chats.

2. **Enable Developer Mode** — inside the project, go to **Settings → Apps**. Toggle **Developer mode** ON. You'll see an "ELEVATED RISK" warning — this is expected. Leave **"Enforce CSP in developer mode"** OFF (this allows unrestricted network access, which is needed for your ngrok tunnel).

3. **Create the MCP app** — with Developer mode on, a **Create app** button appears. Click it. Fill out the form:
   - **Name:** Project PM (or anything you like)
   - **MCP Server URL:** paste your ngrok URL + `/sse` (e.g. `https://abc123.ngrok-free.app/sse`)
   - **Authentication:** change the dropdown from OAuth → **None**
   - Check **"I understand and want to continue"**
   - Click **Create**

4. **Paste the project instructions** — copy the full contents of `chatgpt-instructions.md` into your ChatGPT Project instructions (Project → Settings → Instructions).

5. **Verify the connection** — in your ChatGPT Project, type: `Check the MCP tools available for this project and tell me what you can do.` ChatGPT will call `get_commands()` and report back. You may not see the tools listed in the UI — that's normal, ChatGPT verifies through MCP internally.

6. **Start your session** — type `/resume` and ChatGPT will read your project context.

## Your First Session

```
1. bash $(cat ~/.chatgpt-pm-mcp/repo-path)/start.sh   # server + ngrok (uses saved repo path)
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

**Using the demo project?** The `demo/` folder is a small Express API with pre-written tasks. Use it to test the full loop before connecting your real project:

```bash
cd /path/where/you/cloned/chatgpt-pm-mcp/demo
claude
/chatgpt-pm-setup
```

ChatGPT will read `demo/TASKS.md` and the code in `demo/routes/`. Try `/plan Task 1` — add rate limiting to the login route — and watch Claude Code implement it.

**Writing prompts?** See `prompts/template-task.md` for the self-contained prompt format, and `prompts/example-add-feature.md` / `prompts/example-fix-bug.md` for complete examples.

## Tools Exposed to ChatGPT

| Tool | What it does |
|------|-------------|
| `get_commands` | List all tools and verify the MCP connection is working |
| `check_handoff_status` | Diagnose the pipeline — check bridge state, pending prompts, and response before resubmitting |
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

## Security Model

This setup exposes your local machine to a public HTTPS URL via ngrok. Understand what that means before you start:

- **ChatGPT can read any file inside `PROJECT_ROOT`** — keep secrets, credentials, and `.env` files outside the project folder, or at minimum do not point `PROJECT_ROOT` at a directory containing them
- **`submit_prompt()` is an execution handoff** — it tells Claude Code to run code, write files, and make changes. Treat it with the same care you would giving someone shell access
- **Don't share your ngrok URL** — anyone with the URL can call your MCP tools
- **Stop the server when done** — run `bash start.sh stop` when you finish a session; don't leave it running overnight
- **Auth is None by design** — this is a local personal tool. If you're sharing the server with a team, add bearer token auth to `server.js`

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
| "Error creating connector" in ChatGPT | MCP server wasn't reachable when ChatGPT probed it. Confirm `start.sh status` shows both running, then test: `curl -v https://YOUR-URL/sse` (should return `text/event-stream`). If 502 — ngrok tunnel down; restart `start.sh`. Then retry creating the app. |
| `start.sh` says ngrok missing | Install ngrok: see Requirements section. Authenticate with `ngrok config add-authtoken YOUR_TOKEN` (token at dashboard.ngrok.com/authtokens) |
| `start.sh` shows no tunnel URL | ngrok failed to connect — check `.ngrok.log` for errors; common: missing authtoken (run `ngrok config add-authtoken`) |
| ERR_NGROK_3200 in ChatGPT | Endpoint offline — ngrok is not running or the URL changed. Run `bash start.sh` and use the new URL printed |
| `/check` fails | MCP connection down — restart `bash start.sh`, reconnect MCP app in ChatGPT project settings |
| Approval popup appears | Normal — approve and continue |
| Tool call blocked by platform | Simplify the prompt, remove special characters, retry |
| Prompt approved but nothing in Claude | Call `check_handoff_status` — if prompt file exists but no response, the watcher may have stopped. In Claude Code: `/chatgpt-session` |
| `get_response` times out | Do NOT resubmit — call `check_handoff_status` first. If prompt file exists, Claude may still be working; keep polling |
| Status says running / safe_to_send false | Wait — Claude is executing. Poll `get_response`, do not send again |
| Duplicate execution risk | Always call `check_handoff_status` before sending — if pending_prompt_count > 0, wait |
| ngrok URL changed after restart | ngrok free tier gives a new URL every run. You cannot edit an existing MCP connector — delete it and create a new one (Project → Settings → Apps → delete old app → Create app with new URL). Takes 30 seconds. |
| Connector stale after restart | Delete and re-add the MCP app in ChatGPT project settings |
| Nothing works | **Manual fallback:** copy ChatGPT's structured prompt into Claude Code directly. Summarize result back. Always works. |

> Long waits (up to 600s) depend on platform support. This is a powerful pattern with real-world rough edges — the checklist above covers the common ones.

## License

MIT
