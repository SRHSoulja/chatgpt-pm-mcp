# chatgpt-pm-mcp — Setup Guide

You are Claude Code. The user has cloned this repo and wants to connect ChatGPT to their project as an AI project manager. Walk them through the setup interactively — one step at a time, waiting for their input before proceeding.

Do not do all steps at once. Guide, confirm, then move forward.

---

## SETUP FLOW

### Step 1 — Welcome

When the user first runs `claude` in this directory, introduce what you're setting up:

> "Welcome. I'm going to help you connect ChatGPT to your project so it can act as your AI project manager — reading project context, planning scoped tasks, and sending work to Claude Code via MCP with less manual context passing. This takes about 10 minutes. Let's go."

Then ask:
> "First: what is the full path to the project you want to connect? (e.g. /home/yourname/myproject)"

Wait for their answer.

### Step 2 — Create .env

Once they give you the project path:

1. Copy `.env.example` to `.env` in this directory
2. Fill in `PROJECT_ROOT` with the path they gave you
3. Confirm: "I've set up your .env. Your project root is: [path]. Does that look right?"

### Step 3 — Install Dependencies

Run `npm install` in this directory. Tell the user what's installing and why.

### Step 4 — ngrok Setup

Tell the user:
> "Now we need ngrok so ChatGPT can reach your local server. If you don't have it:
> 1. Go to ngrok.com and sign up free
> 2. Install it: `brew install ngrok` (Mac) or download from ngrok.com/download (Windows/Linux)
> 3. Authenticate: `ngrok config add-authtoken YOUR_TOKEN` (your token is at dashboard.ngrok.com)
>
> Once installed, open a new terminal and run:
> ```
> npm start
> ```
> Then in another terminal:
> ```
> ngrok http 3333
> ```
>
> You'll see a line like:
> `Forwarding  https://abc123.ngrok-free.app → http://localhost:3333`
>
> Paste that https URL back here."

Wait for them to paste the ngrok URL.

### Step 5 — ChatGPT Setup

Once you have the ngrok URL, tell them:

> "Great. Now set up the ChatGPT side:
>
> **1. Create a ChatGPT Project**
> - Click **+ New Project** in the ChatGPT sidebar and name it after your project
>
> **2. Enable Developer Mode**
> - Inside the project, go to **Settings → Apps**
> - Toggle **Developer mode** ON — you'll see an 'ELEVATED RISK' warning, that's expected
> - Leave **'Enforce CSP in developer mode'** OFF (needed for your ngrok tunnel)
>
> **3. Create the MCP app**
> - With Developer mode on, a **Create app** button appears — click it
> - **Name:** Project PM
> - **MCP Server URL:** [THEIR_NGROK_URL]/sse
> - **Authentication:** change the dropdown from OAuth → **None**
> - Check **'I understand and want to continue'**
> - Click **Create**
>
> **4. Connect Claude Code**
> Run this in your project directory (not this one):
> ```
> claude mcp add project-pm --transport sse [THEIR_NGROK_URL]/sse
> ```
>
> Done? Type 'connected' when the ChatGPT app shows your tools."

Wait for "connected" or questions.

### Step 6 — Project Instructions

Tell them:

> "Now paste the project manager instructions into your ChatGPT Project. Open `chatgpt-instructions.md` from this repo, copy everything after the divider line, and paste it into: ChatGPT Project → Instructions."

Wait for confirmation.

### Step 7 — Generate Resume File

Now ask about their project:
> "Tell me a few sentences about your project: what it is, what you're building, what's been done so far, and what you're working on next."

Once they tell you, write a `.chatgpt-resume.md` file to THEIR PROJECT ROOT (the path from Step 2) with this structure:

```markdown
# Project: [name]
_Last updated: [date]_

## What This Is
[their description]

## Current State
[what exists, what's been built]

## Active Goal
[what they're working on now]

## Key Files
[list the main files/dirs you can see in their project root]

## How to Resume
Type `/resume` in ChatGPT to reload this context.
Type `/plan [task]` to plan and submit a task to Claude Code.
Type `/response` to read what Claude Code just did.
```

Tell them: "I've written `.chatgpt-resume.md` to your project. ChatGPT will read this when you type `/resume`."

### Step 8 — Install the Session Skill

Do the following automatically (no user input needed):

1. Create `.claude/commands/` in the user's PROJECT ROOT (the path from Step 2)
2. Copy `.claude/commands/chatgpt-session.md` from THIS repo into that directory
3. Update the watcher path inside the copied file to use the absolute path to watcher.sh in this repo

Tell them:
> "I've installed a `/chatgpt-session` skill into your project. When you open Claude Code in your project, just type `/chatgpt-session` and it will start the watcher and put Claude Code into PM executor mode automatically."

### Step 9 — First Session

Tell them:
> "You're set up. The server and watcher are two halves of one setup — never run one without the other.
>
> **Terminal 1 — start server + ngrok together:**
> ```
> bash ~/chatgpt-pm-mcp/start.sh
> ```
>
> **Terminal 2 — your project (watcher):**
> ```
> cd [YOUR PROJECT PATH] && claude
> ```
> Then type: `/chatgpt-session`
>
> `/chatgpt-session` will verify the server is running before starting the watcher. If you skipped `start.sh`, it will tell you and help you start it.
>
> **In ChatGPT:**
> 1. Type `/resume` — ChatGPT reads your project and orients itself
> 2. Tell ChatGPT what you want to work on
> 3. Use `/plan` to have ChatGPT read your files and structure the task — confirm before it sends
> 4. Use `/send` — ChatGPT calls `submit_prompt()` via MCP
> 5. Claude Code picks it up via the watcher and executes it
> 6. Claude Code writes the result to `.mcp-response.md` and ChatGPT reads it automatically
>
> You're out of the middle. Good luck — ship something."

---

## AFTER SETUP

If the user returns to this directory later, check if `.env` already exists. If it does, they're already set up. Ask if they need help or want to update their project context.

If they say "update resume" or similar — read their project root, ask what's changed, and rewrite `.chatgpt-resume.md`.

## NOTES

- Never store secrets in any file that gets committed
- The `.env` file is gitignored
- `.mcp-prompts/` and `.mcp-response.md` are gitignored (project-specific runtime files)
- The watcher.sh works on Linux/WSL (inotify), Mac (fswatch), or falls back to polling
