---
name: finish-component
description: The lean done-bar for a TrembusUI component — run the gate, hand Nick the contact sheet and the live gallery, fix what HE names, re-run the gate. Nick judges look and feel; Claude does not take screenshots or spawn review agents unless Nick asks for a deep review. Use after implementing or changing a component under Sources/TrembusUI/Components (e.g. "/finish-component Meter").
---

# finish-component — the lean done-bar

```
make validate  →  snap + gallery FOR NICK  →  Nick says what looks / feels wrong  →  fix  →  make validate
```

**Nick is the eyes and the hands. Usage is a weekly budget — checking is what burns it.**

## Default (always)

1. `make validate`. Red? Fix that first.
2. `make snap NAME=<Name>` and `make gallery NAME=<Name>` — then STOP and tell Nick they are ready.
   Ask what he sees. Do **not** read the PNGs. Do **not** drive the gallery.
3. Fix what he names. One image read — cropped, low scale — only if he asks, or to chase a bug he described.
4. Touched a primitive or tokens? `make -s neighbors NAME=<it>` and re-snap those for Nick. List them; don't read them.
5. `make validate` once more. Report in a few lines: what changed, what ran green, what is NOT verified.

## Tests

A handful per component, for logic that can really break: clamping, rounding, a rule the Form states.
Written with the code. No "seen failing first" ritual. No real-window tests unless a bug needs one.
Can't verify something here after one try? Put it under "Not verified yet" in CLAUDE.md and move on.

## Deep review — ONLY when Nick asks for it in his own words

Say the rough cost first (two review agents ≈ hundreds of thousands of tokens). Then, if he says go:
one conventions reviewer + one bug hunter, read-only, in parallel. Triage every finding — accept or
reject with a one-line reason — and fix only what is accepted.

**Recorded ≠ Accept.** A green gate is Recorded. Accept is Nick's.
