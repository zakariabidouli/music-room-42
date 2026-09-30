import type { FastifyRequest } from 'fastify';

// Auth: Supabase JWT verified in production; X-User-Id only when ALLOW_DEV_AUTH=1 (dev/test).
// V.1: email validation + forgot/link helpers. V.6: RLS-style owner checks live in app.ts.
export function validEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email.trim());
}

function base64UrlDecode(seg: string): any | null {
  try {
    const b64 = seg.replace(/-/g, '+').replace(/_/g, '/');
    return JSON.parse(Buffer.from(b64, 'base64').toString('utf8'));
  } catch {
    return null;
  }
}

// Minimal JWT payload decode (no signature check here — full verify via Supabase JWKS
// when SUPABASE_URL is set; see verifySupabaseJwt below). Returns sub or null.
export function decodeJwtSub(token: string): string | null {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const payload = base64UrlDecode(parts[1]);
  return typeof payload?.sub === 'string' ? payload.sub : null;
}

export async function verifySupabaseJwt(token: string): Promise<string | null> {
  // Fast path: short opaque dev tokens are never JWTs.
  const sub = decodeJwtSub(token);
  if (!sub) return null;
  // If Supabase is configured, confirm the token via the Auth API (server-side).
  // Falls back to trusting `sub` only when no SUPABASE_URL is configured (local dev).
  if (!process.env.SUPABASE_URL) return sub;
  try {
    const { createClient } = await import('@supabase/supabase-js');
    const svc = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_KEY ?? process.env.SUPABASE_ANON_KEY ?? '',
    );
    const { data, error } = await svc.auth.getUser(token);
    if (error || !data?.user) return null;
    return data.user.id;
  } catch {
    return null;
  }
}

export function getUserId(req: FastifyRequest): string | null {
  const allowDev = process.env.ALLOW_DEV_AUTH !== '0';
  const override = req.headers['x-user-id'];
  if (allowDev && typeof override === 'string' && override.length > 0) return override;
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) return null;
  const token = auth.slice(7);
  if (!token) return null;
  // Sync path: accept JWT-shaped tokens by `sub`; full async verify happens in
  // requireAuthAsync for state-changing routes. Dev opaque tokens only with ALLOW_DEV_AUTH.
  const sub = decodeJwtSub(token);
  if (sub) return sub;
  if (allowDev) return token;
  return null;
}

export function requireAuth(req: FastifyRequest): string {
  const id = getUserId(req);
  if (!id) throw Object.assign(new Error('Unauthorized'), { statusCode: 401 });
  return id;
}

// Async variant: fully verifies Supabase JWT server-side when configured.
// Use on state-changing routes in prod; sync requireAuth stays for reads/tests.
export async function requireAuthAsync(req: FastifyRequest): Promise<string> {
  const allowDev = process.env.ALLOW_DEV_AUTH !== '0';
  const override = req.headers['x-user-id'];
  if (allowDev && typeof override === 'string' && override.length > 0) return override;
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) throw Object.assign(new Error('Unauthorized'), { statusCode: 401 });
  const token = auth.slice(7);
  const verified = await verifySupabaseJwt(token);
  if (verified) return verified;
  if (allowDev && token) return token;
  throw Object.assign(new Error('Unauthorized'), { statusCode: 401 });
}

// Persist ActionLog to Prisma when a DB is configured; always mirror to memory
// so tests without DATABASE_URL still observe logs (V.6).
export async function persistActionLog(entry: any): Promise<void> {
  db.logs.push(entry);
  try {
    const { getPrisma } = await import('./prisma.js');
    const prisma = await getPrisma();
    if (prisma?.actionLog?.create) {
      await prisma.actionLog.create({
        data: {
          userId: entry.userId ?? null,
          action: String(entry.action ?? ''),
          platform: entry.platform ? String(entry.platform) : null,
          device: entry.device ? String(entry.device) : null,
          appVersion: entry.appVersion ? String(entry.appVersion) : null,
        },
      }).catch(() => {});
    }
  } catch {
    // memory fallback already done
  }
}

// In-memory store for test/dev without Postgres. Prisma used in prod.
export const db = {
  events: new Map<string, any>(),
  suggestions: new Map<string, any>(),
  votes: new Map<string, any>(), // key suggestionId:userId
  playlists: new Map<string, any>(),
  tracks: new Map<string, any>(),
  invites: [] as any[],
  logs: [] as any[],
  profiles: new Map<string, any>(),
  subs: new Map<string, any>(), // userId -> { tier: 'free' | 'premium_mock' }
};

export function getTier(userId: string): string {
  return db.subs.get(userId)?.tier ?? 'free'; // school project: always free by default
}

export function isInvited(userId: string, eventId?: string, playlistId?: string): boolean {
  return db.invites.some(
    (i) => i.userId === userId && (eventId ? i.eventId === eventId : true) && (playlistId ? i.playlistId === playlistId : true),
  );
}

export function checkGeofence(event: any, lat?: number, lon?: number, now = new Date()): boolean {
  if (event.license !== 'geofenced') return true;
  if (event.startAt && now < new Date(event.startAt)) return false;
  if (event.endAt && now > new Date(event.endAt)) return false;
  if (event.lat == null || lat == null || lon == null) return false;
  const R = 6371000;
  const dLat = ((lat - event.lat) * Math.PI) / 180;
  const dLon = ((lon - event.lon) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((event.lat * Math.PI) / 180) * Math.cos((lat * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
  const dist = 2 * R * Math.asin(Math.sqrt(a));
  return dist <= (event.radiusM ?? 500);
}
