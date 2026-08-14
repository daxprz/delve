# Where we're up to

Last updated 2026-08-14. Everything below is committed and pushed.

---

## 🎮 Try these next time you play

Restart Play first — a running game keeps the old code.

1. **The giant spider.** Towers over you on three-jointed X-shaped
   legs, and every step it takes is different. It crawls; feet plant
   and push rather than sliding.
2. **The Runner's claws** — `LMB` / `RMB`. Damage is **100% momentum**:
   0.10 standing, 0.25 walking, 0.50 sprinting, **1.00 dashing**. You
   have to keep moving to hurt anything.
3. **Double-tap `W`** to dash.
4. **The Grabber's piston** — `F` locks the arms together, hold both
   mouse buttons to charge, release to launch. Enemies ragdoll;
   **players keep control**, so you can fire a Runner across the map.
5. **The Grabber's hands** — five fingers that wrap what you pick up
   and keep hold as you move.

---

## 🔨 Asked for, written down, NOT built

| # | what |
|---|---|
| **STO-CHARACTER-068** | the piston as a real extending shaft you can stand on — *"we'll work on this later"* |
| **STO-COMBAT-004** | a thrown object hurts what it hits — **the shared impact rule the rest need** |
| **STO-COMBAT-005** | smashing a held enemy into a wall hurts it |
| **STO-COMBAT-006** | hitting an enemy with an enemy hurts both |
| **STO-COMBAT-007** | `E` crushes the body part you are holding |
| **a boss** | you asked for one; it is an entry in the enemy registry now |

---

## 🧩 Unfinished, with the reason written down

- **STO-ENEMIES-024 — wall climbing.** It works: the spider detects a
  wall and climbs y 1.0 -> 3.3. Then it **stalls** partway up and I do
  not know why. Only the spider climbs, and that IS asserted.
- **STO-CHARACTER-067 — the piston in multiplayer is unverified.** The
  RPC is written; no two-instance test exists. That is the half most
  likely to be wrong.
- **STO-ENEMIES-023** — without foot IK the spider's feet rise and fall
  slightly across a stride.

---

## 🛠️ Jobs for me, not you

- **STO-TOOLS-009** — ~21 tests still cannot run while you have the
  game open, because they need port 7777. This already bit us once:
  **two tests failed in v0.1.9 and nobody knew**, because they never
  ran.
- `smoke_limb_effects` fails only under suite load; passes 3/3 alone.

---

## ✅ Shipped since v0.1.11

Enemy kinds registry · the giant spider (X legs, unique steps,
partial climbing) · the Runner's dash and momentum claws · the
Grabber's piston · procedural fingers that wrap and grip · the
spider ragdoll crash fix.

**Not released yet** — v0.1.11 is still the newest build. A release
would need the version bumped in `project.godot` first; CI fails the
build if it disagrees with the tag.
