---
xid: STO-TOOLS-010
parent: ./epic.md
kind: story
effort: tools
size: S
status: draft
date: 2026-08-07
depends-on: []
bd-id: delve-jm0
---

# The app bundle reports the real version, not 1.0.0

## Summary

`Delve.app` tells macOS it is version **1.0.0**. It is 0.1.10.

Reported by the operator: the watermark added in STO-UI-007 correctly
shows `v0.1.10` *inside* the game, but the **bundle metadata** around
it is a separate thing — what Finder shows in Get Info, what the
About panel reads, and what any deployment tool would query to decide
whether a machine needs updating.

The export presets leave the fields blank, so Godot fills in its
default:

```ini
application/short_version=""     # macOS CFBundleShortVersionString
application/version=""           # macOS CFBundleVersion
```

**Windows has the same hole**, which nobody had noticed because
nothing displays it as prominently:

```ini
application/file_version=""      # exe file version
application/product_version=""   # exe product version
```

This matters beyond tidiness. The whole point of the network
deployment work (STO-TOOLS-008) is that a machine can tell what it
already has. A bundle that claims 1.0.0 forever is exactly the kind of
thing an installer would trust and get wrong.

## Definition of Done

- [ ] `Delve.app` reports 0.1.10 to macOS, not 1.0.0.
- [ ] The Windows `.exe` reports it too.
- [ ] The version comes from the **tag**, so it cannot go stale the
      way this one did — no hand-editing before each release.
- [ ] A release built from a tag whose version disagrees still fails,
      as STO-UI-007 established.
- [ ] Verified by unpacking the built `.app` and reading its
      `Info.plist`, not by trusting the export settings.

## Out of scope

- Code-signing or notarising the macOS build. Separate problem, much
  bigger, and the README already documents the `xattr -cr` workaround.
- A build number distinct from the version.

## Notes

Found by the operator on a real download, which is the only place it
was visible. Nothing in the repo or the test suite looks at the built
bundle's metadata — the tests check the game, and this is the wrapper
around the game.
