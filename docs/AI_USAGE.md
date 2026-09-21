# AI_USAGE — transparency log (mandatory per subject Ch II)
| Date | What AI generated | Reviewed by | Edge cases adjusted |
|------|-------------------|-------------|---------------------|
| 2026-09-21 | Scaffold opencode.json/skills/agents/commands + PLAN | you | skill names match dirs, permissions |
| 2026-09-21 | Backend Fastify app.ts/lib.ts/server.ts + vitest phases (auth/vote/geofence/playlist-version/ActionLog) | you | fixed @fastify/* v10/v9 for Fastify 5; vote critical section documented as Prisma $transaction in prod |
| 2026-09-21 | Flutter api.dart/config.dart/main.dart (backendUrl + headers) + openapi.json + k6 scripts + CI | you | verify backendUrl switch in Settings; 409 conflict dialogs |
