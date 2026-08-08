---
xid: EPI-ENEMIES-ENEMY-ATTACKS
parent: ../design.md
kind: epic
effort: enemies
status: shipped
date: 2026-08-07
bd-id: delve-8h1
shipped: 2026-08-07
---

# Enemies fight back

## Summary

Enemies chase you and then do nothing. `enemy.gd` says so out loud:

```gdscript
# Enemies only chase — they do not deal damage.
```

So there is no danger anywhere in delve. You have health, healing, a
guard and a dodge roll, and nothing has ever needed them. This epic
gives enemies a way to actually hurt you, which is what makes every
defensive thing already in the game mean something.

It also unlocks a rule from EPI-ENEMIES-ENEMY-LIMBS: "one arm = less
damage, both arms = no damage" only makes sense once there is damage
to reduce.

## Definition of Done

- [x] An enemy close enough to a player can hurt it (12 damage).
- [x] There is a wind-up you can see coming, so a hit is avoidable
      rather than unfair (0.55 s, feet planted).
- [x] Blocking works (3.0 vs 12.0) and dodge-rolling works (no damage
      at all) — neither had ever been tested against a real attacker.
- [x] An attack cannot land through a wall.
- [x] Proven by a headless test (9 checks).

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 011 | enemy-attack | M | the first real threat in the game |

## Out of scope

- Ranged or special attacks — melee only for now.
- Enemies attacking each other.
