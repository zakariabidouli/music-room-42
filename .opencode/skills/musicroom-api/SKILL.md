---
name: musicroom-api
description: REST JSON API design with Fastify Swagger and validation
---

## What I do
- Define REST routes under `/api/v1`, JSON only, Zod validation.
- Generate Swagger from code (`backend/src/swagger.ts` -> `docs/openapi.json`).
- Standard errors `{error:{code,message}}`, pagination, auth via Bearer JWT.

## When to use me
Any backend endpoint, DTO, Swagger work.

## Rules
- Backend is source of truth; no business logic in mobile.
- Justify REST choice in `docs/ARCH_DECISIONS.md`.
