---
xid: STO-ENEMIES-017
parent: ./epic.md
kind: story
effort: enemies
size: S
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-0an
---

# A registry of enemy kinds

## Summary

A list of enemy **kinds**, each with its own name, stats and body
shape — the same idea as `CharacterDB` for players.

Right now `enemy.gd` hard-codes one creature: 60 health, speed 3, a
humanoid body. A second kind would mean `if` statements threaded
through the AI, and a third would make that unreadable. A list makes
each new enemy an **entry** rather than an edit.

Kept deliberately small: this story adds the list and moves the
existing enemy into it as the first entry. Nothing should look or play
any different afterwards — that is how we know it worked.

## Definition of Done

- [x] `EnemyKinds.LIST` holds each kind with its stats and body.
- [x] The Walker is the first entry and plays exactly as before.
- [x] `kind` is a spawn-replicated property, so every peer builds the
      same creature rather than guessing.
- [x] Adding a kind needs no change to the AI — the Crawler shares it.
- [x] Proven by `tests/smoke_crawler.gd`.

## Out of scope

- Any new kind. That is 018 onward.
