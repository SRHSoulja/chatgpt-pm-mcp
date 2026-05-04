# /chatgpt-pm-setup

You are setting up the ChatGPT PM MCP bridge for this project. This connects ChatGPT to Claude Code via a local MCP server so ChatGPT can read project context, plan scoped tasks, and send work here via MCP — with less copy-paste, less manual context passing, and clear fallbacks when tools need help.

**Supported environments: Linux, macOS, Windows via WSL2.**
If the user is on Windows without WSL2, stop and tell them: "This kit requires WSL2 on Windows. Please install WSL2 (Ubuntu or Debian), then clone the repo and run install.sh inside your WSL terminal."

The user has already cloned `chatgpt-pm-mcp` and run `bash install.sh` from that repo. Now you are running inside the **target project folder** — the project ChatGPT will manage and Claude Code will work on.

Walk the user through setup one step at a time. Wait for input before proceeding.

---

## STEP 1 — Find the MCP repo

Read the saved repo path:
```bash
cat ~/.chatgpt-pm-mcp/repo-path 2>/dev/null
```

If the file exists and contains a valid path, use it as `MCP_REPO`. Confirm with the user:
> "I found the MCP setup repo at: [MCP_REPO]. Does that look right? (yes/no)"

If the file is missing or empty, tell the user:
> "I couldn't find the saved repo path. Where did you clone `chatgpt-pm-mcp`? Give me the full path (e.g. `/home/yourname/chatgpt-pm-mcp`)."

Wait for their answer and use it as `MCP_REPO`.

---

## STEP 2 — Confirm target project folder

Tell the user:
> "I'll set up this project at: `[current directory]`. Is this the right folder? (yes/no)"

Wait for confirmation. If no, ask for the correct path.

---

## STEP 3 — Check dependencies

Run each check and report status:

```bash
node --version 2>/dev/null && echo "node: ok" || echo "node: MISSING — install from nodejs.org"
npm --version 2>/dev/null && echo "npm: ok" || echo "npm: MISSING"
ngrok --version 2>/dev/null && echo "ngrok: ok" || echo "ngrok: not found — needed later; get free tier at ngrok.com"
inotifywait --version 2>/dev/null && echo "inotifywait: ok (fast watcher)" || echo "inotifywait: not found — polling fallback will be used (works, slightly slower)"
```

- **node/npm missing**: stop and tell the user to run:
  ```bash
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  ```
  Then re-run `/chatgpt-pm-setup`.
- **ngrok not found**: non-blocking — note it is needed in a later step
- **inotifywait not found**: non-blocking — watcher.sh has a polling fallback that works without it

---

## STEP 4 — Install MCP server dependencies

Run:
```bash
cd [MCP_REPO] && npm install
```

Tell the user: "Installing MCP server dependencies in [MCP_REPO]..."

---

## STEP 5 — Create .env

Check if `[MCP_REPO]/.env` exists. If not, copy `.env.example`:
```bash
cp [MCP_REPO]/.env.example [MCP_REPO]/.env
```

Write `PROJECT_ROOT` to the `.env` file with the current target project path (use `pwd`).

Tell the user: "Set PROJECT_ROOT=[current path] in [MCP_REPO]/.env. Does that look right?"

Wait for confirmation.

---

## STEP 6 — CLAUDE.md safety check

Check if `CLAUDE.md` exists in the current directory.

**If CLAUDE.md does NOT exist:** Create a minimal one:
```markdown
# Project Setup

To start a ChatGPT PM session:
1. Run `bash [MCP_REPO]/start.sh` in a terminal
2. Open Claude Code here and run `/chatgpt-session`
```

**If CLAUDE.md DOES exist:** Do NOT overwrite it. Tell the user:
> "You already have a CLAUDE.md here. I won't overwrite it. You can optionally add this line:
>
> `# ChatGPT PM: run /chatgpt-session to start the bridge watcher`
>
> Type **add** to append it, or **skip** to leave CLAUDE.md unchanged."

Wait for their choice and act accordingly.

---

## STEP 7 — Create .chatgpt-resume.md

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

## STEP 8 — ngrok setup

First check if ngrok is installed:
```bash
ngrok --version 2>/dev/null && echo "ngrok: ok" || echo "ngrok: MISSING"
```

