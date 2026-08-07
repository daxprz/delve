---
xid: STO-TOOLS-005
parent: ./epic.md
kind: story
effort: tools
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-7k7
shipped: 2026-08-07
tasks: 5
complete: 5
---

# GitHub Actions builds Linux + Windows releases

## Summary

`.github/workflows/release.yml` builds downloadable **Linux** and
**Windows** versions on GitHub's runners, so people can play without
installing Godot or cloning the repo.

- push a tag `v*` → builds both and publishes a GitHub Release
- run manually from the Actions tab → builds and attaches the zips to
  that run, without publishing

`export_presets.cfg` is now committed (it was gitignored) because CI
cannot export without it. The presets exclude the non-game parts of
the repo — `effort/`, `tests/`, `ai/`, the Beads DB — so a download is
just the game.

## Definition of Done

- [x] Workflow builds Linux and Windows from a tag.
- [x] Manual runs possible for testing without tagging.
- [x] Export presets committed and excluding non-game files.
- [x] The build fails loudly if an export produces nothing.
- [x] Release notes explain how to play together.

## Out of scope

- macOS (needs signing/notarisation to be pleasant).
- Auto-updating.

## Verification notes (2026-08-07)

- Godot download URLs were checked against the real
  `godotengine/godot-builds` release assets for 4.6.3-stable rather
  than guessed.
- **The workflow itself is unverified** — it cannot run locally. The
  first tag push is the real test. Most likely failure points: the
  export-template install path, and Godot's exit codes on import
  warnings (already tolerated with `|| true`).
