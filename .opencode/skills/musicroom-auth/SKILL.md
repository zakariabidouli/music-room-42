---
name: musicroom-auth
description: Supabase email/password + Google/Facebook auth, linking, validation, RLS isolation
---

## What I do
- Implement signup/login email+password with mail validation + forgot-password via Supabase Auth.
- Add Google + Facebook OAuth, link/unlink post-signup.
- Profile model: public / friends-only / private + music preferences.
- Enforce RLS: user reads only own private data.

## When to use me
Auth, profile, OAuth, RLS, session handling.

## Steps
1. Check `backend/prisma/schema.prisma` for User/Profile models.
2. Use Supabase Auth API, never store plaintext passwords.
3. Add rate-limit on login, revoke refresh tokens on logout.
4. Mobile: use flutter `supabase_flutter`, configurable `backendUrl`.
5. Update `docs/AI_USAGE.md` after generation.
