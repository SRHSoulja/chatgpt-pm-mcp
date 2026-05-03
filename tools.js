import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const ROOT = process.env.PROJECT_ROOT || process.cwd();

function safePath(p) {
  const resolved = path.resolve(ROOT, p);
  if (!resolved.startsWith(ROOT)) throw new Error('Path outside project root');
  return resolved;
}

export const tools = [
  {
    name: 'read_file',
    description: 'Read a file from the project. Use relative paths.',
    inputSchema: {
      type: 'object',
      properties: { path: { type: 'string', description: 'Relative file path' } },
      required: ['path'],
    },
    handler: ({ path: p }) => {
      const content = fs.readFileSync(safePath(p), 'utf8');
      return { content: content.slice(0, 8000) };
    },
  },
  {
    name: 'list_directory',
    description: 'List files in a directory. Defaults to project root.',
    inputSchema: {
      type: 'object',
      properties: { path: { type: 'string', description: 'Relative path (optional)' } },
    },
    handler: ({ path: p = '.' }) => {
      const entries = fs.readdirSync(safePath(p), { withFileTypes: true });
      return {
        entries: entries
          .filter(e => !e.name.startsWith('.') || e.name === '.mcp-response.md')
          .map(e => ({ name: e.name, type: e.isDirectory() ? 'dir' : 'file' })),
      };
    },
  },
  {
    name: 'get_project_context',
    description: 'Get project overview from CLAUDE.md, README.md, or .chatgpt-resume.md.',
    inputSchema: { type: 'object', properties: {} },
    handler: () => {
      for (const name of ['.chatgpt-resume.md', 'CLAUDE.md', 'README.md', 'readme.md']) {
        const fp = path.join(ROOT, name);
        if (fs.existsSync(fp)) {
          return { file: name, content: fs.readFileSync(fp, 'utf8').slice(0, 6000) };
        }
      }
      return { content: 'No context file found. Ask Claude Code to create a .chatgpt-resume.md.' };
    },
  },
  {
    name: 'get_git_log',
    description: 'Get recent git commits to understand what has changed.',
    inputSchema: {
      type: 'object',
      properties: { n: { type: 'number', description: 'Number of commits (default 10)' } },
    },
    handler: ({ n = 10 }) => {
      try {
        const log = execSync(`git -C "${ROOT}" log --oneline -${n}`, { encoding: 'utf8' });
        return { log };
      } catch {
        return { error: 'Not a git repo or git not installed' };
      }
    },
  },
  {
    name: 'submit_prompt',
    description: 'Send a scoped task prompt to Claude Code via the MCP bridge. Claude picks it up via the file watcher when the handoff is healthy.',
    inputSchema: {
      type: 'object',
      properties: {
        prompt: { type: 'string', description: 'The full self-contained task prompt for Claude Code' },
      },
      required: ['prompt'],
    },
    handler: ({ prompt }) => {
      const promptDir = path.join(ROOT, '.mcp-prompts');
      fs.mkdirSync(promptDir, { recursive: true });
      const filename = `${new Date().toISOString().replace(/[:.]/g, '-')}.md`;
      const fp = path.join(promptDir, filename);
      fs.writeFileSync(fp, prompt);
      return {
        submitted: true,
        file: filename,
        message: 'Claude Code will pick this up automatically from .mcp-prompts/. Use get_response() to check when it\'s done.',
      };
    },
  },
  {
    name: 'get_response',
    description: 'Read Claude Code\'s response to the last submitted prompt. Pass timeout_seconds to poll until ready (max 600).',
    inputSchema: {
      type: 'object',
      properties: {
        timeout_seconds: {
          type: 'number',
          description: 'How long to wait for Claude to finish, in seconds (0 = check once, max 600). Default: 0.',
        },
      },
    },
    handler: async ({ timeout_seconds = 0 }) => {
      const fp = path.join(ROOT, '.mcp-response.md');
      const maxWait = Math.min(Math.max(0, timeout_seconds), 600) * 1000;
      const pollInterval = 5000;
      const deadline = Date.now() + maxWait;

      const read = () => {
        if (!fs.existsSync(fp)) return null;
        const content = fs.readFileSync(fp, 'utf8');
        const stat = fs.statSync(fp);
        return { ready: true, response: content, updated: stat.mtime.toISOString() };
      };

      const result = read();
      if (result || maxWait === 0) {
        return result || { ready: false, message: 'No response yet. Claude is still working.' };
      }

      while (Date.now() < deadline) {
        await new Promise(r => setTimeout(r, pollInterval));
        const r = read();
        if (r) return r;
      }

      return { ready: false, message: `Timed out after ${timeout_seconds}s. Claude may still be working — call get_response() again to check.` };
    },
  },
  {
    name: 'write_task',
    description: 'Write a task to TASKS.md for Claude Code to pick up later.',
    inputSchema: {
      type: 'object',
      properties: { content: { type: 'string', description: 'Task description' } },
      required: ['content'],
    },
    handler: ({ content }) => {
      const fp = path.join(ROOT, 'TASKS.md');
      const entry = `\n## ${new Date().toISOString()}\n${content}\n`;
      fs.appendFileSync(fp, entry);
      return { written: true, file: 'TASKS.md' };
    },
  },
  {
    name: 'get_commands',
    description: 'List all available MCP tools, what they do, and how to use them. Call this to verify the MCP connection is working and to tell the user what you can do.',
    inputSchema: { type: 'object', properties: {} },
    handler: () => ({
      tools: [
        { name: 'read_file', usage: 'read_file(path)', description: 'Read any project file. Use relative paths from project root.' },
        { name: 'list_directory', usage: 'list_directory(path?)', description: 'List files in a directory. Defaults to project root.' },
        { name: 'get_project_context', usage: 'get_project_context()', description: 'Load project overview from .chatgpt-resume.md, CLAUDE.md, or README. Call at session start.' },
        { name: 'get_git_log', usage: 'get_git_log(n?)', description: 'Get recent git commits. Default 10.' },
        { name: 'write_task', usage: 'write_task(content)', description: 'Save a task idea to TASKS.md backlog. Does NOT execute anything — use submit_prompt to act.' },
        { name: 'submit_prompt', usage: 'submit_prompt(prompt)', description: 'Send a self-contained task to Claude Code. Claude picks it up via the file watcher and executes it.' },
        { name: 'get_response', usage: 'get_response(timeout_seconds?)', description: 'Poll for Claude Code\'s response. Waits up to timeout_seconds (default 600, max 600). If timed_out, do NOT resubmit — call again to keep polling.' },
        { name: 'get_commands', usage: 'get_commands()', description: 'This tool. Returns all available tools and usage.' },
        { name: 'check_handoff_status', usage: 'check_handoff_status()', description: 'Check handoff health. Shows pending prompts, response state, and what to do next. Call before resubmitting.' },
      ],
      note: 'If you can read this, the MCP connection is working. Tell the user which tools are available and that you are ready to start.',
    }),
  },
  {
    name: 'check_handoff_status',
    description: 'Check the health of the ChatGPT → MCP → Claude Code handoff. Use this before resubmitting a prompt to understand exactly where the pipeline stands.',
    inputSchema: { type: 'object', properties: {} },
    handler: () => {
      const promptDir = path.join(ROOT, '.mcp-prompts');
      const responseFile = path.join(ROOT, '.mcp-response.md');

      // Check for pending prompt files
      let pendingPrompts = [];
      if (fs.existsSync(promptDir)) {
        pendingPrompts = fs.readdirSync(promptDir)
          .filter(f => f.endsWith('.md'))
          .map(f => {
            const fp = path.join(promptDir, f);
            return { file: f, written_at: fs.statSync(fp).mtime.toISOString() };
          })
          .sort((a, b) => b.written_at.localeCompare(a.written_at));
      }

      // Check response file
      let lastResponse = null;
      if (fs.existsSync(responseFile)) {
        const stat = fs.statSync(responseFile);
        lastResponse = { exists: true, updated_at: stat.mtime.toISOString() };
      }

      const hasPending = pendingPrompts.length > 0;
      const hasResponse = lastResponse !== null;

      let bridge_state, recommended_action;
      if (!hasPending && !hasResponse) {
        bridge_state = 'idle_clean';
        recommended_action = 'Ready to send. No pending prompts and no prior response. Submit a new prompt.';
      } else if (hasPending && !hasResponse) {
        bridge_state = 'prompt_pending_no_response';
        recommended_action = 'A prompt was written to .mcp-prompts/ but Claude has not responded yet. Wait and call get_response(), or check that the watcher is running in Claude Code (/chatgpt-session). Do NOT resubmit.';
      } else if (hasPending && hasResponse) {
        bridge_state = 'prompt_pending_with_response';
        recommended_action = 'A prompt file exists AND a response file exists. Claude may have processed a prior prompt. Call get_response() to read it before deciding whether to send anything new.';
      } else {
        bridge_state = 'idle_with_prior_response';
        recommended_action = 'No pending prompts. A prior response exists. Ready to send a new prompt.';
      }

      return {
        bridge_state,
        safe_to_send: !hasPending,
        pending_prompts: pendingPrompts,
        pending_prompt_count: pendingPrompts.length,
        last_prompt_file: pendingPrompts[0]?.file || null,
        last_prompt_time: pendingPrompts[0]?.written_at || null,
        last_response: lastResponse,
        recommended_action,
        handoff_stages: {
          '1_platform_dispatch': 'Cannot verify from here — if this tool responded, the MCP connection is alive',
          '2_prompt_file_written': hasPending ? `YES — ${pendingPrompts.length} file(s) in .mcp-prompts/` : 'No pending files',
          '3_claude_picked_up': 'Cannot verify directly — check with the user if Claude Code is showing the watcher prompt',
          '4_response_produced': hasResponse ? `YES — response file exists (${lastResponse.updated_at})` : 'Not yet',
        },
      };
    },
  },
];
