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

## Tools Exposed to ChatGPT

| Tool | What it does |
|------|-------------|
| `read_file` | Read any project file |
| `list_directory` | List files in a directory |
| `get_project_context` | Load .chatgpt-resume.md / CLAUDE.md / README |
| `get_git_log` | Recent git commits |
| `submit_prompt` | Send a task directly to Claude Code |
| `get_response` | Read Claude Code's response |
| `write_task` | Add a task to TASKS.md for Claude Code |

## Slash Commands (in ChatGPT)

Once you paste `chatgpt-instructions.md` into your ChatGPT Project:

| Command | What happens |
|---------|-------------|
| `/resume` | ChatGPT reads .chatgpt-resume.md and orients itself |
| `/plan [task]` | ChatGPT reads context, structures the task, asks to confirm |
| `/send` | ChatGPT calls submit_prompt() with the last plan |
| `/response` | ChatGPT reads .mcp-response.md |
| `/context` | ChatGPT reloads project files |
| `/task [text]` | Saves to TASKS.md |

## License

MIT
