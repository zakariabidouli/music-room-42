import { check, sleep } from 'k6';
import http from 'k6/http';
// Playlist reorder race (V.2.3 + V.7): versioned reorder, stale version must 409, never silent overwrite.
// Run: k6 run -e BASE_URL=http://localhost:3001 docs/k6-playlist.js
export const options = { vus: 20, duration: '30s', thresholds: { http_req_failed: ['rate<0.1'], http_req_duration: ['p(95)<500'] } };
export function setup() {
  const base = __ENV.BASE_URL || 'http://localhost:3000';
  const owner = `k6pl_${Date.now()}`;
  const h = { 'Content-Type': 'application/json', 'X-User-Id': owner };
  const pl = http.post(`${base}/api/v1/playlists`, JSON.stringify({ title: 'k6 mix' }), { headers: h }).json();
  const t1 = http.post(`${base}/api/v1/playlists/${pl.id}/tracks`, JSON.stringify({ deezerTrackId: '1', title: 'A', artist: 'x' }), { headers: h }).json();
  const t2 = http.post(`${base}/api/v1/playlists/${pl.id}/tracks`, JSON.stringify({ deezerTrackId: '2', title: 'B', artist: 'x' }), { headers: h }).json();
  const cur = http.get(`${base}/api/v1/playlists/${pl.id}`, { headers: h }).json();
  return { base, owner, playlistId: pl.id, t1: t1.id, t2: t2.id, version: cur.version };
}
export default function (data) {
  const h = { 'Content-Type': 'application/json', 'X-User-Id': data.owner };
  // Fresh read then reorder (may 200 or 409 under race — both valid, 500+ never valid).
  const cur = http.get(`${data.base}/api/v1/playlists/${data.playlistId}`, { headers: h }).json();
  const res = http.patch(`${data.base}/api/v1/playlists/${data.playlistId}/reorder`, JSON.stringify({ orderedIds: [data.t2, data.t1], version: cur.version }), { headers: h });
  check(res, { 'reorder 200|409': (r) => r.status === 200 || r.status === 409 });
  // Stale write must always 409.
  const stale = http.patch(`${data.base}/api/v1/playlists/${data.playlistId}/reorder`, JSON.stringify({ orderedIds: [data.t1, data.t2], version: 1 }), { headers: h });
  check(stale, { 'stale 409': (r) => r.status === 409 });
  sleep(0.5);
}
