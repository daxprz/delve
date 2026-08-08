---
xid: STO-TOOLS-010
parent: ./epic.md
kind: story
effort: tools
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-jm0
shipped: 2026-08-07
tasks: 5
complete: 5
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

- [x] `Delve.app` reports its real version to macOS, not 1.0.0.
- [x] The Windows `.exe` reports it too.
- [x] The version comes from the **tag** — CI stamps all four fields
      at build time, so there is nothing to hand-edit or forget.
- [x] A release built from a mismatched tag still fails
      (STO-UI-007's guard runs first, in the same step).
- [x] Verified by unpacking the **published** build, not by trusting
      the export settings.

## Verification notes (2026-08-08)

Checked against the real download, because the export settings looking
correct is exactly what was true before this bug existed.

`delve-macos.zip` -> `Delve.app/Contents/Info.plist`:

```
CFBundleShortVersionString  0.1.11
CFBundleVersion             0.1.11
```

`delve-windows.zip` -> `delve.exe` version resource carries
`FileVersion` / `ProductVersion` with `0.1.11`.

`tests/smoke_version_watermark.gd` now also reads
`export_presets.cfg` and compares every version field against
`application/config/version`. Teeth-checked both ways it can break:

| what was done to the field | what the test said |
|---|---|
| blanked | *"is EMPTY — that is what makes builds say 1.0.0"* |
| set to 0.1.9 | *"matches the project version (0.1.9 vs 0.1.11)"* |

Shipped as **0.1.11** rather than rebuilding 0.1.10. That binary was
already published, and replacing a file under a tag someone may have
installed is worse than moving forward.

## Out of scope

- Code-signing or notarising the macOS build. Separate problem, much
  bigger, and the README already documents the `xattr -cr` workaround.
- A build number distinct from the version.

## Notes

Found by the operator on a real download, which is the only place it
was visible. Nothing in the repo or the test suite looks at the built
bundle's metadata — the tests check the game, and this is the wrapper
around the game.
