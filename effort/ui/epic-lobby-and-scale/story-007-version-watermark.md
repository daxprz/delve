---
xid: STO-UI-007
parent: ./epic.md
kind: story
effort: ui
size: S
status: draft
date: 2026-08-07
depends-on: []
bd-id: delve-6wm
---

# A version watermark in the top-right corner

## Summary

The game shows which version it is, small and out of the way, in the
**top-right corner** — on the menu, in the lobby and while playing.

This matters more than it looks. delve is handed round a network as
downloaded builds, and everyone has to be on the same one: there is no
protocol version check yet, so a mismatched client connects and then
behaves strangely rather than refusing. Right now the only way to tell
what someone is running is to ask them what they downloaded. A
watermark makes "are we all on the same build?" answerable at a
glance.

## The version has to be true, or it is worse than nothing

The game currently has no version at all. CI takes it from the git tag
(`GITHUB_REF_NAME#v`), which is why `manifest.json` is always right.

So the version goes in `project.godot` as `config/version` — and the
release workflow **checks it matches the tag and fails the build if it
does not**. A watermark that confidently displays a stale number is
worse than having none, because people would trust it.

## Definition of Done

- [x] The version shows in the top-right corner.
- [x] It is visible on the menu, in the lobby, and in game — it is an
      autoload on its own CanvasLayer, so there is one copy rather
      than three to keep in step.
- [x] It never blocks a click (`MOUSE_FILTER_IGNORE`).
- [x] It reads its number from `application/config/version`, not a
      string typed into the UI.
- [x] Releasing with a mismatched version **fails the build**.
- [x] It scales with the UI-size setting, via the window content
      scale like every other Control.
- [x] Proven by a headless test (16 checks).

## Verification notes (2026-08-08)

`tests/smoke_version_watermark.gd`, 16 checks — including that the
watermark's own `version()` is the bare number with no doubled "v",
and that its CanvasLayer sits above the menu's (128 vs 1) so it is
never hidden behind a screen.

The CI guard was teeth-checked by running its comparison against the
wrong tags:

| tag being built | result |
|---|---|
| `v0.1.10` | passes |
| `v0.1.9` (stale — the exact bug) | **fails, caught** |
| `v0.2.0` | **fails, caught** |

Drawn with a dark outline as well as a light fill, because the Sniper
renders on a pure-black background while the playground is bright —
one colour alone would vanish on one of them.

## Out of scope

- Showing the version to *other* players, or refusing to connect on a
  mismatch. That is a real protocol check and deserves its own story.
- A build date, commit hash, or "dirty" marker.
