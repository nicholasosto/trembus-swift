---
name: finish-component
description: Run the TrembusUI component quality loop before declaring a component done — read its contact sheet in all three themes, feel it in the live gallery, run a parallel adversarial review (conventions + bug hunt), land every accepted fix with a regression test, and re-run the gate. Use after implementing or substantially changing a component under Sources/TrembusUI/Components (e.g. "/finish-component Meter", "finish the Tag component").
---

# finish-component — the quality loop

The bar for "done" here is NOT "tests pass". It is:

```
looked at in 3 themes  →  felt in the gallery  →  adversarially reviewed  →  fixes have tests
        →  neighbors re-looked  →  gate green  →  RECORDED   (Accept is Nick's, never the gate's)
```

## 0 · Scope

Locate `Sources/TrembusUI/Components/<Name>/` and `Sources/TrembusCatalog/Entries/Components/<Name>Entry.swift`.

Read the entry's `form:` — meaning, invariants, prohibitions. It is the brief everything below is judged against.

## 1 · Fast gate first

`make test` — don't spend review time on a component that is already red.

## 2 · Look (stills — Claude's eyes)

```bash
make snap NAME=<Name>                              # one sheet: every specimen × every theme
make snap NAME=<Name> ARGS='--singles --scale 3'   # close-ups: Snapshots/<Name>/<Specimen>.<theme>.png
```

**Read the PNGs. Read, don't vibe.** Check, in light AND dark AND reliquary:

- text-on-tone contrast · label collisions and clipping · shadows cut off at a band edge
- focus ring distinct from selection · disabled clearly disabled · hover ≠ pressed ≠ rest
- a tall sheet is downscaled when read — **zoom with `--singles --scale 3` before calling anything a bug** (a "white" label once turned out to be correct dark ink)

Stills cannot show: Liquid Glass / materials (render as nothing), motion, real hover. That is what step 3 is for.

## 3 · Feel (live — the gallery)

```bash
make gallery NAME=<Name> THEME=dark
```

It runs as a real app (`com.trembus.gallery`), so screen-driving tools can address it:
`request_access(["com.trembus.gallery"])` → `app_screenshot` / `app_click` / `app_menu(["Theme","Reliquary"])`.

- Exercise the `Interaction` specimen and confirm the acknowledged state actually changes.
- Switch themes live; state must survive the switch.
- If a window screenshot comes back as a tiny thumbnail, the window is on another Space / in a side dock — ask the user to bring it to the current Space.
- Keyboard focus needs **System Settings → Keyboard → Keyboard navigation** ON; keys sent to a background window are unverified. Say so rather than guessing.

## 4 · Adversarial review — two agents, IN PARALLEL (one message)

1. **Conventions reviewer** — every Form invariant is visible in a specimen or held by a test, no prohibition is broken, the Form still mirrors the web contract · three-file shape · contract names a real specimen per job and says HOW · tokens only (no hex, no magic numbers) · size via `controlSize` + `ControlMetrics` · built on `Pressable`/`InteractionReader` so states freeze · `.motion` not `.animation` · tone is never the only signal · `Shape`/`EnvironmentKey`/value types marked `nonisolated` · every file imports what it uses.
2. **Bug hunter** (`general-purpose`) — tell it to CONSTRUCT inputs and trace code, not skim: NaN / infinity / negative / zero-width ranges, empty and very long strings, RTL, `controlSize` extremes, disabled + loading together, rapid toggling mid-animation, Increase Contrast / Reduce Motion / Differentiate Without Color. Require per finding: severity, exact triggering input, wrong behavior, minimal fix. Tell it to drop suspicions that don't survive its own trace.

Give both the component path, its entry file, and the sibling that is the convention baseline (Button for styles, Meter for views).

## 5 · Triage + fix

- Accept or reject each finding explicitly — a rejection needs a one-line reason.
- **Every accepted fix lands with a regression test that fails before and passes after.** Prove the "fails before" half: a test that passes with the bug present is worth nothing (this has happened here — a density test passed with the fix switched off, because it probed vector content instead of text).
- Findings both agents raise = high confidence; do those first.

## 6 · Harmonics pass — what else did this change touch?

One change, authored relationships, a bounded walk, a human look. Review candidates, not proof.

```bash
git status --short Sources/TrembusUI/Primitives Sources/TrembusTokens   # did shared ground move?
make -s neighbors NAME=<ChangedPrimitiveOrComponent>                    # who builds on it, ≤2 hops
make snap NAME="$(make -s neighbors NAME=Surface | tr '\n' ' ')"         # re-photograph only those
```

- Touched a **primitive**? Run `neighbors` for each file touched and **Read every neighbor's sheet**.
- Touched **tokens**? Everything is a neighbor: `make snap`, read all.
- Touched only `Components/<Name>/`? Still run `make -s neighbors NAME=<Name>` — a component can be built on.
- Changed what the component MEANS (not just how it looks)? That is a Form revision: web contract first, bump `revision`, mirror here.

## 7 · Re-gate

`make validate` (lint + build + test), then `make snap NAME=<Name>` once more and re-read the sheet.

## 8 · Report — the done-bar

Use Relay's words honestly: a green gate with evidence is **Recorded**. **Accept** is Nick's decision that
the result is what he meant — never claim it for him.

State plainly: which neighbors were re-looked at and why, which themes were read, what was exercised live, the findings table (finding → fixed-with-test | rejected-because), and the exact gates that ran green. **If a leg was skipped, say so** — never declare done past a skipped leg.
