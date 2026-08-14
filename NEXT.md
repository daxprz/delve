# Where we're up to

Last updated 2026-08-13. Everything below is committed and pushed.

---

## 🎮 Try these next time you play

Restart Play first — a running game keeps the old code.

1. **The Grabber's hands.** Five fingers now. Pick something up with
   `RMB` and watch them close around it.
2. **The tail.** Turned down twice; ~6 solid hits to kill instead of 2.
   **Is that right, or still wrong?** Story 052 can't close until you
   say.
3. **Throwing.** Grab a crate — it should sit out in front where you
   can aim. **Easier now?** Story 055 needs your yes.
4. **Enemies fight back.** They rear back before swinging, so you can
   step away. There is no block or dodge any more — footwork only.
5. **Limbs come off.** Shoot an enemy in the head with the Sniper.

---

## 🔨 Waiting on a decision from you

**What should the new enemy kinds DO?** Some ideas, but yours are
better:

- a fast weak one that rushes you
- a big slow tough one that hits hard
- one that hangs back and darts in
- one that splits in two when you hit it

Plus **a boss** — you already said you want one.

The plan: build an **enemy registry** first (a list of enemy kinds,
like `CharacterDB` is for players). Then each new enemy is a small
story instead of a rewrite, and the boss is just another entry in the
list. That is why the registry comes first.

---

## 🧩 One thing left unfinished

**STO-CHARACTER-062** — fingers wrap around things, but a **big crate
and a small block still close the fingers the same amount**. The test
`smoke_finger_grip` is deliberately left FAILING rather than loosened,
because that check is the whole point of the story.

Everything else about the hands works.

---

## ✅ Done recently

| what | story |
|---|---|
| Player names, remembered between sessions | STO-UI-006 |
| Version watermark, top-right corner | STO-UI-007 |
| App bundles report the real version | STO-TOOLS-010 |
| Enemies attack you | STO-ENEMIES-011 |
| Limbs can be torn off | STO-ENEMIES-012 |
| Head off = instant death | STO-ENEMIES-013 |
| One leg = limp, both = dead | STO-ENEMIES-014 |
| One arm = weak, both = harmless | STO-ENEMIES-015 |
| Dead bodies stay | STO-ENEMIES-016 |
| Tail hits softer | STO-CHARACTER-052 |
| Things held out in front | STO-CHARACTER-054 |
| RMB picks up and holds out | STO-CHARACTER-055 |
| C and G do nothing | STO-CHARACTER-056 |
| Five procedural fingers | STO-CHARACTER-057 |
| Fingers bend like real fingers | STO-CHARACTER-058 |
| Fingers wrap / fist clenches | STO-CHARACTER-059 / 060 |
| Thicker, simpler fingers | STO-CHARACTER-061 |

**Released:** v0.1.11 is the latest build on GitHub.
Everyone playing together must be on the **same version** — the number
in the top-right corner tells you which.

---

## 🛠️ Jobs for me, not you

- **STO-TOOLS-009** — 22 tests still can't run while you have the game
  open, because they need port 7777. This already bit us: **two tests
  were failing in v0.1.9 and nobody knew**, because they never ran.
- **STO-CORE-007 / STO-ENEMIES-012** — both had bugs that hid for
  months behind tests that measured the wrong thing. Worth remembering
  the pattern.
