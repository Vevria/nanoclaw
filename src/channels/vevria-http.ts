import { registerChannel } from './registry.js';
import {
  Channel,
  NewMessage,
  OnInboundMessage,
  OnChatMetadata,
} from '../types.js';
import type { ChannelOpts } from './registry.js';
import http from 'node:http';
import { randomUUID } from 'node:crypto';

const VEVRIA_HTTP_PORT = parseInt(process.env.VEVRIA_HTTP_PORT || '3100', 10);
const VEVRIA_CALLBACK_URL = process.env.VEVRIA_CALLBACK_URL || '';
const VEVRIA_AGENT_ID = process.env.VEVRIA_AGENT_ID || '';
const VEVRIA_COMPANY_ID = process.env.VEVRIA_COMPANY_ID || '';
const VEVRIA_INTERNAL_KEY = process.env.VEVRIA_INTERNAL_KEY || '';

function readBody(req: http.IncomingMessage): Promise<string> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    req.on('data', (chunk: Buffer) => chunks.push(chunk));
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf-8')));
    req.on('error', reject);
  });
}

function jsonResponse(
  res: http.ServerResponse,
  status: number,
  body: Record<string, unknown>,
): void {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

class VevriaHttpChannel implements Channel {
  name = 'vevria-http';
  private server: http.Server | null = null;
  private onMessage: OnInboundMessage;
  private onChatMetadata: OnChatMetadata;
  private connected = false;

  constructor(opts: ChannelOpts) {
    this.onMessage = opts.onMessage;
    this.onChatMetadata = opts.onChatMetadata;
  }

  async connect(): Promise<void> {
    this.server = http.createServer(async (req, res) => {
      const url = new URL(
        req.url || '/',
        `http://localhost:${VEVRIA_HTTP_PORT}`,
      );
      const pathname = url.pathname;

      try {
        // POST /message — receive a message from the Vevria backend
        if (req.method === 'POST' && pathname === '/message') {
          // Verify internal API key
          if (VEVRIA_INTERNAL_KEY) {
            const providedKey = req.headers['x-internal-key'];
            if (providedKey !== VEVRIA_INTERNAL_KEY) {
              jsonResponse(res, 401, { error: 'Unauthorized: invalid or missing x-internal-key' });
              return;
            }
          }

          const raw = await readBody(req);
          let body: Record<string, unknown>;
          try {
            body = JSON.parse(raw);
          } catch {
            jsonResponse(res, 400, { error: 'Invalid JSON' });
            return;
          }

          const content = typeof body.content === 'string' ? body.content : '';
          const senderName =
            typeof body.sender_name === 'string'
              ? body.sender_name
              : 'vevria-user';
          const senderId =
            typeof body.sender_id === 'string' ? body.sender_id : 'user';
          const chatJid =
            typeof body.chat_jid === 'string'
              ? body.chat_jid
              : `vevria:${VEVRIA_COMPANY_ID}`;

          if (!content) {
            jsonResponse(res, 400, { error: 'Missing "content" field' });
            return;
          }

          const message: NewMessage = {
            id: typeof body.id === 'string' ? body.id : randomUUID(),
            chat_jid: chatJid,
            sender: senderId,
            sender_name: senderName,
            content,
            timestamp: new Date().toISOString(),
            is_from_me: false,
            is_bot_message: false,
          };

          // Notify the channel registry of this chat
          this.onChatMetadata(
            chatJid,
            message.timestamp,
            senderName,
            'vevria-http',
            false,
          );

          // Deliver the message to the agent
          this.onMessage(chatJid, message);

          jsonResponse(res, 200, { ok: true, message_id: message.id });
          return;
        }

        // GET /status — health check
        if (req.method === 'GET' && pathname === '/status') {
          jsonResponse(res, 200, {
            status: 'running',
            agent_id: VEVRIA_AGENT_ID,
            company_id: VEVRIA_COMPANY_ID,
            connected: this.connected,
            uptime_s: Math.floor(process.uptime()),
          });
          return;
        }

        // POST /stop — graceful shutdown
        if (req.method === 'POST' && pathname === '/stop') {
          jsonResponse(res, 200, { ok: true, message: 'Shutting down' });
          // Disconnect after response is sent
          setImmediate(() => this.disconnect());
          return;
        }

        // 404 for everything else
        jsonResponse(res, 404, { error: 'Not found' });
      } catch (err) {
        console.error('[vevria-http] Request handler error:', err);
        jsonResponse(res, 500, { error: 'Internal server error' });
      }
    });

    await new Promise<void>((resolve, reject) => {
      this.server!.once('error', reject);
      this.server!.listen(VEVRIA_HTTP_PORT, () => {
        console.log(
          `[vevria-http] Listening on port ${VEVRIA_HTTP_PORT} (agent=${VEVRIA_AGENT_ID}, company=${VEVRIA_COMPANY_ID})`,
        );
        resolve();
      });
    });

    this.connected = true;
  }

  async sendMessage(jid: string, text: string): Promise<void> {
    if (!VEVRIA_CALLBACK_URL) {
      console.warn(
        '[vevria-http] No VEVRIA_CALLBACK_URL set, cannot send response',
      );
      return;
    }

    try {
      const resp = await fetch(VEVRIA_CALLBACK_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(VEVRIA_INTERNAL_KEY ? { 'x-internal-key': VEVRIA_INTERNAL_KEY } : {}),
        },
        body: JSON.stringify({
          agent_id: VEVRIA_AGENT_ID,
          company_id: VEVRIA_COMPANY_ID,
          chat_jid: jid,
          content: text,
        }),
      });

      if (!resp.ok) {
        console.error(
          `[vevria-http] Callback returned ${resp.status}: ${await resp.text()}`,
        );
      }
    } catch (err) {
      console.error('[vevria-http] Failed to send callback:', err);
    }
  }

  isConnected(): boolean {
    return this.connected;
  }

  ownsJid(jid: string): boolean {
    return jid.startsWith('vevria:');
  }

  async disconnect(): Promise<void> {
    if (this.server) {
      await new Promise<void>((resolve) => {
        this.server!.close(() => resolve());
      });
      this.server = null;
    }
    this.connected = false;
    console.log('[vevria-http] Disconnected');
  }
}

// Self-register — only activate when Vevria env vars are configured
registerChannel('vevria-http', (opts) => {
  if (!VEVRIA_CALLBACK_URL && !VEVRIA_AGENT_ID) return null;
  return new VevriaHttpChannel(opts);
});
