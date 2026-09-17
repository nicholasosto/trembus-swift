---
name: new-component
description: Scaffold a new TrembusUI SwiftUI component in the canonical three-file shape (component / catalog entry with contract + specimens / logic tests), registered in the catalog and rendering immediately. Use when adding a component to this library (e.g. "/new-component Tag", "add an Avatar component").
---

# new-component

```
Scripts/new-component <Name>
        │
        ├─▶ Sources/TrembusUI/Components/<Name>/<Name>.swift              the component
        ├─▶ Sources/TrembusCatalog/Entries/Components/<Name>Entry.swift   contract + 3 specimens + Xcode preview
        ├─▶ Tests/TrembusUITests/<Name>Tests.swift                        its own logic
        └─▶ Sources/TrembusCatalog/Catalog.swift                          + .<name>
```

## Run it

```bash
make new NAME=Tag
make new NAME=AvatarGroup LEAD=reveal-state     # or afford-action | acknowledge-input
```

- `NAME` — PascalCase. It becomes the directory name AND `contract.name` (they must match).
- `LEAD` — the UI job the component leads with. Default `reveal-state`.
- It refuses to overwrite, and refuses a name SwiftUI already uses (see "Style or view?").

The scaffold compiles, lints, and renders in all three themes straight away.
**The contract gate stays RED until the three `TODO` statements are real sentences.** That is on purpose — a contract that says TODO is not a contract.

## After scaffolding

1. `make snap NAME=<Name>` — then **Read `Snapshots/<Name>.png`**. Look before you design.
2. Design `<Name>.swift`:
   - **tokens only** — `.theme(.surface)`, `.tone(.success, .bg)`, `Space.s4`, `Radius.md`. Never a hex, never a magic number.
   - **size follows `.controlSize(_:)`** — add a table to `Primitives/ControlMetrics.swift`; no `size:` parameter.
   - **interactive?** build on `Pressable` (or `InteractionReader` inside a style) so every state can be frozen with `.interactionOverride(_:)`.
   - **motion** — `.motion(_:value:)`, never bare `.animation`, so Reduce Motion is honored for free.
3. Make the specimens earn their names:
   - `Default` — the one-line usage. `States` — every state, frozen (`StateRow { … }`). `Interaction` — live, with `@State`.
   - Every specimen needs a **definite size**: give flexible views a `.frame(width:)`.
4. Replace the contract `TODO`s. Honest beats impressive — "non-interactive by design — it reports state" is a fine answer.
5. Put the component's own logic (clamping, value → tone rules) behind an internal computed property and test it in `<Name>Tests.swift`, the way `MeterTests` checks `Meter.fraction`.
6. `make validate`, then run **/finish-component <Name>** — that is the done-bar, not green tests.

## Style or view?

> **Styles for what SwiftUI has. Views for what it lacks.**

| You are making… | Build a… | Copy the shape of |
| --- | --- | --- |
| a better Button / Toggle / anything SwiftUI ships | **style** (`ButtonStyle`, `ToggleStyle`, …) — by hand | `Components/Button/`, `Components/Switch/` |
| something SwiftUI doesn't have (Badge, Meter, Tag) | **view** — `make new` | `Components/Badge/`, `Components/Meter/` |

A style keeps SwiftUI's own control and everything attached to it: roles, keyboard shortcuts, menus, accessibility. For a style, the directory is still `Components/<Name>/` and the contract name is still `"<Name>"` — create the three files by hand and add `.<name>` to `Catalog.entries`.