**If ngrok is MISSING**, stop and tell the user:
> "ngrok is required before we can connect ChatGPT. ChatGPT is a cloud service and needs a public HTTPS URL to reach your local MCP server.
>
> Install ngrok for Linux/WSL2:
> ```bash
> curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
> echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' | sudo tee /etc/apt/sources.list.d/ngrok.list
> sudo apt update && sudo apt install ngrok
> ```
>
> macOS:
> ```bash
> brew install ngrok
> ```
>
> Then get a free auth token:
> 1. Go to **https://ngrok.com** and sign up for a free account
> 2. After signing in, go to **https://dashboard.ngrok.com/authtokens**
> 3. Copy your token, then run:
> ```bash
> ngrok config add-authtoken YOUR_TOKEN_HERE
> ```
>
> Once ngrok is installed and authenticated, run `start.sh` and then continue setup."

Wait for the user to confirm ngrok is installed. Do not proceed to Step 9 until they confirm.

**If ngrok is installed**, tell the user:
> "Start the server and ngrok now. In a new terminal, run:
>
> ```bash
> bash [MCP_REPO]/start.sh
> ```
>
> `start.sh` checks for ngrok, starts the MCP server, and waits for the tunnel URL. When it's ready, you'll see a box like this:
>
> ```
> ┌─────────────────────────────────────────────────────┐
> │  ngrok tunnel URL:                                  │
> │  https://YOURCODE.ngrok-free.app                    │
> │                                                     │
> │  Use this in ChatGPT → Create App:                 │
> │  MCP Server URL: https://YOURCODE.ngrok-free.app/sse│
> └─────────────────────────────────────────────────────┘
> ```
>
> Copy the `https://YOURCODE.ngrok-free.app` line and paste it here. Your URL will be different each run — do not type `abc123` or any example URL."

Wait for them to paste the real ngrok URL. If the URL they paste contains `abc123` or does not start with `https://`, ask them to check the `start.sh` output again — it prints the real URL in the box above.

---

## STEP 9 — ChatGPT Project setup

Once you have the ngrok URL, tell the user:

> "Now set up the ChatGPT side:
>
> **1. Create a ChatGPT Project**
> Click **+ New Project** in the ChatGPT sidebar and give it a name. In the project settings (gear icon), set **Memory** to **"Project only"** to keep this isolated from your other chats.
>
> **2. Enable Developer Mode**
> Inside the project, go to **Settings → Apps**. Toggle **Developer mode** ON.
> You'll see an 'ELEVATED RISK' warning — this is expected.
> Leave **'Enforce CSP in developer mode'** OFF (needed for your ngrok tunnel to work).
>
> **3. Create the MCP app**
> With Developer mode on, a **Create app** button appears. Click it and fill out the form:
> - **Name:** Project PM (or whatever you like)
> - **MCP Server URL:** [NGROK_URL]/sse
> - **Authentication:** change the dropdown from OAuth → **None**
> - Check **'I understand and want to continue'**
> - Click **Create**
>
> **4. Paste project instructions**
> Open `[MCP_REPO]/chatgpt-instructions.md`, copy the full contents, and paste into your ChatGPT Project instructions (Project → Settings → Instructions).
>
> **5. Verify the connection**
> In your ChatGPT Project, type:
> `Check the MCP tools available for this project and tell me what you can do.`
> ChatGPT calls `get_commands()` and reports back. You may not see tools listed in the UI — that's normal.
>
> Type **connected** when ChatGPT reports the tools."

Wait for "connected".

---

## STEP 10 — First session

Tell the user:

> "You're set up. Here's how to run a session:
>
> **Terminal 1 (if not already running):**
> ```bash
> bash [MCP_REPO]/start.sh
> ```
>
> **Here in Claude Code:**
> ```
> /chatgpt-session
> ```
> Starts the watcher and puts Claude into executor mode.
>
> **In ChatGPT:**
> 1. `/resume` — ChatGPT reads your project context
> 2. Tell ChatGPT what you want to work on
> 3. `/plan [task]` — ChatGPT reads your files, structures the task, asks to confirm
> 4. `/send` — ChatGPT sends via MCP when the bridge is healthy
> 5. Claude Code picks it up via the watcher and executes
> 6. ChatGPT reads the result automatically (polls up to 10 min)
>
> If the bridge seems stuck, type `/check` — ChatGPT calls `check_handoff_status()` and tells you what's wrong.
>
> Less copy-paste. Less manual context passing. Clear fallbacks when tools need help.
>
> Good luck — ship something."
