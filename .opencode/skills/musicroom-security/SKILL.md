---
name: musicroom-security
description: Authz isolation, rate limits, session protection, secrets hygiene
---

## What I do
- RLS/authz checks per row, 403 on cross-user access.
- Rate-limit login/vote (e.g. 100 req/15min), lockout + audit log.
- Secure JWT (short expiry + refresh rotation), detect session theft.
- ActionLog every mobile action: platform, device, appVersion, userId, action, timestamp.
- Enforce `.env` ignored, scan for leaked keys before commit.

## When to use me
Security review, logs, authz, pre-commit check.
