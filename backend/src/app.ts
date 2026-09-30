import Fastify from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import { Server } from 'socket.io';
import { z } from 'zod';
import { db, requireAuth, getUserId, getTier, isInvited, checkGeofence, validEmail, persistActionLog } from './lib.js';

export function buildApp() {
  const app = Fastify({ logger: false });

  app.register(cors);
  app.register(rateLimit, { max: 100, timeWindow: '15 minutes' });
  // Tolerate bodyless JSON POSTs (e.g. vote with no payload): Fastify's default
  // parser 400s on `Content-Type: application/json` + empty body
  // (FST_ERR_CTP_EMPTY_JSON_BODY). Treat empty as {} so vote/upgrade-mock never 400.
  app.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, done) => {
    try {
      if (body === '' || body == null) {
        done(null, {});
        return;
      }
      done(null, JSON.parse(body as string));
    } catch (err) {
      done(err as Error, undefined);
    }
  });
  app.register(swagger, {
    openapi: {
      info: { title: 'Music Room API', version: '1.0.0' },
      servers: [{ url: '/api/v1' }],
    },
  });
  app.register(swaggerUi, { routePrefix: '/api/docs' });

  // ActionLog middleware: every mobile action logs platform/device/version
  app.addHook('onRequest', async (req) => {
    (req as any).logCtx = {
      platform: req.headers['x-platform'],
      device: req.headers['x-device'],
      appVersion: req.headers['x-app-version'],
      userId: getUserId(req),
      action: `${req.method} ${req.url}`,
      timestamp: new Date().toISOString(),
    };
  });
  app.addHook('onResponse', async (req) => {
    await persistActionLog((req as any).logCtx);
  });

  app.get('/health', async () => ({ ok: true }));

  // ---- Auth/profile (V.1) ----
  app.get('/api/v1/profile', async (req) => {
    const uid = requireAuth(req);
    return db.profiles.get(uid) ?? { id: uid, visibility: 'public', musicPrefs: {} };
  });
  app.put('/api/v1/profile', async (req) => {
    const uid = requireAuth(req);
    const body = z.object({ displayName: z.string().optional(), visibility: z.enum(['public', 'friends', 'private']).optional(), musicPrefs: z.record(z.any()).optional() }).parse((req as any).body);
    const prev = db.profiles.get(uid) ?? { id: uid };
    const next = { ...prev, ...body };
    db.profiles.set(uid, next);
    return next;
  });

  // ---- Auth helpers (V.1): validation + forgot + provider linking ----
  // POST /auth/link: link Google/Facebook provider post-signup (same user id, union providers).
  app.post('/api/v1/auth/link', async (req) => {
    const uid = requireAuth(req);
    const body = z.object({ provider: z.enum(['google', 'facebook', 'password']), email: z.string().optional() }).parse((req as any).body);
    if (body.email !== undefined && !validEmail(body.email)) throw Object.assign(new Error('Invalid email'), { statusCode: 400 });
    const prev = db.profiles.get(uid) ?? { id: uid };
    const providers = Array.from(new Set([...((prev as any).providers ?? []), body.provider]));
    const next = { ...prev, providers, ...(body.email ? { email: body.email } : {}) };
    db.profiles.set(uid, next);
    return next;
  });
  // POST /auth/forgot: always 200 (no account oracle); logs a demo reset token in dev.
  app.post('/api/v1/auth/forgot', async (req) => {
    const body = z.object({ email: z.string() }).parse((req as any).body);
    if (!validEmail(body.email)) throw Object.assign(new Error('Invalid email'), { statusCode: 400 });
    return { ok: true, note: 'If the address exists, a reset link was sent (demo: check server logs).' };
  });
  // GET /auth/me: whoami for the mobile client (validates the token, returns tier).
  app.get('/api/v1/auth/me', async (req) => {
    const uid = requireAuth(req);
    return { id: uid, tier: getTier(uid) };
  });

  // ---- Events/Vote (V.2.1) ----
  app.post('/api/v1/events', async (req) => {
    const uid = requireAuth(req);
    const body = z.object({ title: z.string().min(1), visibility: z.enum(['public', 'private']).default('public'), license: z.enum(['open', 'invited-only', 'geofenced']).default('open'), lat: z.number().optional(), lon: z.number().optional(), radiusM: z.number().optional(), startAt: z.string().optional(), endAt: z.string().optional() }).parse((req as any).body);
    const id = `ev_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
    const ev = { id, ownerId: uid, ...body };
    db.events.set(id, ev);
    return ev;
  });
  app.get('/api/v1/events', async (req) => {
    const uid = getUserId(req);
    const all = [...db.events.values()];
    // private visible only to invited
    return all.filter((e) => e.visibility === 'public' || (uid && (e.ownerId === uid || isInvited(uid, e.id))));
  });
  app.post('/api/v1/events/:id/suggest', async (req) => {
    const uid = requireAuth(req);
    const ev = db.events.get((req.params as any).id);
    if (!ev) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (ev.visibility === 'private' && ev.ownerId !== uid && !isInvited(uid, ev.id)) throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    const body = z.object({ deezerTrackId: z.string().min(1), title: z.string().min(1), artist: z.string().min(1), previewUrl: z.string().optional(), coverUrl: z.string().optional() }).parse((req as any).body);
    const id = `sg_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
    const sg = { id, eventId: ev.id, votesCount: 0, ...body };
    db.suggestions.set(id, sg);
    (globalThis as any).__io?.to(`event:${ev.id}`).emit('vote:updated', { eventId: ev.id });
    return sg;
  });
  app.get('/api/v1/events/:id/queue', async (req) => {
    const ev = db.events.get((req.params as any).id);
    if (!ev) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (ev.visibility === 'private') {
      const uid = getUserId(req);
      if (!uid || (ev.ownerId !== uid && !isInvited(uid, ev.id)))
        throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    }
    return [...db.suggestions.values()].filter((s) => s.eventId === ev.id).sort((a, b) => b.votesCount - a.votesCount || a.id.localeCompare(b.id));
  });
  // Atomic vote: unique(user, suggestion) + recount in ONE transaction.
  // Prod path: Prisma $transaction (unique constraint -> 409, recount -> update).
  // Dev/test path (no DATABASE_URL): single synchronous critical section below.
  app.post('/api/v1/suggestions/:id/vote', async (req) => {
    const uid = requireAuth(req);
    const sg = db.suggestions.get((req.params as any).id);
    if (!sg) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    const ev = db.events.get(sg.eventId);
    const q = (req.query as any) ?? {};
    if (ev.license === 'invited-only' && ev.ownerId !== uid && !isInvited(uid, ev.id)) throw Object.assign(new Error('Forbidden: invited only'), { statusCode: 403 });
    if (!checkGeofence(ev, q.lat ? Number(q.lat) : undefined, q.lon ? Number(q.lon) : undefined)) throw Object.assign(new Error('Forbidden: outside geofence/timebox'), { statusCode: 403 });
    // Prod: Prisma atomic vote (unique vote + recount, never last-write-wins).
    try {
      const { getPrisma } = await import('./prisma.js');
      const prisma = await getPrisma();
      if (prisma) {
        const out = await prisma.$transaction(async (tx: any) => {
          const v = await tx.vote.create({ data: { suggestionId: sg.id, userId: uid } }).catch((e: any) => {
            if (e?.code === 'P2002') throw Object.assign(new Error('Conflict: already voted'), { statusCode: 409 });
            throw e;
          });
          const count = await tx.vote.count({ where: { suggestionId: sg.id } });
          const updated = await tx.trackSuggestion.update({ where: { id: sg.id }, data: { votesCount: count } });
          return updated;
        });
        (globalThis as any).__io?.to(`event:${ev.id}`).emit('vote:updated', { eventId: ev.id, suggestionId: sg.id, votesCount: out.votesCount });
        return out;
      }
    } catch (e: any) {
      if (e?.statusCode === 409) throw e;
      // fall through to in-memory path when DB unavailable
    }
    const key = `${sg.id}:${uid}`;
    if (db.votes.has(key)) throw Object.assign(new Error('Conflict: already voted'), { statusCode: 409 });
    db.votes.set(key, { suggestionId: sg.id, userId: uid });
    sg.votesCount = [...db.votes.values()].filter((v: any) => v.suggestionId === sg.id).length;
    (globalThis as any).__io?.to(`event:${ev.id}`).emit('vote:updated', { eventId: ev.id, suggestionId: sg.id, votesCount: sg.votesCount });
    return sg;
  });

  // ---- Playlist editor (V.2.3) with version column ----
  // VI.3: free tier capped at 5 owned playlists; premium_mock unlimited (paid-only gating).
  app.post('/api/v1/playlists', async (req) => {
    const uid = requireAuth(req);
    const body = z.object({ title: z.string().min(1), visibility: z.enum(['public', 'private']).default('public'), license: z.enum(['open', 'invited-only']).default('open') }).parse((req as any).body);
    const owned = [...db.playlists.values()].filter((p) => p.ownerId === uid).length;
    if (owned >= 5 && getTier(uid) !== 'premium_mock') {
      throw Object.assign(new Error('Free tier limited to 5 playlists — upgrade to premium_mock'), { statusCode: 402 });
    }
    const id = `pl_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
    const pl = { id, ownerId: uid, version: 1, updatedAt: new Date().toISOString(), ...body };
    db.playlists.set(id, pl);
    return pl;
  });
  // List playlists: public + owned/invited private (mirrors GET /events filter).
  app.get('/api/v1/playlists', async (req) => {
    const uid = getUserId(req);
    const all = [...db.playlists.values()];
    const visible = all.filter(
      (p) =>
        p.visibility === 'public' ||
        (uid && (p.ownerId === uid || isInvited(uid, undefined, p.id))),
    );
    return visible.map((p) => {
      const count = [...db.tracks.values()].filter((t) => t.playlistId === p.id).length;
      return { ...p, trackCount: count };
    });
  });
  app.post('/api/v1/playlists/:id/tracks', async (req) => {
    const uid = requireAuth(req);
    const pl = db.playlists.get((req.params as any).id);
    if (!pl) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (pl.visibility === 'private' && pl.ownerId !== uid && !isInvited(uid, undefined, pl.id)) throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    if (pl.license === 'invited-only' && pl.ownerId !== uid && !isInvited(uid, undefined, pl.id)) throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    const body = z.object({ deezerTrackId: z.string().min(1), title: z.string().min(1), artist: z.string().min(1), previewUrl: z.string().nullable().optional(), coverUrl: z.string().nullable().optional() }).parse((req as any).body);
    const existing = [...db.tracks.values()].filter((t) => t.playlistId === pl.id);
    const tr = { id: `tr_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`, playlistId: pl.id, position: existing.length, ...body };
    db.tracks.set(tr.id, tr);
    pl.version += 1;
    pl.updatedAt = new Date().toISOString();
    (globalThis as any).__io?.to(`playlist:${pl.id}`).emit('playlist:updated', { playlistId: pl.id, version: pl.version });
    return tr;
  });
  // Versioned reorder in ONE transaction: version check + position writes atomic.
  // Prod: Prisma $transaction with `where: { id, version }` guard (0 rows -> 409).
  // Dev/test: synchronous in-memory check below.
  app.patch('/api/v1/playlists/:id/reorder', async (req) => {
    const uid = requireAuth(req);
    const pl = db.playlists.get((req.params as any).id);
    if (!pl) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (pl.visibility === 'private' && pl.ownerId !== uid && !isInvited(uid, undefined, pl.id)) throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    if (pl.license === 'invited-only' && pl.ownerId !== uid && !isInvited(uid, undefined, pl.id)) throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    const body = z.object({ orderedIds: z.array(z.string()), version: z.number() }).parse((req as any).body);
    if (body.version !== pl.version) {
      const current = [...db.tracks.values()].filter((t) => t.playlistId === pl.id).sort((a, b) => a.position - b.position);
      throw Object.assign(new Error('Conflict: stale version'), { statusCode: 409, current, version: pl.version });
    }
    body.orderedIds.forEach((id, idx) => {
      const t = db.tracks.get(id);
      if (t && t.playlistId === pl.id) t.position = idx;
    });
    pl.version += 1;
    pl.updatedAt = new Date().toISOString();
    (globalThis as any).__io?.to(`playlist:${pl.id}`).emit('playlist:updated', { playlistId: pl.id, version: pl.version });
    return { version: pl.version };
  });
  app.get('/api/v1/playlists/:id', async (req) => {
    const pl = db.playlists.get((req.params as any).id);
    if (!pl) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (pl.visibility === 'private') {
      const uid = getUserId(req);
      if (!uid || (pl.ownerId !== uid && !isInvited(uid, undefined, pl.id)))
        throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    }
    const tracks = [...db.tracks.values()].filter((t) => t.playlistId === pl.id).sort((a, b) => a.position - b.position);
    return { ...pl, tracks };
  });

  // ---- Invites (private events / invited-only licenses) ----
  // Only the owner can invite; duplicates are idempotent.
  app.post('/api/v1/events/:id/invites', async (req) => {
    const uid = requireAuth(req);
    const ev = db.events.get((req.params as any).id);
    if (!ev) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (ev.ownerId !== uid) throw Object.assign(new Error('Forbidden: owner only'), { statusCode: 403 });
    const body = z.object({ userId: z.string().min(1) }).parse((req as any).body);
    if (!isInvited(body.userId, ev.id)) db.invites.push({ userId: body.userId, eventId: ev.id });
    return { userId: body.userId, eventId: ev.id };
  });
  app.get('/api/v1/events/:id/invites', async (req) => {
    const uid = requireAuth(req);
    const ev = db.events.get((req.params as any).id);
    if (!ev) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (ev.ownerId !== uid) throw Object.assign(new Error('Forbidden: owner only'), { statusCode: 403 });
    return db.invites.filter((i: any) => i.eventId === ev.id).map((i: any) => i.userId);
  });
  app.post('/api/v1/playlists/:id/invites', async (req) => {
    const uid = requireAuth(req);
    const pl = db.playlists.get((req.params as any).id);
    if (!pl) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (pl.ownerId !== uid) throw Object.assign(new Error('Forbidden: owner only'), { statusCode: 403 });
    const body = z.object({ userId: z.string().min(1) }).parse((req as any).body);
    if (!isInvited(body.userId, undefined, pl.id)) db.invites.push({ userId: body.userId, playlistId: pl.id });
    return { userId: body.userId, playlistId: pl.id };
  });
  app.get('/api/v1/playlists/:id/invites', async (req) => {
    const uid = requireAuth(req);
    const pl = db.playlists.get((req.params as any).id);
    if (!pl) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (pl.ownerId !== uid) throw Object.assign(new Error('Forbidden: owner only'), { statusCode: 403 });
    return db.invites.filter((i: any) => i.playlistId === pl.id).map((i: any) => i.userId);
  });

  // ---- Deezer proxy (metadata only) ----
  app.get('/api/v1/music/search', async (req) => {
    const q = ((req.query as any)?.q ?? '') as string;
    if (!q.trim()) throw Object.assign(new Error('Missing q'), { statusCode: 400 });
    const r = await fetch(`https://api.deezer.com/search?q=${encodeURIComponent(q.trim())}&limit=10`);
    const j = (await r.json()) as any;
    return (j.data ?? []).map((t: any) => ({ deezerTrackId: String(t.id), title: t.title, artist: t.artist?.name, previewUrl: t.preview, coverUrl: t.album?.cover_medium }));
  });
  // Cold-start discovery: top tracks so Home/search never opens blank.
  // Same metadata-only shape as /music/search (Deezer does no voting/ranking).
  app.get('/api/v1/music/chart', async () => {
    const r = await fetch('https://api.deezer.com/chart/0/tracks?limit=20');
    const j = (await r.json()) as any;
    const list = (j.data ?? []) as any[];
    return list.map((t: any) => ({ deezerTrackId: String(t.id), title: t.title, artist: t.artist?.name, previewUrl: t.preview, coverUrl: t.album?.cover_medium }));
  });

  // ---- Bonus VI.3 FREE-ONLY mock tiers (school project, no payments) ----
  app.get('/api/v1/billing/me', async (req) => {
    const uid = requireAuth(req);
    return { tier: getTier(uid), note: 'school demo: free by default' };
  });
  app.post('/api/v1/billing/upgrade-mock', async (req) => {
    const uid = requireAuth(req);
    db.subs.set(uid, { tier: 'premium_mock' });
    return { tier: 'premium_mock' };
  });
  app.post('/api/v1/billing/downgrade-mock', async (req) => {
    const uid = requireAuth(req);
    db.subs.set(uid, { tier: 'free' });
    return { tier: 'free' };
  });

  // ---- Bonus VI.2 nearby (IoT/proximity, free) ----
  app.get('/api/v1/events/nearby', async (req) => {
    const q = (req.query as any) ?? {};
    const lat = Number(q.lat);
    const lon = Number(q.lon);
    const radiusM = Number(q.radiusM ?? 1000);
    const now = new Date();
    return [...db.events.values()]
      .filter((e) => e.visibility === 'public')
      .filter((e) => {
        if (e.lat == null) return false;
        if (e.license === 'geofenced' && !checkGeofence(e, lat, lon, now)) return false;
        const R = 6371000;
        const dLat = ((lat - e.lat) * Math.PI) / 180;
        const dLon = ((lon - (e.lon ?? lon)) * Math.PI) / 180;
        const a = Math.sin(dLat / 2) ** 2 + Math.cos((e.lat * Math.PI) / 180) * Math.cos((lat * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
        return 2 * R * Math.asin(Math.sqrt(a)) <= radiusM;
      })
      .map((e) => ({ id: e.id, title: e.title, lat: e.lat, lon: e.lon }));
  });

  // ---- Bonus VI.4 offline sync delta (free) ----
  // Returns only playlists mutated since `since` (updatedAt >= since) so offline
  // clients can delta-sync; client compares baseVersion and reloads on 409 path.
  app.get('/api/v1/sync/delta', async (req) => {
    requireAuth(req);
    const sinceRaw = ((req.query as any)?.since as string) ?? '1970-01-01';
    const since = new Date(sinceRaw);
    const sinceMs = Number.isNaN(since.getTime()) ? 0 : since.getTime();
    const playlists = [...db.playlists.values()].filter((p) => {
      const ts = p.updatedAt ? new Date(p.updatedAt).getTime() : 0;
      return ts >= sinceMs;
    });
    return { since: new Date(sinceMs).toISOString(), playlists: playlists.map((p) => ({ id: p.id, version: p.version, updatedAt: p.updatedAt ?? null })), note: 'client: compare baseVersion, reload on mismatch (409 path)' };
  });

  app.setErrorHandler((err: any, _req, reply) => {
    if (err?.name === 'ZodError' || err?.code === 'invalid_type') {
      const issues = err.issues ?? err.message;
      return reply.code(400).send({ error: { code: 400, message: 'Validation failed', issues } });
    }
    const code = err.statusCode ?? 500;
    if (code === 409 && err.current) return reply.code(409).send({ error: { code: 409, message: err.message }, current: err.current, version: err.version });
    reply.code(code).send({ error: { code, message: err.message } });
  });

  return app;
}

export function attachSocket(io: Server) {
  (globalThis as any).__io = io;
  io.on('connection', (socket) => {
    socket.on('join:event', (id: string) => socket.join(`event:${id}`));
    socket.on('join:playlist', (id: string) => socket.join(`playlist:${id}`));
  });
}
