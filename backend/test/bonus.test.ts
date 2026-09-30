import { describe, it, expect } from 'vitest';
import { buildApp } from '../src/app.js';

const H = (uid = 'u1') => ({ 'x-user-id': uid, 'x-platform': 'android', 'x-device': 'Pixel', 'x-app-version': '1.0.0' });

describe('Bonus (free-only school demo)', () => {
  it('VI.3 billing mock: free by default, upgrade-mock toggles', async () => {
    const app = buildApp();
    const me1 = await app.inject({ method: 'GET', url: '/api/v1/billing/me', headers: H('free1') }).then(r => r.json());
    expect(me1.tier).toBe('free');
    await app.inject({ method: 'POST', url: '/api/v1/billing/upgrade-mock', headers: H('free1') });
    const me2 = await app.inject({ method: 'GET', url: '/api/v1/billing/me', headers: H('free1') }).then(r => r.json());
    expect(me2.tier).toBe('premium_mock');
  });

  it('VI.2 nearby: inside radius sees event, far does not', async () => {
    const app = buildApp();
    await app.inject({ method: 'POST', url: '/api/v1/events', headers: H('o'), payload: { title: 'Near', visibility: 'public', license: 'open', lat: 48.85, lon: 2.35 } });
    const near = await app.inject({ method: 'GET', url: '/api/v1/events/nearby?lat=48.85&lon=2.35&radiusM=1000' }).then(r => r.json());
    expect(near.length).toBeGreaterThanOrEqual(1);
    const far = await app.inject({ method: 'GET', url: '/api/v1/events/nearby?lat=0&lon=0&radiusM=1000' }).then(r => r.json());
    expect(far.length).toBe(0);
  });

  it('VI.4 sync delta returns versions + filters by since', async () => {
    const app = buildApp();
    const r = await app.inject({ method: 'GET', url: '/api/v1/sync/delta?since=2020-01-01T00:00:00.000Z', headers: H('u') }).then(x => x.json());
    expect(Array.isArray(r.playlists)).toBe(true);
    const future = await app.inject({ method: 'GET', url: `/api/v1/sync/delta?since=${new Date(Date.now() + 3600e3).toISOString()}`, headers: H('u') }).then(x => x.json());
    expect(future.playlists).toEqual([]);
  });

  it('V.1 auth helpers: link validates email, forgot always 200, me returns tier', async () => {
    const app = buildApp();
    const bad = await app.inject({ method: 'POST', url: '/api/v1/auth/link', headers: H('link1'), payload: { provider: 'google', email: 'not-an-email' } });
    expect(bad.statusCode).toBe(400);
    const ok = await app.inject({ method: 'POST', url: '/api/v1/auth/link', headers: H('link1'), payload: { provider: 'google', email: 'a@b.co' } }).then(r => r.json());
    expect(ok.providers).toContain('google');
    const forgot = await app.inject({ method: 'POST', url: '/api/v1/auth/forgot', payload: { email: 'a@b.co' } });
    expect(forgot.statusCode).toBe(200);
    const me = await app.inject({ method: 'GET', url: '/api/v1/auth/me', headers: H('link1') }).then(r => r.json());
    expect(me.id).toBe('link1');
  });

  it('VI.3 free tier capped at 5 playlists, premium unlimited', async () => {
    const app = buildApp();
    for (let i = 0; i < 5; i++) {
      const r = await app.inject({ method: 'POST', url: '/api/v1/playlists', headers: H('cap1'), payload: { title: `M${i}` } });
      expect(r.statusCode).toBe(200);
    }
    const sixth = await app.inject({ method: 'POST', url: '/api/v1/playlists', headers: H('cap1'), payload: { title: 'M5' } });
    expect(sixth.statusCode).toBe(402);
    await app.inject({ method: 'POST', url: '/api/v1/billing/upgrade-mock', headers: H('cap1') });
    const after = await app.inject({ method: 'POST', url: '/api/v1/playlists', headers: H('cap1'), payload: { title: 'M5' } });
    expect(after.statusCode).toBe(200);
  });
});
