---
xid: EPI-ENEMIES-ENEMY-ATTACKS
parent: ../design.md
kind: epic
effort: enemies
status: open
date: 2026-08-07
bd-id: delve-8h1
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

- [ ] An enemy close enough to a player can hurt it.
- [ ] There is a wind-up you can see coming, so a hit is avoidable
      rather than unfair.
- [ ] Blocking and dodge-rolling work against it (they already exist
      and have never been tested against a real attacker).
- [ ] An attack cannot land through a wall.
- [ ] Proven by a headless test.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 011 | enemy-attack | M | the first real threat in the game |

## Out of scope

- Ranged or special attacks — melee only for now.
- Enemies attacking each other.
