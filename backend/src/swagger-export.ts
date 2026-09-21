import { buildApp } from './app.js';
import { writeFileSync } from 'node:fs';

const app = buildApp();
await app.ready();
writeFileSync(new URL('../../docs/openapi.json', import.meta.url), JSON.stringify(app.swagger(), null, 2));
console.log('docs/openapi.json written');
await app.close();
