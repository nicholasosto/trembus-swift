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
**The contract gate stays RED until every `TODO` — the three jobs AND the Form — is a real sentence.** That is on purpose — a contract that says TODO is not a contract.

## Name the Form first (Platonics)

```
Form      what it IS — meaning · invariants · prohibitions · permitted variation     shared
 └▶ Shape     one expression of it: the React component, this SwiftUI one          per repo
     └▶ Instance  one real use: a specimen, a card on a consumer's screen
```

Before any design, fill `form:` in `<Name>Entry.swift`. It is the brief the design must satisfy.

- **Everything happens in THIS repo.** `../Trembus-Component-Library` is read-only from here: never edit,
  build, test or commit in it.
- **The web has a `<Name>`?** READ `../Trembus-Component-Library/packages/ui/src/components/<Name>/`
  (`.tsx`, `.css`, `.contract.ts`) — it is the design brief. If its contract already has a `form:` block,
  copy those sentences here word for word (the gate compares them). If it has none, author the Form here.
- **No web version?** Author it here. Same fields, same bar.
- **Invariants must be checkable** — by a test or by eye on the sheet. "Feels premium" is not one.
- **Name the near neighbor** as a `.distinctFrom` relationship: it is the sentence that stops misuse.
- Changing meaning or an invariant later = a new `revision`.

## After scaffolding

1. `make snap NAME=<Name>` — then **Read `Snapshots/<Name>.png`**. Look before you design.
2. Design `<Name>.swift` — every invariant in the Form should be visible in a specimen or held by a test:
   - **tokens only** — `.theme(.surface)`, `.tone(.success, .bg)`, `Space.s4`, `Radius.md`. Never a hex, never a magic number.
   - **size follows `.controlSize(_:)`** — add a table to `Primitives/ControlMetrics.swift`; no `size:` parameter.
   - **interactive?** build on `Pressable` (or `InteractionReader` inside a style) so every state can be frozen with `.interactionOverride(_:)`.
   - **motion** — `.motion(_:value:)`, never bare `.animation`, so Reduce Motion is honored for free.
3. Make the specimens earn their names:
   - `Default` — the one-line usage. `States` — every state, frozen (`StateRow { … }`). `Interaction` — live, with `@State`.
   - Every specimen needs a **definite size**: give flexible views a `.frame(width:)`.
4. Replace the contract `TODO`s, and keep `buildsOn:` honest — the gate reads the source and tells you
   exactly which primitives and components you used. That list is what `make neighbors` walks. Honest beats impressive — "non-interactive by design — it reports state" is a fine answer.
5. Put the component's own logic (clamping, value → tone rules) behind an internal computed property and test it in `<Name>Tests.swift`, the way `MeterTests` checks `Meter.fraction`.
6. `make validate`, then run **/finish-component <Name>** — that is the done-bar, not green tests.

## Style or view?

> **Styles for what SwiftUI has. Views for what it lacks.**

| You are making… | Build a… | Copy the shape of |
| --- | --- | --- |
| a better Button / Toggle / anything SwiftUI ships | **style** (`ButtonStyle`, `ToggleStyle`, …) — by hand | `Components/Button/`, `Components/Switch/` |
| something SwiftUI doesn't have (Badge, Meter, Tag) | **view** — `make new` | `Components/Badge/`, `Components/Meter/` |

A style keeps SwiftUI's own control and everything attached to it: roles, keyboard shortcuts, menus, accessibility. For a style, the directory is still `Components/<Name>/` and the contract name is still `"<Name>"` — create the three files by hand and add `.<name>` to `Catalog.entries`.
