import { describe, it, expect } from 'vitest';
import { buildApp } from '../src/app.js';

const H = (uid = 'u1') => ({ 'x-user-id': uid, 'x-platform': 'android', 'x-device': 'Pixel', 'x-app-version': '1.0.0' });

describe('Phase 1: API foundation', () => {
  it('health + profile + swagger-shaped errors', async () => {
    const app = buildApp();
    const h = await app.inject({ method: 'GET', url: '/health' });
    expect(h.statusCode).toBe(200);
    const unauth = await app.inject({ method: 'GET', url: '/api/v1/profile' });
    expect(unauth.statusCode).toBe(401);
    const p = await app.inject({ method: 'PUT', url: '/api/v1/profile', headers: H(), payload: { visibility: 'private' } });
    expect(p.statusCode).toBe(200);
  });
});

describe('Phase 3: Vote concurrency + licenses', () => {
  it('one vote per user, ranking, invited-only enforced', async () => {
    const app = buildApp();
    const ev = (await app.inject({ method: 'POST', url: '/api/v1/events', headers: H('owner'), payload: { title: 'Party', license: 'invited-only' } }).then(r => r.json()));
    const sg = (await app.inject({ method: 'POST', url: `/api/v1/events/${ev.id}/suggest`, headers: H('owner'), payload: { deezerTrackId: '1', title: 'T', artist: 'A' } }).then(r => r.json()));
    const forbidden = await app.inject({ method: 'POST', url: `/api/v1/suggestions/${sg.id}/vote`, headers: H('stranger') });
    expect(forbidden.statusCode).toBe(403);
    // invite then vote twice concurrently
    const { db } = await import('../src/lib.js');
    db.invites.push({ userId: 'v1', eventId: ev.id });
    const [a, b] = await Promise.all([
      app.inject({ method: 'POST', url: `/api/v1/suggestions/${sg.id}/vote`, headers: H('v1') }),
      app.inject({ method: 'POST', url: `/api/v1/suggestions/${sg.id}/vote`, headers: H('v1') }),
    ]);
    expect([a.statusCode, b.statusCode].sort()).toEqual([200, 409]);
    const queue = (await app.inject({ method: 'GET', url: `/api/v1/events/${ev.id}/queue` }).then(r => r.json()));
    expect(queue[0].votesCount).toBe(1);
  });

  it('geofenced event rejects outside box', async () => {
    const app = buildApp();
    const now = new Date();
    const ev = (await app.inject({ method: 'POST', url: '/api/v1/events', headers: H('o2'), payload: { title: 'G', license: 'geofenced', lat: 48.85, lon: 2.35, radiusM: 200, startAt: new Date(now.getTime() - 3600e3).toISOString(), endAt: new Date(now.getTime() + 3600e3).toISOString() } }).then(r => r.json()));
    const sg = (await app.inject({ method: 'POST', url: `/api/v1/events/${ev.id}/suggest`, headers: H('o2'), payload: { deezerTrackId: '9', title: 'T', artist: 'A' } }).then(r => r.json()));
    const far = await app.inject({ method: 'POST', url: `/api/v1/suggestions/${sg.id}/vote?lat=0&lon=0`, headers: H('o2') });
    expect(far.statusCode).toBe(403);
  });
});

describe('Phase 4: Playlist versioned reorder', () => {
  it('stale version -> 409, correct reorder bumps version', async () => {
    const app = buildApp();
    const pl = (await app.inject({ method: 'POST', url: '/api/v1/playlists', headers: H('owner'), payload: { title: 'Mix' } }).then(r => r.json()));
    const t1 = (await app.inject({ method: 'POST', url: `/api/v1/playlists/${pl.id}/tracks`, headers: H('owner'), payload: { deezerTrackId: '1', title: 'A', artist: 'x' } }).then(r => r.json()));
    const t2 = (await app.inject({ method: 'POST', url: `/api/v1/playlists/${pl.id}/tracks`, headers: H('owner'), payload: { deezerTrackId: '2', title: 'B', artist: 'x' } }).then(r => r.json()));
    const cur = (await app.inject({ method: 'GET', url: `/api/v1/playlists/${pl.id}` }).then(r => r.json()));
    const ok = await app.inject({ method: 'PATCH', url: `/api/v1/playlists/${pl.id}/reorder`, headers: H('owner'), payload: { orderedIds: [t2.id, t1.id], version: cur.version } });
    expect(ok.statusCode).toBe(200);
    const stale = await app.inject({ method: 'PATCH', url: `/api/v1/playlists/${pl.id}/reorder`, headers: H('owner'), payload: { orderedIds: [t1.id, t2.id], version: cur.version } });
    expect(stale.statusCode).toBe(409);
  });
});

describe('Phase 5: ActionLog', () => {
  it('every request logged with platform/device/version', async () => {
    const app = buildApp();
    const { db } = await import('../src/lib.js');
    db.logs.length = 0;
    await app.inject({ method: 'GET', url: '/health', headers: H() });
    expect(db.logs.length).toBe(1);
    expect(db.logs[0]).toMatchObject({ platform: 'android', device: 'Pixel', appVersion: '1.0.0' });
  });
});
