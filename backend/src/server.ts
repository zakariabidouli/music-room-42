import { buildApp, attachSocket } from './app.js';
import { Server } from 'socket.io';

const app = buildApp();
const port = Number(process.env.PORT ?? 3000);
const io = new Server(app.server, { cors: { origin: '*' } });
attachSocket(io);
await app.ready();
await app.listen({ port, host: '0.0.0.0' });
console.log(`Music Room API on :${port}, docs at /api/docs`);
