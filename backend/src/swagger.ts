import { buildApp } from './app.js';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';

// Subject V.4: canonical Swagger codegen entry point (backend/src/swagger.ts -> docs/openapi.json).
// Fastify codegen alone emits 0 paths (no per-route schemas), so we MERGE the generated
// base with the hand-maintained contract (docs/openapi.json) instead of wiping it.
// Run via `npm run swagger` / `make swagger`. Idempotent: generated keys win, hand keys preserved.
const outUrl = new URL('../../docs/openapi.json', import.meta.url);
const app = buildApp();
await app.ready();
const generated = app.swagger() as any;
let hand: any = { paths: {} };
try {
  if (existsSync(outUrl)) hand = JSON.parse(readFileSync(outUrl, 'utf8'));
} catch {
  hand = { paths: {} };
}
const merged = {
  ...generated,
  ...hand,
  info: generated.info ?? hand.info,
  paths: { ...(hand.paths ?? {}), ...(generated.paths ?? {}) },
};
writeFileSync(outUrl, JSON.stringify(merged, null, 2));
console.log(`docs/openapi.json written (${Object.keys(merged.paths).length} paths, merge-safe)`);
await app.close();
