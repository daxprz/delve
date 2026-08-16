---
xid: STO-TOOLS-013
parent: ./epic.md
kind: story
effort: tools
size: S
status: shipped
date: 2026-08-16
depends-on: [STO-TOOLS-011]
bd-id: delve-cpp9
tasks: 5
complete: 5
---

# It tells you what is wrong with your model, in words

## Summary

The code reaches into a loaded part **by name**: `J0` for the base
joint it rotates to curl the claw, `End` for where a block stops, `J1`
for the elbow. Rename `J0` to `Base` in the editor — a completely
reasonable thing to do, since `J0` is a programmer's name — and the
claw stops curling.

Silently. Nothing crashes, nothing prints, the claw is just wrong.

That is the worst possible outcome for someone learning a new program.
It reads as *"I did something wrong and I can't find out what"*, and
that feeling is what makes people stop opening the editor. A young
operator has no reason to suspect a node name; they will assume they
broke the game.

So the loader checks the part when it loads it and, when something is
missing, says so in a sentence a person can act on:

```
[PART] scenes/parts/claw.tscn — ProngTL has no "J0".
       A prong needs: J0 > (Seg, End > J1 > (Seg, End))
       Did you rename it? Using the built-in claw instead.
```

Two things in that message matter as much as the words:

- **it names the file and the node**, so there is somewhere to go;
- **it says what it did instead**, so the operator knows the game is
  still running and nothing is destroyed.

And the fallback is the real safety: a broken model **falls back to
the code-built claw** rather than leaving an armless Grabber. A
mistake should cost you your change, never your game.

## Definition of Done

- [x] A part missing a required node prints a message naming the file,
      the node, and the shape it expected.
- [x] The game keeps running, using the built-in shape.
- [x] The message says which it used, so the operator is not left
      wondering why their edit did nothing.
- [x] A test breaks a model on purpose and checks both the message and
      that the claw still exists.
- [x] Nothing is printed at all when the model is fine — a warning
      that always appears is a warning nobody reads.

## Out of scope

- Fixing the model automatically. Guessing that `Base` meant `J0`
  would work until it didn't, and a tool that silently rewrites your
  work is worse than one that explains itself.

## What it actually says

Renaming `J0` to `Base` — the likeliest mistake, since `J0` is a
programmer's name and `Base` is what a person would call it — produces:

```
[PART] claw.tscn — ProngTL has no "J0".
       A limb needs: J0 > (Seg, End > J1 > (Seg, End))
       Did you rename it?
       Using claw_default.tscn instead, so the game keeps running.
       Your file is untouched.
```

Deleting the file entirely produces the same shape of message with
"is missing." in place of the rename line. Both leave a working
four-pronged claw.

## Verification

`smoke_part_model` breaks the model on purpose and asserts the message
separately on each thing the operator would otherwise have to ask:
it names the file, names what was missing, says where it was looking,
says what it used instead, and says their file was not overwritten.
Then it deletes the file outright, then restores it and checks that a
model which is FINE says **nothing at all**.

Sabotage-tested: removing the fallback fails 8 checks, including the
one that matters most — the Grabber is left with 0 prongs.

## Note on the fallback

The story said a broken model falls back to "the code-built shape".
It falls back to `claw_default.tscn` instead, because STO-TOOLS-011
deleted the code-built shape — keeping it alive purely as a fallback
would have kept the eight constants that story existed to remove.

The backup file is better anyway: it is the answer to "how do I get
the original claw back?", which is `cp claw_default.tscn claw.tscn`,
and STO-TOOLS-015 should say so.
