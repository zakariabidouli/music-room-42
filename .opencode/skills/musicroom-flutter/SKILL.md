---
name: musicroom-flutter
description: Flutter remote-control client with configurable backend URL and device logging
---

## What I do
- Screens: Auth, Profile, Vote queue, Playlist editor, Settings(backendUrl).
- `appConfig.backendUrl` editable in Settings, persisted locally.
- Every API call sends `X-Platform, X-Device, X-App-Version` headers.
- Deezer search UI uses backend proxy, never API key in app.

## When to use me
All mobile work in `mobile/`.
