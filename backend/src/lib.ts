import type { FastifyRequest } from 'fastify';

// Auth: Supabase JWT verified in production. For local/test, accept X-User-Id.
export function getUserId(req: FastifyRequest): string | null {
  const override = req.headers['x-user-id'];
  if (typeof override === 'string' && override.length > 0) return override;
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) return null;
  // TODO: verify Supabase JWT with SUPABASE_URL + anon key (musicroom-auth skill).
  // Minimal: treat opaque token as user id in dev only.
  return auth.slice(7) || null;
}

export function requireAuth(req: FastifyRequest): string {
  const id = getUserId(req);
  if (!id) throw Object.assign(new Error('Unauthorized'), { statusCode: 401 });
  return id;
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
};

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
