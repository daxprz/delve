---
xid: STO-TOOLS-012
parent: ./epic.md
kind: story
effort: tools
size: M
status: draft
date: 2026-08-16
depends-on: [STO-TOOLS-011]
bd-id: delve-lore
---

# Whatever you build is solid, without adding collision by hand

## Summary

After STO-TOOLS-011 the operator can add a block in the editor. It
will be **invisible to the game** — a shape with no collision touches
nothing.

Fixing that by hand means, for every block: add an Area3D child, add a
CollisionShape3D under it, make a BoxShape3D, type in three numbers
matching the mesh, set `monitorable = false`, and set the layers. Six
steps, per block, forever, and every one of them a chance to get it
wrong silently.

That is exactly the kind of chore that makes a tool stop being used.
So the code does it: after loading a part, walk every `MeshInstance3D`
in it and give it collision matching its mesh automatically.

Why an **Area3D** rather than a solid body, carried over from the
existing claw: a prong is dragged about by an animated chain, and a
solid body dragged through the world by an animation fights the
physics solver instead of obeying it. An area *detects* what it has
closed around, which is what a claw actually needs to know.

## The failure this is really guarding against

The dangerous version of this story is one that works on the four
prongs that already exist and silently does nothing for a block the
operator adds later — because the test only ever ran against the
exported claw.

So the test must **add a block that was not in the export** and prove
it became solid. Counting 16 pieces would pass with the walk
completely unimplemented, since the export already contains 16.

## Amendment: the mechanism arrived in STO-TOOLS-011

The collision walk shipped early, in STO-TOOLS-011, because it turned
out not to be separable from the export.

The exported scene deliberately leaves the `Touch` areas out — with
them the operator would see 12 nodes per prong instead of 6, and would
have to hand-add a collider to every new block. But once they are not
in the file, something must create them, and building a throwaway
version first would have meant two mechanisms for one job.

So `PartModel.add_collision()` already exists and already generates a
box/sphere/cylinder/capsule collider per mesh, already skips a parent
that has hand-authored collision, and already relies on
`monitorable = false` for the neighbour rule. `smoke_claw`'s 16-piece
count passes against it.

**What is left of this story is the guarantees, not the mechanism** —
the checkbox that matters is the second one below, which nothing yet
proves.

## Definition of Done

- [x] Loading a part gives every mesh in it collision, sized from its
      mesh, with no hand-authored shapes in the scene file.
      *(shipped in STO-TOOLS-011)*
- [ ] A block added to the scene by hand becomes solid with nothing
      else done to it — **proved by a test that adds one**. Still the
      real work: the existing count of 16 would pass with the walk
      unimplemented, since the export already contains 16 blocks.
- [x] Neighbouring pieces do not collide with each other (the rule
      already established at STO-CHARACTER-088; two blocks sharing a
      joint always overlap). *(`monitorable = false`, as before)*
- [~] If the operator *did* author collision by hand, it is respected
      rather than doubled. **Written, not tested.**
- [x] `smoke_claw`'s 16-piece count still passes.

## Out of scope

- Non-box meshes. Boxes are what the claw and every delve limb use;
  cylinders and spheres can come with STO-TOOLS-017 if a part needs
  them.
