# Music Room — Full Plan to Defense (Vote + Playlist Editor, Deezer, Flutter + Fastify)

Source: `/Users/pc/Desktop/music.pdf` v6. Stack chosen: most-manageable.

## Phase 0 — Environment (DONE, verify with `ls -R`)
- [x] `opencode.json`, `AGENTS.md`, `.gitignore`, `.env.example`, `Makefile`
- [x] 8 skills, 4 agents, 5 commands
- [ ] Run `cp .env.example .env`, `cd backend && npm init + install fastify prisma socket.io`, `flutter create mobile`

## Phase 1 — Backend foundation
1. Prisma schema: User/Profile, Event, TrackSuggestion, Vote, Playlist, PlaylistTrack, Invite, ActionLog.
2. `backend/src/server.ts` + `swagger.ts` + auth middleware (Supabase JWT verify).
3. `GET /health`, `GET /api/docs` (Swagger UI), export `docs/openapi.json`.
4. Skill: `musicroom-api`. Command: `/swagger-check`.

## Phase 2 — Auth + Profile (subject V.1, V.5, V.6)
1. Supabase Auth: email validation + forgot + Google/Facebook; link endpoint `POST /api/v1/auth/link`.
2. Profile CRUD with visibility levels + music prefs. RLS/authz tests.
3. Flutter: login/signup/link/profile screens. Skill: `musicroom-auth` + `musicroom-flutter`.

## Phase 3 — Vote service (V.2.1)
1. Endpoints: `POST /events`, `POST /events/:id/suggest` (Deezer lookup), `POST /suggestions/:id/vote`, `GET /events/:id/queue` (ranked).
2. Licenses: open | invited-only | geofenced+timeboxed (check lat/lon+now server-side).
3. Concurrency: `$transaction`, unique vote, re-rank, socket `event:{id}` broadcast.
4. Flutter vote queue UI + suggest + vote buttons. Skill: `musicroom-vote`. Command: `/vote-sim`.

## Phase 4 — Playlist Editor (V.2.3)
1. Endpoints: `POST /playlists`, `POST /playlists/:id/tracks`, `PATCH /playlists/:id/reorder {orderedIds, version}`, `POST /playlists/:id/invites`.
2. Reorder transaction with version check (409 on stale). Socket `playlist:{id}`.
3. Flutter editor with drag-reorder + version conflict dialog. Skill: `musicroom-playlist`.

## Phase 5 — Securing + Logs (V.6, V.8)
1. Rate-limit, helmet, short JWT + refresh rotation, 403 tests for cross-user reads.
2. `ActionLog` middleware: every request stores platform/device/appVersion/userId/action/timestamp.
3. Audit: `@security-auditor`, ensure no `.env` in git. Skill: `musicroom-security`.

## Phase 6 — Deezer integration (constraint: SDK must not do our work)
1. Backend proxy `GET /api/v1/music/search?q=` -> Deezer API, cache result. Only metadata (title/artist/preview/cover).
2. Flutter calls backend, never Deezer directly. No voting/ranking in SDK.

## Phase 7 — Ramp-up + CI (V.7, V.8)
1. `docs/k6-vote.js` + `docs/k6-playlist.js`, run `make load`, fill `docs/LOAD_TEST.md` with CPU/RAM + p95.
2. Tests per layer (`make test` green), GH Actions workflow.
3. Skills: `musicroom-loadtest`, `musicroom-ci`. Commands: `/api-test`, `/load-run`.

## Phase 8 — Defense prep (Ch VII)
1. `/defense-prep`: demo public event vote, private invite-only, geofenced vote, concurrent reorder conflict, backendUrl switch in app Settings, live Swagger, ActionLog query.
2. Fill `docs/AI_USAGE.md` + `docs/ARCH_DECISIONS.md` (why Fastify/Flutter/REST/JSON/Supabase/Deezer).
3. Bonus only if mandatory perfect — do NOT start bonus before Phase 7 green.

## Exit criteria
- `make test` green, `make swagger` fresh, `make load` results logged, no secrets in git, `docs/openapi.json` + `LOAD_TEST.md` + `AI_USAGE.md` complete.
