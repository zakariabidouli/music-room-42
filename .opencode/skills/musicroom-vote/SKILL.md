---
name: musicroom-vote
description: Live vote queue with visibility, licenses, atomic ranking and concurrency safety
---

## What I do
- Models: Event, TrackSuggestion, Vote. Re-rank by vote count atomically.
- Visibility: public (anyone finds/votes) / private (invited only).
- License: open | invited-only | geofenced+timeboxed (lat/lon + start/end).
- Concurrency: single transaction per vote, unique(userId,suggestionId), socket broadcast.

## When to use me
Any vote/event/queue/ranking work.

## Rules
- Use Prisma `$transaction` for vote insert + recount.
- Check geofence + timebox server-side, never trust client.
- Emit `vote:updated` on `event:{id}` room.
- Deezer only for track metadata (title/preview/cover).
