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
    description: 'Send a task prompt directly to Claude Code. Claude picks it up automatically — no copy-paste needed.',
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
    description: 'Read Claude Code\'s response to the last submitted prompt.',
    inputSchema: { type: 'object', properties: {} },
    handler: () => {
      const fp = path.join(ROOT, '.mcp-response.md');
      if (!fs.existsSync(fp)) {
        return { ready: false, message: 'No response yet. Claude is still working. Try again in 30 seconds.' };
      }
      const content = fs.readFileSync(fp, 'utf8');
      const stat = fs.statSync(fp);
      return { ready: true, response: content, updated: stat.mtime.toISOString() };
    },
  },
  {
    name: 'write_note',
    description: 'Write a note or task to the project backlog for later.',
    inputSchema: {
      type: 'object',
      properties: { content: { type: 'string', description: 'Note content' } },
      required: ['content'],
    },
    handler: ({ content }) => {
      const fp = path.join(ROOT, 'BACKLOG.md');
      const entry = `\n## ${new Date().toISOString()}\n${content}\n`;
      fs.appendFileSync(fp, entry);
      return { written: true, file: 'BACKLOG.md' };
    },
  },
];
