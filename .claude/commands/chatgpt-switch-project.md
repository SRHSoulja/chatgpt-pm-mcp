# /chatgpt-switch-project

You are switching an existing ChatGPT PM MCP setup to point at a new project folder. The MCP server, ngrok, and ChatGPT connector are already configured — this only updates the project-specific files.

---

## STEP 1 — Find the MCP repo

```bash
cat ~/.chatgpt-pm-mcp/repo-path 2>/dev/null
```

Use the path as `MCP_REPO`. If missing, tell the user to run `bash install.sh` from the chatgpt-pm-mcp repo first.

---

## STEP 2 — Confirm the new project folder

Tell the user:
> "Switching to: `[current directory]`. Is this the right project? (yes/no)"

Wait for confirmation. If no, ask for the correct path.

---

## STEP 3 — Update PROJECT_ROOT in .env

Write `PROJECT_ROOT=[current path]` to `[MCP_REPO]/.env`.

Tell the user: "Updated PROJECT_ROOT to [path]."

---

## STEP 4 — CLAUDE.md

Check if `CLAUDE.md` exists in the current directory.

**If it does NOT exist:** Create a minimal one:
```markdown
# Project Setup

To start a ChatGPT PM session:
1. Run `bash [MCP_REPO]/start.sh` in a terminal
2. Open Claude Code here and run `/chatgpt-session`
```

**If it DOES exist:** Do NOT overwrite it. Tell the user:
> "You already have a CLAUDE.md here — leaving it unchanged."

---

## STEP 5 — .chatgpt-resume.md

Check if `.chatgpt-resume.md` already exists.

**If it exists:** Tell the user:
> "Found an existing `.chatgpt-resume.md` — keeping it. Type `/resume` in ChatGPT to load this project's context."

**If it does NOT exist:** Ask:
> "Tell me 2-3 sentences about this project: what it is, what's been built, and what you're working on next."

Once they answer, write `.chatgpt-resume.md`:

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

---

## STEP 6 — Restart the server

Tell the user:
> "Project switched. Restart the server to pick up the new PROJECT_ROOT:
>
> ```bash
> bash [MCP_REPO]/start.sh restart
> ```
>
> Then in ChatGPT, type `/context` to reload your project files. You're ready to go."
