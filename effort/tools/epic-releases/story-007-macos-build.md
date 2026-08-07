---
xid: STO-TOOLS-007
parent: ./epic.md
kind: story
effort: tools
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-4j2
shipped: 2026-08-07
tasks: 4
complete: 4
---

# macOS build in the release pipeline

## Summary

Adds **macOS** to the release pipeline, alongside Linux and Windows.
Godot exports macOS from the Linux runner (the same `.tpz` carries all
the templates), producing a `.zip` containing `delve.app`, built
universal so it runs on both Apple Silicon and Intel Macs.

The app is **unsigned** — signing and notarising needs a paid Apple
Developer account — so Gatekeeper blocks the first launch. The release
notes now explain both ways past it (right-click → Open, or
`xattr -cr`).

## Definition of Done

- [x] A macOS preset exporting a universal `delve.app` zip.
- [x] The CI matrix builds it and attaches `delve-macos.zip`.
- [x] Packaging doesn't nest a zip inside a zip (Godot already zips
      the .app).
- [x] Release notes tell Mac users how to get past Gatekeeper.

## Out of scope

- Code signing / notarisation (needs an Apple Developer account).
- A `.dmg` installer — that requires building on a Mac.

## Verification notes (2026-08-07)

- Confirmed the 4.6.3 `export_templates.tpz` is what supplies the
  macOS templates, so no extra download is needed.
- **Not verifiable locally**: no export templates on this machine and
  no Mac to run the result on. CI proves it *builds*; whether the app
  actually launches needs someone with a Mac to try it. The most
  likely snags are the unsigned-app warning (documented) and the
  universal-binary architecture setting.
