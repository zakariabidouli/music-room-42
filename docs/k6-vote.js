import { check, sleep } from 'k6';
import http from 'k6/http';
// Vote race (V.2.1 + V.7): setup one public event + suggestion, then N VUs vote.
// Atomic backend must keep votesCount == #unique voters; duplicates -> 409.
// Run: k6 run -e BASE_URL=http://localhost:3001 docs/k6-vote.js
export const options = { vus: 50, duration: '30s', thresholds: { http_req_failed: ['rate<0.05'], http_req_duration: ['p(95)<500'] } };
export function setup() {
  const base = __ENV.BASE_URL || 'http://localhost:3000';
  const owner = `k6owner_${__VU}_${Date.now()}`;
  const ev = http.post(`${base}/api/v1/events`, JSON.stringify({ title: 'k6 vote race', visibility: 'public', license: 'open' }), { headers: { 'Content-Type': 'application/json', 'X-User-Id': owner } });
  const evId = ev.json().id;
  const sg = http.post(`${base}/api/v1/events/${evId}/suggest`, JSON.stringify({ deezerTrackId: 'k61337', title: 'k6 track', artist: 'k6' }), { headers: { 'Content-Type': 'application/json', 'X-User-Id': owner } });
  return { base, suggestionId: sg.json().id };
}
export default function (data) {
  const voter = `k6voter_${__VU}_${__ITER}`;
  const res = http.post(`${data.base}/api/v1/suggestions/${data.suggestionId}/vote`, null, { headers: { 'X-User-Id': voter } });
  check(res, { 'vote 200': (r) => r.status === 200 });
  const q = http.get(`${data.base}/api/v1/events/nearby?lat=48.85&lon=2.35&radiusM=100000`);
  check(q, { 'nearby 200': (r) => r.status === 200 });
  sleep(0.5);
}
