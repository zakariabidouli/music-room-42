# LOAD_TEST (V.7 — subject: justify + measure simultaneous users)
- Server (dev): Apple Silicon darwin, Node 22, local Fastify. Prod target: 1x low-end VPS (2 vCPU / 4GB RAM) -> thousands concurrent per subject guidance.
- Scenarios (real API, not /health stubs):
  - `docs/k6-vote.js` (50 VUs, 30s): setup 1 public event + suggestion, VUs vote as unique users + `GET /events/nearby`; asserts vote 200, thresholds `p95<500ms err<5%`.
  - `docs/k6-playlist.js` (20 VUs, 30s): setup 1 playlist + 2 tracks, VUs read-then-reorder (200|409 under race) + stale `version:1` must 409; thresholds `p95<500ms err<10%`.
- How to run: `npm i -g k6` then `make load` (or `k6 run -e BASE_URL=http://localhost:3001 docs/k6-vote.js` + playlist). Docker API is `:3001`, local dev `:3000`.
- Backend concurrency proof (vitest, must stay green before k6):
  - duplicate vote -> 409 + recount correct; geofence 403; invited-only 403->200 after invite; stale reorder 409; ActionLog headers present.
  - Run: `make test` (backend vitest 14 + mobile `flutter test` when SDK present).
- Results table (fill after k6 run on prod-like host; example run 2026-09-29 local Fastify, no DB):
| Scenario | VUs | p95 | Errors | Verdict |
|----------|-----|-----|--------|---------|
| vote race (unique voters) | 50 | <500ms expected | <5% expected | run `make load` then paste |
| playlist-reorder race | 20 | <500ms expected | <10% expected | run `make load` then paste |
> Note: vitest concurrency tests are the source of truth in CI (k6 needs a prod-like host + installed binary). Paste real numbers before defense — TBD rows fail V.7.
