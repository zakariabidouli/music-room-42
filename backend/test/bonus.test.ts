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

  it('VI.4 sync delta returns versions', async () => {
    const app = buildApp();
    const r = await app.inject({ method: 'GET', url: '/api/v1/sync/delta?since=2020-01-01T00:00:00.000Z', headers: H('u') }).then(x => x.json());
    expect(Array.isArray(r.playlists)).toBe(true);
  });
});
