# syntax=docker/dockerfile:1
# ---- Music Room backend (Fastify + socket.io) ----
# Multi-stage build: compile TypeScript in "builder", ship a slim runtime.
# Dev store is in-memory (backend/src/lib.ts); Postgres/Prisma is prod-only.

# ---------- Stage 1: build ----------
FROM node:22-alpine AS builder
WORKDIR /app

# Install deps first (better layer caching: package files rarely change).
COPY backend/package.json backend/package-lock.json ./
RUN npm ci

# Compile TypeScript -> dist/
COPY backend/tsconfig.json ./
COPY backend/src ./src
RUN npm run build

# Drop dev dependencies from node_modules for the runtime stage.
RUN npm prune --omit=dev

# ---------- Stage 2: runtime ----------
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

# Run as an unprivileged user.
RUN addgroup -S app && adduser -S app -G app

# Only the compiled output + production node_modules cross the stage boundary.
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY backend/package.json ./package.json

USER app
EXPOSE 3000

# BusyBox wget ships with alpine (no curl needed).
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=5 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1

CMD ["node", "dist/server.js"]