---
xid: EPI-CHARACTER-FINGERS
parent: ../design.md
kind: epic
effort: character
status: open
date: 2026-08-13
bd-id: delve-3av
---

# Fingers on the Grabber's hands

## Summary

The Grabber's hands get **five real fingers**, each with **two
joints**, generated in code like everything else in delve. They wrap
around whatever you grab, they clench into a fist in punch mode, and
they bend the way real fingers bend — they cannot fold backwards or
pass through each other.

Today the hand is a solid block with four decorative knuckle ridges
and no fingers at all. Grabbing something makes the whole block move
to it; nothing closes around anything.

This is the piece that will make grabbing *look* like grabbing.

## Definition of Done

- [ ] Each hand has 5 fingers, each with 2 joints.
- [ ] They are generated in code, not modelled by hand.
- [ ] Grabbing something closes the fingers around it.
- [ ] Punch mode clenches them into a fist.
- [ ] They cannot bend backwards past straight.
- [ ] They cannot pass through each other.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 057 | procedural-fingers | M | the fingers themselves — **everything waits on this** |
| 058 | finger-limits | M | no bending backwards, no clipping |
| 059 | wrap-around | M | close around what you grab |
| 060 | clenched-fist | S | punch mode makes a fist |

## Out of scope

- Fingers on the **enemies** or on the other characters. The Grabber's
  mechanical arms are the only hands anyone looks at closely.
- Individually controllable fingers.
- Fingers being damaged or torn off.
