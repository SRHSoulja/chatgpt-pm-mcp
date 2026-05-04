import 'dotenv/config';
import express from 'express';
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { SSEServerTransport } from '@modelcontextprotocol/sdk/server/sse.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { tools } from './tools.js';

const app = express();
app.use(express.json());

// CORS — required for ChatGPT to connect
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

// Each SSE connection gets its own Server instance — the MCP SDK does not
// support reusing a single Server across multiple transports.
function createServer() {
  const server = new Server(
    { name: 'project-pm', version: '1.0.0' },
    { capabilities: { tools: {} } }
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: tools.map(({ name, description, inputSchema }) => ({ name, description, inputSchema })),
  }));

  server.setRequestHandler(CallToolRequestSchema, async (req) => {
    const tool = tools.find(t => t.name === req.params.name);
    if (!tool) throw new Error(`Unknown tool: ${req.params.name}`);
    try {
      const result = await tool.handler(req.params.arguments ?? {});
      return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: `Error: ${err.message}` }], isError: true };
    }
  });

  return server;
}

const transports = {};

app.get('/sse', async (req, res) => {
  const server = createServer();
  // SSEServerTransport (SDK ≤1.29) ignores the absolute URL passed to it and
  // always emits `data: /messages?sessionId=...`. ChatGPT needs a full URL to
  // POST tool calls back. Patch res.write to rewrite that one event line.
  const proto = req.headers['x-forwarded-proto'] || 'https';
  const host  = req.headers['x-forwarded-host'] || req.headers['host'] || `localhost:${PORT}`;
  const base  = `${proto}://${host}`;

  const origWrite = res.write.bind(res);
  res.write = (chunk, ...args) => {
    let str = typeof chunk === 'string' ? chunk : chunk.toString('utf8');
    // Replace `data: /messages?` with the absolute URL so ChatGPT can POST back.
    str = str.replace(/(data: )(\/messages\?)/g, `$1${base}$2`);
    const patched = Buffer.isBuffer(chunk) ? Buffer.from(str, 'utf8') : str;
    return origWrite(patched, ...args);
  };

  const transport = new SSEServerTransport('/messages', res);
  transports[transport.sessionId] = transport;
  res.on('close', () => {
    delete transports[transport.sessionId];
    server.close().catch(() => {});
  });
  await server.connect(transport);
});

app.post('/messages', async (req, res) => {
  const { sessionId } = req.query;
  const transport = transports[sessionId];
  if (!transport) return res.status(400).json({ error: 'Unknown session' });
  await transport.handlePostMessage(req, res);
});

const PORT = process.env.PORT || 3333;
app.listen(PORT, () => {
  console.log(`MCP server running → http://localhost:${PORT}`);
  console.log(`Tools: ${tools.map(t => t.name).join(', ')}`);
  console.log(`Project root: ${process.env.PROJECT_ROOT || process.cwd()}`);
});
