import { describe, it, expect, vi, afterEach } from 'vitest';
import { buildApp } from '../src/app.js';

const H = (uid = 'u1') => ({ 'x-user-id': uid, 'x-platform': 'android', 'x-device': 'Pixel', 'x-app-version': '1.0.0' });

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('Reliability: add-track validation + coverUrl', () => {
  it('empty title -> 400 (not 500), coverUrl round-trips', async () => {
    const app = buildApp();
    const pl = (await app.inject({ method: 'POST', url: '/api/v1/playlists', headers: H('owner'), payload: { title: 'Mix' } }).then(r => r.json()));
    const bad = await app.inject({ method: 'POST', url: `/api/v1/playlists/${pl.id}/tracks`, headers: H('owner'), payload: { deezerTrackId: '1', title: '', artist: 'x' } });
    expect(bad.statusCode).toBe(400);
    expect(bad.json().error.code).toBe(400);
    const ok = (await app.inject({ method: 'POST', url: `/api/v1/playlists/${pl.id}/tracks`, headers: H('owner'), payload: { deezerTrackId: '7', title: 'Song', artist: 'Band', previewUrl: 'https://p', coverUrl: 'https://c' } }).then(r => r.json()));
    expect(ok.coverUrl).toBe('https://c');
    const got = (await app.inject({ method: 'GET', url: `/api/v1/playlists/${pl.id}` }).then(r => r.json()));
    expect(got.tracks[0].coverUrl).toBe('https://c');
  });
});

describe('Reliability: private visibility enforced on playlists + queue', () => {
  it('private playlist hidden from strangers, writable only by invited', async () => {
    const app = buildApp();
    const pl = (await app.inject({ method: 'POST', url: '/api/v1/playlists', headers: H('owner'), payload: { title: 'Secret', visibility: 'private', license: 'open' } }).then(r => r.json()));
    const hidden = await app.inject({ method: 'GET', url: `/api/v1/playlists/${pl.id}`, headers: H('stranger') });
    expect(hidden.statusCode).toBe(403);
    const deniedWrite = await app.inject({ method: 'POST', url: `/api/v1/playlists/${pl.id}/tracks`, headers: H('stranger'), payload: { deezerTrackId: '1', title: 'A', artist: 'x' } });
    expect(deniedWrite.statusCode).toBe(403);
    const listed = (await app.inject({ method: 'GET', url: '/api/v1/playlists', headers: H('stranger') }).then(r => r.json())) as any[];
    expect(listed.find((p: any) => p.id === pl.id)).toBeUndefined();
    const { db } = await import('../src/lib.js');
    db.invites.push({ userId: 'guest', playlistId: pl.id });
    const ok = await app.inject({ method: 'POST', url: `/api/v1/playlists/${pl.id}/tracks`, headers: H('guest'), payload: { deezerTrackId: '1', title: 'A', artist: 'x' } });
    expect(ok.statusCode).toBe(200);
  });

  it('private event queue hidden from strangers', async () => {
    const app = buildApp();
    const ev = (await app.inject({ method: 'POST', url: '/api/v1/events', headers: H('owner'), payload: { title: 'Secret', visibility: 'private' } }).then(r => r.json()));
    const q = await app.inject({ method: 'GET', url: `/api/v1/events/${ev.id}/queue`, headers: H('stranger') });
    expect(q.statusCode).toBe(403);
  });
});

describe('Reliability: chart proxy shape (mocked fetch)', () => {
  it('returns deezer metadata shape without doing vote work', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      json: async () => ({ data: [{ id: 123, title: 'Hit', artist: { name: 'Star' }, preview: 'https://pv', album: { cover_medium: 'https://cv' } }] }),
    }) as any));
    const app = buildApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/music/chart', headers: H('u1') });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual([{ deezerTrackId: '123', title: 'Hit', artist: 'Star', previewUrl: 'https://pv', coverUrl: 'https://cv' }]);
  });
});
