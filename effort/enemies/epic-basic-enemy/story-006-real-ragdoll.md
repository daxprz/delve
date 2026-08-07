---
xid: STO-ENEMIES-006
parent: ./epic.md
kind: story
effort: enemies
size: L
status: shipped
date: 2026-08-06
depends-on: []
bd-id: delve-swt
shipped: 2026-08-06
tasks: 6
complete: 6
---

# Real physics ragdoll (RigidBody parts + joints), no fake tumble

## Summary

The fake whole-body tumble (STO-ENEMIES-004) is replaced by a REAL
physics ragdoll (`scripts/ragdoll.gd`): on knockdown, an `EnemyRagdoll`
is procedurally generated from the enemy's live procedural Body — 11
RigidBody3D parts built at the body's current pose with its actual
segment sizes, shared material (damage flash still tints it) and
per-individual mass distribution — connected with cone-twist joints
(twist axis remapped to run along each bone). Momentum carries in:
parts inherit the enemy's velocity plus the hit dv; sweeps strike the
shins, blows strike torso/head, and the joint solver produces the
tumble. The enemy hides its Body, disables its capsule and follows
the pelvis; once the pelvis comes to rest it stands back up out of
the pose it landed in (brief upright blend). The dv-threshold /
mass / stability model from STO-ENEMIES-005 is unchanged.

## Definition of Done

- [x] Knockdowns spawn real RigidBody3D parts + joints (no scripted
      tumble left); procedural body hides during, restores after.
- [x] Physics is stable: no joint explosions; tumble angular
      velocities in single/double digits, brief contact spikes only.
- [x] Momentum conserved into the parts (launch = own velocity + dv;
      no double-counting of the hit).
- [x] Trips launch via the shins; body blows via torso/head.
- [x] Enemy recovers: ragdoll freed, capsule re-enabled, body upright,
      gait back on. Death/carry while ragdolled cleans up.
- [x] `tests/smoke_enemy_reactions.gd` passes headless (16 checks).

## Out of scope

- Ragdoll for players.
- Hinge-limited elbows/knees (cone-twist everywhere; good enough).
- Blended physical get-up (parts lerping to pose) — current get-up is
  a short visual blend from the landing orientation.

## Verification notes (2026-08-06)

- 16/16 PASS. Three real bugs found & fixed via a per-tick probe
  (tests/probe_ragdoll.gd, deleted after):
  1. part-vs-part contacts at spawn — parts now on layer 2, mask 1
     (world only);
  2. ConeTwistJoint twist axis is the joint's local X but limbs run
     along Y — joint frames remapped (x<--y, y<-x, z<-z) or the solver
     fights from frame one;
  3. hit dv was applied to enemy velocity AND the launch — parts flew
     at 25 m/s and sailed 103 m. Now dv goes only into the ragdoll.
- After fixes: launch ~13 m/s, tumble 5–20 rad/s (landing spike ~50),
  carry 11.5 m, max pelvis angular 21 rad/s (was 886).
- `smoke_enemy_body` regression PASS. Hosting regressions still queued
  behind the operator's play session (port 7777).
