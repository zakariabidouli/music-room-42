import Fastify from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import { Server } from 'socket.io';
import { z } from 'zod';
import { db, requireAuth, getUserId, isInvited, checkGeofence } from './lib.js';

export function buildApp() {
  const app = Fastify({ logger: false });

  app.register(cors);
  app.register(rateLimit, { max: 100, timeWindow: '15 minutes' });
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
    db.logs.push((req as any).logCtx);
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

  // ---- Events/Vote (V.2.1) ----
  app.post('/api/v1/events', async (req) => {
    const uid = requireAuth(req);
    const body = z.object({ title: z.string(), visibility: z.enum(['public', 'private']).default('public'), license: z.enum(['open', 'invited-only', 'geofenced']).default('open'), lat: z.number().optional(), lon: z.number().optional(), radiusM: z.number().optional(), startAt: z.string().optional(), endAt: z.string().optional() }).parse((req as any).body);
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
    const body = z.object({ deezerTrackId: z.string(), title: z.string(), artist: z.string(), previewUrl: z.string().optional(), coverUrl: z.string().optional() }).parse((req as any).body);
    const id = `sg_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
    const sg = { id, eventId: ev.id, votesCount: 0, ...body };
    db.suggestions.set(id, sg);
    (globalThis as any).__io?.to(`event:${ev.id}`).emit('vote:updated', { eventId: ev.id });
    return sg;
  });
  app.get('/api/v1/events/:id/queue', async (req) => {
    const ev = db.events.get((req.params as any).id);
    if (!ev) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    return [...db.suggestions.values()].filter((s) => s.eventId === ev.id).sort((a, b) => b.votesCount - a.votesCount || a.id.localeCompare(b.id));
  });
  // Atomic vote: unique(user, suggestion) + recount inside single synchronous critical section (prod: Prisma $transaction)
  app.post('/api/v1/suggestions/:id/vote', async (req) => {
    const uid = requireAuth(req);
    const sg = db.suggestions.get((req.params as any).id);
    if (!sg) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    const ev = db.events.get(sg.eventId);
    const q = (req.query as any) ?? {};
    if (ev.license === 'invited-only' && ev.ownerId !== uid && !isInvited(uid, ev.id)) throw Object.assign(new Error('Forbidden: invited only'), { statusCode: 403 });
    if (!checkGeofence(ev, q.lat ? Number(q.lat) : undefined, q.lon ? Number(q.lon) : undefined)) throw Object.assign(new Error('Forbidden: outside geofence/timebox'), { statusCode: 403 });
    const key = `${sg.id}:${uid}`;
    if (db.votes.has(key)) throw Object.assign(new Error('Conflict: already voted'), { statusCode: 409 });
    db.votes.set(key, { suggestionId: sg.id, userId: uid });
    sg.votesCount = [...db.votes.values()].filter((v: any) => v.suggestionId === sg.id).length;
    (globalThis as any).__io?.to(`event:${ev.id}`).emit('vote:updated', { eventId: ev.id, suggestionId: sg.id, votesCount: sg.votesCount });
    return sg;
  });

  // ---- Playlist editor (V.2.3) with version column ----
  app.post('/api/v1/playlists', async (req) => {
    const uid = requireAuth(req);
    const body = z.object({ title: z.string(), visibility: z.enum(['public', 'private']).default('public'), license: z.enum(['open', 'invited-only']).default('open') }).parse((req as any).body);
    const id = `pl_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
    const pl = { id, ownerId: uid, version: 1, ...body };
    db.playlists.set(id, pl);
    return pl;
  });
  app.post('/api/v1/playlists/:id/tracks', async (req) => {
    const uid = requireAuth(req);
    const pl = db.playlists.get((req.params as any).id);
    if (!pl) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    if (pl.license === 'invited-only' && pl.ownerId !== uid && !isInvited(uid, undefined, pl.id)) throw Object.assign(new Error('Forbidden'), { statusCode: 403 });
    const body = z.object({ deezerTrackId: z.string(), title: z.string(), artist: z.string(), previewUrl: z.string().optional() }).parse((req as any).body);
    const existing = [...db.tracks.values()].filter((t) => t.playlistId === pl.id);
    const tr = { id: `tr_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`, playlistId: pl.id, position: existing.length, ...body };
    db.tracks.set(tr.id, tr);
    pl.version += 1;
    return tr;
  });
  app.patch('/api/v1/playlists/:id/reorder', async (req) => {
    const uid = requireAuth(req);
    const pl = db.playlists.get((req.params as any).id);
    if (!pl) throw Object.assign(new Error('Not found'), { statusCode: 404 });
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
    (globalThis as any).__io?.to(`playlist:${pl.id}`).emit('playlist:updated', { playlistId: pl.id, version: pl.version });
    return { version: pl.version };
  });
  app.get('/api/v1/playlists/:id', async (req) => {
    const pl = db.playlists.get((req.params as any).id);
    if (!pl) throw Object.assign(new Error('Not found'), { statusCode: 404 });
    const tracks = [...db.tracks.values()].filter((t) => t.playlistId === pl.id).sort((a, b) => a.position - b.position);
    return { ...pl, tracks };
  });

  // ---- Deezer proxy (metadata only) ----
  app.get('/api/v1/music/search', async (req) => {
    const q = ((req.query as any)?.q ?? '') as string;
    if (!q) throw Object.assign(new Error('Missing q'), { statusCode: 400 });
    const r = await fetch(`https://api.deezer.com/search?q=${encodeURIComponent(q)}&limit=10`);
    const j = (await r.json()) as any;
    return (j.data ?? []).map((t: any) => ({ deezerTrackId: String(t.id), title: t.title, artist: t.artist?.name, previewUrl: t.preview, coverUrl: t.album?.cover_medium }));
  });

  app.setErrorHandler((err: any, _req, reply) => {
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
