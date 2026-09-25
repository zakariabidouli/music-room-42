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

## Frontend aesthetics (mandatory for all mobile/UI work)
Distilled from https://platform.claude.com/cookbook/coding-prompting-for-frontend-aesthetics (tricks only — their HTML scripts do not apply; we build Flutter). Avoid the generic "AI slop" look on every screen:
- Typography: pick one distinctive font pairing and use it decisively (display + mono, or serif + geometric sans; extremes like 200 vs 800, size jumps 3x+). Never ship Arial / Inter / Roboto / default system fonts as the whole design. State the font choice before coding.
- Color & theme: commit to ONE cohesive aesthetic via `mobile/lib/ui/theme.dart` (`ThemeData` + `darkTheme`, CSS-variable equivalent). Dominant color + one sharp accent beats timid evenly-distributed palettes. Draw from IDE themes / cultural aesthetics for inspiration. Never default to purple-gradient-on-white.
- Motion: one well-orchestrated moment beats scattered micro-interactions — e.g. staggered list reveals on first paint (`animation-delay` equivalent), animated queue rank changes, bottom-sheet transitions. Keep realtime socket refresh jank-free; prefer Flutter implicit animations over heavy custom tickers.
- Backgrounds: create atmosphere and depth, never flat solid defaults — layered gradients, geometric patterns, or contextual artwork (e.g. blurred `coverUrl` art behind queue/playlist headers) matching the theme.
- Layout: no cookie-cutter `ListTile`-only screens. Reuse `mobile/lib/ui/widgets.dart` (`TrackTile`, `CoverArt`, `EmptyState`, `AppSearchBar`, `SectionHeader`) so every screen feels like one designed app with context-specific character. Vary light/dark; do not converge on the same safe defaults every time.
