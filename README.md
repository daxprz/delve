# Delve

A 3D first-person multiplayer game built in **Godot 4.6** (Forward+).

Every character is a different *way of moving and fighting* — not a
different set of stats. A Grabber hauls itself around on mechanical
arms; a Runner pounces and sweeps with a physics tail; a Flyer carries
enemies into the sky; a Sniper is blind and sees the world by
listening to it.

Almost nothing here is hand-placed. Bodies, enemies, the maze and the
animation are **generated in code**, and the fighting runs on real
physics — enemies have jointed ragdolls whose mass, balance and
loudness all come from the body each one happened to be generated
with.

---

## Running it

```bash
godot --path .            # play
godot --editor --path .   # open in the editor
```

Then pick a character and press **Host**. To play together, launch a
second instance and press **Join** (localhost). You can also skip the
menu:

```bash
godot --path . -- --server     # window 1
godot --path . -- --client     # window 2
```

---

## Controls

| Input | Action |
|---|---|
| `WASD` | Move |
| `Mouse` | Look |
| `Space` | Jump *(Runner: **hold** to charge a pounce)* |
| `Shift` | Sprint |
| `Esc` | Pause (frees the mouse) |
| `F3` | Debug overlay |

**Grabber** — `LMB`/`RMB` grab with the left/right arm, `E` switches
to punch mode (hold a mouse button to ram; punches aim where you
look), `Q` grapple-zip, `G` throw, `F` pull, `C` guard/parry.

**Runner** — hold `Space` to pounce (15 s cooldown, *refunded if you
hit something*), `C` dodge roll, and a tail that damages and trips
what it hits at speed.

**Flyer** — hold `Space` to fly, `Shift` to dive-bomb, `LMB`+`RMB` to
snatch an enemy and carry it off.

**Sniper** — `LMB` fires the rifle, `RMB` sweeps a lidar scan. See
below.

---

## The Sniper

The Sniper is blind. Its screen renders nothing at all — no lighting,
no geometry. It has three ways of seeing, each a different trade:

| | Shows you | Costs you |
|---|---|---|
| **Hearing** (passive) | Anything that *moves* sends out a wave that lights the walls around it — never the creature itself | Nothing, but you can't choose when |
| **Lidar** (`RMB`) | A cone ahead of you that *holds* for a few seconds. Creatures come back **red** | 2.2 s cooldown |
| **Rifle** (`LMB`) | The bang floods the whole area with light — this is how you look around | It tells *everything* exactly where you are |

Heavier creatures are louder, so a big enemy announces itself from
much further away than a small one — and since mass comes from each
enemy's generated body, no two sound alike.

---

## What's generated, not authored

- **Bodies** — every character and enemy is a jointed humanoid built
  from code, with procedural walk animation (foot planting, 2-bone leg
  IK, arm swing). No keyframes.
- **Enemies** — each one's proportions, mass, centre of balance,
  stability and colour derive from a seed taken from its name, so
  every enemy is a distinct individual and every peer in multiplayer
  renders the same one.
- **Ragdolls** — built at the moment of impact from the enemy's live
  body pose: 11 rigid parts, cone-twist joints, mass distributed
  anatomically.
- **The map** — a randomised maze of rooms and doorways, plus an
  obstacle playground.
- **The Grabber's arms and Runner's tail** — Verlet chains simulated
  every frame, colliding with the world and with the player's own body.

Hits are momentum transfers (`Δv = impulse / mass`), so the same punch
launches a light enemy and barely rocks a heavy one. Reactions come in
tiers: a weak hit shoves, a medium one buckles a leg into a stumble,
and a hard one ragdolls.

---

## Testing (TUMU)

The game is built to be inspected without looking at the screen.

**RCON** — a TCP console into the running game:

```bash
scripts/rcon.sh status              # scene, peers, players, enemies, fps
scripts/rcon.sh players             # positions, health, character
scripts/rcon.sh spawn enemy 4 1 4
scripts/rcon.sh debug log enemy/ai  # stream a debug aspect
scripts/rcon.sh eval <expression>
```

A second instance falls back to port 10000, so host and client can
both be driven at once.

**Debug overlay** (`F3`) — every system registers *aspects* that can
be toggled independently for on-screen gizmos and text logging, per
observer. Gizmos include tail hit points and enemy hit-reaction
arrows.

**Smoke tests** — 49 headless tests:

```bash
godot --headless --path . -s res://tests/smoke_player.gd
scripts/run_mp_test.sh     # two-instance multiplayer test
```

Some need to host, so they can't run while a game is open on port
7777. `tests/smoke_world_collision.gd` sweeps every static body in the
built world and fails if a visible mesh has drifted off its collision
box — it has caught that exact regression twice.

---

## Layout

```
scenes/          main + player scenes
scripts/         gameplay; autoload/ holds rcon, debug overlay, network
tests/           headless smoke tests
effort/          the work tree: designs, epics, stories
```

`effort/` is worth a look if you want to know *why* something is the
way it is. Every feature was written down before it was built, and
each story records what shipped, what was measured, what broke on the
way, and — for the things that were tried and removed — why they went.
