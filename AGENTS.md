# AGENTS.md — Music Room rules (mandatory for all agents)

Source of truth: `/Users/pc/Desktop/music.pdf` (42 Music Room v6).
Scope: Vote + Playlist Editor (mandatory), Deezer API, Flutter + Fastify stack.

## Non-negotiable rules
1. Backend is source of truth. Mobile is remote-control only.
2. API is REST + JSON, documented with Swagger (`backend/src/swagger.ts` -> `docs/openapi.json`).
3. Backend base URL must be configurable in mobile app (`appConfig.backendUrl`).
4. No secrets in git. Use `.env` locally, commit only `.env.example`. Publicly stored credentials = project failure.
5. Every mobile action logs on backend: `platform, device, appVersion, userId, action, timestamp`.
6. Auth: email/password (validation + forgot) + Google + Facebook, linkable post-signup. RLS / authz isolation: user sees own data only.
7. Visibility: Public (anyone finds) / Private (invited only). License Vote: open | invited-only | geofenced+timeboxed. License Playlist: open | invited-only.
8. Concurrency: votes use atomic transaction + re-rank; playlist reorder uses transaction with version column. Never last-write-wins silently.
9. Deezer SDK must NOT do our work — only search/track/preview metadata. Voting/ranking/realtime is ours.
10. Tests per layer + `make test` green before commit. Load test via k6, results in `docs/LOAD_TEST.md`.
11. AI transparency: update `docs/AI_USAGE.md` for every AI-generated block (what, reviewed by whom, edge cases adjusted).
