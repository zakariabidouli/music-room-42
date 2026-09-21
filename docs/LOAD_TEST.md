# LOAD_TEST (k6 not installed locally — scripts ready, backend verified via vitest concurrency tests)
- Server (dev): Apple Silicon darwin, Node 22, local Fastify. Prod target: 1x low-end VPS (2 vCPU / 4GB RAM) -> thousands concurrent per subject guidance.
- Scenarios: `docs/k6-vote.js` (50 VUs vote race, p95<500ms, err<5%), `docs/k6-playlist.js` (20 VUs reorder, p95<500ms).
- How to run: `npm i -g k6` (or Docker) then `make load` / `k6 run -e BASE_URL=http://localhost:3000 docs/k6-vote.js`.
- Backend concurrency proof (vitest, 2026-09-21): 5/5 green — duplicate vote -> 409, ranking correct, geofence 403, stale reorder 409, ActionLog headers present.
- Results table (fill after k6 run on prod-like host):
| Scenario | VUs | p95 | Errors |
|----------|-----|-----|--------|
| vote | 50 | TBD | TBD |
| playlist-reorder | 20 | TBD | TBD |
