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

The first attempt (tag v0.1.1) **failed in CI**, and the job log needs
repo-admin rights to read — so rather than guess, the export was
reproduced locally by downloading the same Godot build and templates
CI uses. The real error appeared immediately:

> Cannot export for universal or arm64 if ETC2 ASTC texture format is
> disabled.

Godot refuses to build for Apple Silicon without that texture format.
Fixed by enabling `rendering/textures/vram_compression/import_etc2_astc`
in project settings and `texture_format/etc2_astc` in the preset. It
costs delve nothing — there are no imported textures, every material
is procedural.

After the fix, verified locally rather than hoping:

- export succeeds, producing a 61.7 MB zip;
- it contains a real bundle (`Delve.app/Contents/...`);
- `file` reports **Mach-O universal binary, x86_64 + arm64**;
- the Linux export still works, so the project-settings change broke
  nothing.

Also caught: the bundle is `Delve.app` (capitalised), so the
Gatekeeper instructions in the release notes were corrected.

Still unverified: whether the app actually **launches** on a real Mac.
CI and local export prove it builds; only a Mac can prove the rest.

**Worth noting** — the guard `test -s <exported file>` in the workflow
is what turned this into a visible failure. Godot exited with code
**0** despite printing the error and producing no file, so without
that check CI would have reported success and published an empty
release.
