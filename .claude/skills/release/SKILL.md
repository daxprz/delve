---
name: release
description: Cut a delve release — verify the suite with nothing skipped, bump the version, tag, and push, which triggers the GitHub Actions pipeline that builds Linux/Windows/macOS, writes manifest.json, and publishes the release the beeprz fleet installer picks up. Takes an optional major.minor.patch version; with none, bumps the patch. Use when asked to release, ship, cut a version, or push a build to the fleet.
---

# Releasing delve

## Which version

The skill takes an **optional** `major.minor.patch`.

- **Given one** — use it exactly, e.g. `/release 0.2.0`.
- **Given nothing** — take the version currently in `project.godot`
  and **increment the patch**, keeping major and minor. So 0.1.12
  becomes 0.1.13.

Read the current version rather than the last tag, because the two can
legitimately differ: the version is sometimes bumped in a commit before
anyone releases it.

```bash
CUR=$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)
# no argument: bump the patch
NEXT=$(echo "$CUR" | awk -F. '{printf "%d.%d.%d", $1, $2, $3 + 1}')
```

Two things to check before accepting either answer:

- It must be **higher than the newest tag** — `git tag --sort=-v:refname
  | head -1`. Re-tagging a released version silently ships the wrong
  build to the fleet.
- A given version must be **three numbers**. Reject anything else
  rather than guessing what was meant.

Say which version is being cut, and why, before doing anything: "no
version given, so 0.1.12 becomes 0.1.13."

Tagging is the whole trigger. Pushing a tag `v*` starts
`.github/workflows/release.yml`, which builds Linux, Windows and macOS,
stamps the version into the bundles, writes `manifest.json`, and
publishes a GitHub Release. The **beeprz fleet installer** consumes
that `manifest.json` — so a bad tag is a bad rollout, not just a bad
download.

That is why most of this skill is checks, and only the last two steps
actually release anything.

## The rule that exists because it was broken

> **The game must be CLOSED, and the suite must report `skipped=0`.**

delve shipped **v0.1.9 with two failing tests** because roughly 24
tests need UDP port 7777, the operator had the game open, the runner
skipped them, and skipped read as fine. Since then the runner prints
"skipped tests are NOT verified" — heed it.

**Check the port with `ss -lunp`, not `ss -ltn`.** 7777 is **UDP**. A
TCP check reports it free while the game plainly holds it, which has
wasted time more than once.

Only the *play* instance holds the port, not the editor — so stop the
running game and leave the editor open.

## Steps

### 1. Everything committed

```bash
git status --porcelain          # must be empty
```

Nothing uncommitted goes into a release. If there are changes, commit
them properly first — with a real message, not "wip".

### 2. Close the game and free the port

```bash
ss -lunp 2>/dev/null | grep :7777        # nothing = good
pgrep -a godot
```

If held, kill the *play* child process (the one with `--remote-debug`
and `--scene`), not the editor.

### 3. Full suite, nothing skipped

```bash
scripts/run_suite.sh
```

Require **`skipped=0`**. If any were skipped, the port came back
mid-run — run those tests individually and confirm them before going
on.

**Any failure must be explained, not waved through.** The honest way to
tell "pre-existing" from "I broke it" is to stash and re-run:

```bash
git stash push --include-untracked scripts/ tests/
timeout 150 godot --headless --path . -s res://tests/<failing>.gd
git stash pop
```

Failing before your changes = pre-existing, and may ship if it is
recorded in the release notes. Passing before = **you broke it**, and
it must be fixed or reverted before releasing.

### 4. Version must match the tag

The workflow **fails the build** if `application/config/version` in
`project.godot` does not equal the tag without its `v`. It fails on
purpose: the in-game watermark reads that field, and a download that
confidently displays the wrong version is worse than one showing none.

```bash
grep 'config/version' project.godot
git tag --sort=-v:refname | head -3
```

Set `project.godot` to the version chosen at the top of this skill —
the one supplied, or the patch bump — and commit that bump on its own,
so the release tag points at a commit that says what it is.

```bash
sed -i "s|^config/version=.*|config/version=\"$NEXT\"|" project.godot
git add project.godot && git commit -m "release: v$NEXT"
git push origin main
```

**Push `main` before tagging.** A tag pushed to a commit that is not on
the remote builds nothing.

### 5. Tag with real notes, and push

Write the notes for the **operator**, who is a child building this
game — plain language, what is new to *play*, not a changelog of
commits. Group by what it means in the game.

Always include a section listing **knowingly-failing tests** and
whether each is pre-existing or new. Shipping a known fault is fine;
shipping it silently is not.

```bash
git tag -a vX.Y.Z -F /tmp/tag.txt
git push origin vX.Y.Z
```

### 6. Say what happens next

The pipeline takes a few minutes. It produces the three platform
archives plus `manifest.json` — `schema`, `version`, `released`,
`default_port`, and per platform `file`, `sha256`, `size`, `entry`.
The contract is documented in `README.md` under **Deployment bundle**;
that section is the spec and `scripts/make_manifest.py` is its
implementation.

There is no `gh` CLI on this machine, so the run cannot be watched from
here — say so rather than implying it was checked.

## Do not

- Release with `skipped > 0`.
- Release with an unexplained failure.
- Tag a version that does not match `project.godot` — the build will
  reject it anyway, after wasting several minutes.
- Write notes that list commits. Say what changed **in the game**.
