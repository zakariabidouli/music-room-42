---
name: musicroom-loadtest
description: k6 load scenarios for vote and playlist with server specs reporting
---

## What I do
- Write k6 scripts `docs/k6-vote.js`, `docs/k6-playlist.js`: ramp VUs, assert p95 < 500ms.
- Document server specs (CPU/RAM/cloud|premise) in `docs/LOAD_TEST.md`.
- Target: low-end server = thousands concurrent; justify choice.

## When to use me
Ramp-up evaluation, perf work.
