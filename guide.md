# Guide — setup & run Music Room (school, always free)

Source spec: `/Users/pc/Desktop/music.pdf` (42 Music Room v6). Stack: Fastify + Prisma + Flutter + Deezer. No payments anywhere (VI.3 is a mock toggle).

## 1. Prereqs
- Node 22+, npm, git, Postgres 16 (local or Supabase). Optional: Flutter SDK (mobile UI), k6 (load test), Docker.
- Check: `node --version`, `psql --version`.

## 2. Setup
```sh
cd ~/Desktop/music_42
cp .env.example .env   # never commit .env
cd backend && npm install
# Prisma prod wiring (needs DATABASE_URL in .env):
# npx prisma migrate dev --name init
cd ..
```

## 3. Run backend
```sh
cd backend
npm run dev            # :3000, docs at http://localhost:3000/api/docs
curl localhost:3000/health   # {"ok":true}
```

## 4. Run tests / swagger / load
```sh
cd backend
npm test               # vitest: 5 mandatory + 3 bonus = 8 green
npm run swagger        # regenerates docs/openapi.json (hand-completed to 15 paths)
# k6 (install first: brew install k6 or npm i -g k6):
k6 run -e BASE_URL=http://localhost:3000 ../docs/k6-vote.js
k6 run -e BASE_URL=http://localhost:3000 ../docs/k6-playlist.js
```

## 5. Mobile (Flutter, remote-control only)
```sh
# install Flutter SDK first (not in this env)
flutter pub get        # inside mobile/
flutter run            # set backend URL in Settings screen first
```
Rules: `appConfig.backendUrl` editable; every call sends `X-Platform/X-Device/X-App-Version`; Deezer via backend `/music/search` only.

## 6. Demo script (defense)
1. Signup/login (email + Google/Facebook mock via `X-User-Id` locally, Supabase JWT in prod).
2. Create public event → suggest (Deezer) → vote from 2 users → ranked queue.
3. Private event + invite-only license → stranger gets 403.
4. Geofenced event → far coords get 403.
5. Playlist reorder with stale `version` → 409 + current order.
6. Bonus: `GET /billing/me` → free; `POST /billing/upgrade-mock` → premium_mock; `GET /events/nearby?lat&lon`; `GET /sync/delta?since=`; web responsive at 390px vs 1280px.
7. Show Swagger + ActionLog + `make test` green + `AI_USAGE.md`.

## 7. Notes / limits
- Dev auth accepts `X-User-Id` header; prod must verify Supabase JWT (`lib.ts` TODO).
- Dev store is in-memory; prod uses Prisma Postgres transactions for vote rank + versioned reorder.
- Always free: billing is a mock toggle, no Stripe/keys. Web/IoT/offline are minimal demo-grade (see `test/bonus.test.ts`).
