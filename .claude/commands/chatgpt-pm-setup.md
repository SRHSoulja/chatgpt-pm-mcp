# /chatgpt-pm-setup

You are setting up the ChatGPT PM MCP bridge for this project. This connects ChatGPT to Claude Code via a local MCP server so ChatGPT can read project context, plan scoped tasks, and send work here via MCP.

The user has already cloned `chatgpt-pm-mcp` and run `bash install.sh` from that repo — this command was installed by that step. Now you are running inside the **target project folder** (the project ChatGPT will manage).

Walk the user through setup one step at a time. Wait for their input before proceeding.

---

## STEP 1 — Confirm project folder

Tell the user:

> "I'm going to set up the ChatGPT PM MCP bridge for this project. I'll check a few things, then guide you through connecting ChatGPT.
>
> First: is this the right project folder? Type **yes** to continue, or give me the correct path."

Wait for confirmation.

---

## STEP 2 — Check dependencies

Check the following and report status:

```bash
node --version 2>/dev/null && echo "node: ok" || echo "node: MISSING — install from nodejs.org"
npm --version 2>/dev/null && echo "npm: ok" || echo "npm: MISSING"
ngrok --version 2>/dev/null && echo "ngrok: ok" || echo "ngrok: not found — needed to expose the server; get it at ngrok.com (free tier works)"
inotifywait --version 2>/dev/null && echo "inotifywait: ok" || echo "inotifywait: not found — watcher will use polling fallback (slower but works)"
```

Report results. If node or npm is missing, stop and tell the user to install them first. ngrok and inotifywait warnings are non-blocking.

---

## STEP 3 — Install MCP server dependencies

Run:
```bash
cd ~/chatgpt-pm-mcp && npm install
```

Tell the user: "Installing MCP server dependencies..."

---

## STEP 4 — Create .env

Check if `~/chatgpt-pm-mcp/.env` exists. If not:

```bash
cp ~/chatgpt-pm-mcp/.env.example ~/chatgpt-pm-mcp/.env
```

Then write `PROJECT_ROOT` to the `.env` file with the current project path (use `pwd`).

Tell the user: "I've set PROJECT_ROOT to [current path] in ~/chatgpt-pm-mcp/.env. Does that look right?"

Wait for confirmation.

---

## STEP 5 — CLAUDE.md safety check

Check if `CLAUDE.md` exists in the current directory.

**If CLAUDE.md does NOT exist:** Create a minimal one:
```markdown
# Project Setup

To start a ChatGPT PM session:
1. Run `bash ~/chatgpt-pm-mcp/start.sh` in a terminal
2. Open Claude Code here and run `/chatgpt-session`
```

**If CLAUDE.md DOES exist:** Do NOT overwrite it. Tell the user:
> "You already have a CLAUDE.md in this project. I won't touch it. You can optionally add this line to the bottom:
>
> `# ChatGPT PM: run /chatgpt-session to start the bridge watcher`
>
> Type **add** to append it, or **skip** to leave CLAUDE.md unchanged."

Wait for their choice and act accordingly.

---

## STEP 6 — Create .chatgpt-resume.md

Ask the user:

> "Tell me 2-3 sentences about this project: what it is, what's been built, and what you're working on next."

Once they answer, write `.chatgpt-resume.md` to the current directory:

```markdown
# Project: [inferred name from folder]
_Last updated: [today's date]_

## What This Is
[their description]

## Current State
[what exists — list key files/dirs you can see]

## Active Goal
[what they said they're working on next]

## How to Use ChatGPT PM
Type `/resume` in your ChatGPT Project to reload this context.
Type `/plan [task]` to plan and send a task to Claude Code.
Type `/response` to read what Claude Code did.
Type `/check` to verify the MCP connection.
```

Tell them: "Created `.chatgpt-resume.md`. ChatGPT will read this when you type `/resume`."

---

## STEP 7 — ngrok setup

Tell the user:

> "Now start the server and ngrok. In a new terminal, run:
>
> ```bash
> bash ~/chatgpt-pm-mcp/start.sh
> ```
>
> You'll see a line like: `https://abc123.ngrok-free.app`
>
> Paste that URL here."

Wait for them to paste the ngrok URL.

---

## STEP 8 — ChatGPT Project setup

Once you have the ngrok URL:

> "Now set up the ChatGPT side:
>
> 1. **Enable Developer Mode** — ChatGPT Settings → Apps → Advanced Mode → Advanced Settings → Developer Mode ON
> 2. **Create a new Project** — set memory to **'Project only'** during creation (this option disappears after)
> 3. **Add MCP app** — Project Settings → Apps → Create App → Name: Project PM → URL: [NGROK_URL]/sse → Auth: None
> 4. **Paste project instructions** — open `~/chatgpt-pm-mcp/chatgpt-instructions.md`, copy everything after the divider, paste into your ChatGPT Project instructions
> 5. **Verify** — in ChatGPT, type: `Check the MCP tools available for this project and tell me what you can do.` ChatGPT will call `get_commands()` and report back. You may not see tools listed in the UI — that's normal.
>
> Type **connected** when ChatGPT reports the tools."

Wait for "connected".

---

## STEP 9 — Start your first session

Tell the user:

> "You're set up. Here's how to run a session:
>
> **Terminal 1 (already running):**
> `bash ~/chatgpt-pm-mcp/start.sh` — server + ngrok
>
> **Here in Claude Code:**
> `/chatgpt-session` — starts the watcher, puts Claude into executor mode
>
> **In ChatGPT:**
> 1. `/resume` — ChatGPT reads your project context
> 2. Tell ChatGPT what you want to work on
> 3. `/plan [task]` — ChatGPT reads your files, structures the task, asks to confirm
> 4. `/send` — ChatGPT sends via MCP when the bridge is healthy
> 5. Claude Code picks it up via the watcher and executes
> 6. ChatGPT reads the result automatically (polls up to 10 min)
>
> If ChatGPT doesn't respond or the bridge seems stuck, type `/check` — ChatGPT will call `check_handoff_status()` and tell you exactly what's wrong.
>
> Less copy-paste. Less manual context passing. Clear fallbacks when tools need help.
>
> Good luck — ship something."
