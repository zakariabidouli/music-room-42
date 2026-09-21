# ARCH_DECISIONS (fill as you build — needed for defense justification)
- Backend Fastify over NestJS: lighter, faster, Swagger plugin simple.
- REST+JSON over GraphQL/gRPC: 42 subject requires REST justification, tooling + mobile simplicity.
- Supabase Postgres+Auth: manages email validation/forgot/OAuth, RLS for isolation.
- Socket.io rooms: simple realtime for vote/playlist, backend stays truth.
- Flutter: one codebase Android+iOS+web-responsive bonus path.
- Deezer over Spotify: free search+preview, no Premium blocker.
- Prisma transactions: atomic vote rank + versioned reorder.
