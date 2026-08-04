---
xid: EPI-CHARACTER-SPIDER-CHARACTER
parent: ../design.md
kind: epic
effort: character
status: shipped
date: 2026-08-03
bd-id: delve-ak5
shipped: 2026-08-03
---

# Spider: wall-climbing character

## Summary

A third character, the **Spider** — its own movement style: it **climbs
walls** (sticks to and crawls up/along them), with a leggy procedural
body. Rounds out the roster (Grabber = swing, Runner = speed, Spider =
climb).

> **REMOVED 2026-08-03.** The operator asked to get rid of the Spider
> crawler. All Spider code was reverted: the "spider" character def,
> `scripts/spider.gd`, the player's wall-climb movement, and
> `tests/smoke_spider.gd` were removed; the player builds the humanoid
> body for every character again. Stories 018/019 marked abandoned. The
> roster is back to Grabber + Runner. All other tests + MP still pass.

## Definition of Done

- [x] A Spider character you can pick, that climbs walls.
- [x] A leggy (non-humanoid) procedural body.

## Stories

| #   | Slug        | Size | Notes |
|-----|-------------|------|-------|
| 018 | wall-climb  | L    | Stick to a wall, crawl up/down/along, leap off. |
| 019 | spider-body | M    | Low central body + 8 splayed legs, fade shader. |
