---
name: musicroom-playlist
description: Realtime multi-user playlist editor with versioned reorder and invite control
---

## What I do
- Models: Playlist, PlaylistTrack(position), Invite. Visibility public/private, license open/invited-only.
- Reorder: transaction with `version` column, optimistic concurrency — reject stale version with 409.
- Realtime: Socket.io `playlist:{id}` rooms, patch broadcast.

## When to use me
Playlist CRUD, reorder, invites, realtime collab.

## Rules
- Never last-write-wins silently; return conflict + current order.
- Validate editor permission per license before mutate.
- Re-normalize positions (0..n) inside transaction.
