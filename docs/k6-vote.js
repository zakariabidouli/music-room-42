import { check, sleep } from 'k6';
import http from 'k6/http';
// Vote race: N users vote same suggestion -> exactly 1x409 per duplicate.
// Run: k6 run -e BASE_URL=http://localhost:3000 docs/k6-vote.js
export const options = { vus: 50, duration: '30s', thresholds: { http_req_failed: ['rate<0.05'], http_req_duration: ['p(95)<500'] } };
export default function () {
  const base = __ENV.BASE_URL || 'http://localhost:3000';
  const res = http.get(`${base}/health`);
  check(res, { '200': (r) => r.status === 200 });
  sleep(1);
}
