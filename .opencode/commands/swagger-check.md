---
description: Verify Swagger matches implementation
agent: build
---

Regenerate Swagger (`make swagger`), diff `docs/openapi.json`. Fail if routes undocumented or stale. Every endpoint must have inputs/outputs documented.
