# trembus-swift — guide for Claude

A SwiftUI component library for macOS. The Swift sibling of
[`@trembus/ui`](https://github.com/nicholasosto/Trembus-Component-Library) (React — checked out
next door as `../Trembus-Component-Library`): same tokens, same three themes, same three-jobs contract.

```
   TrembusTokens ──▶ TrembusUI ──▶ TrembusCatalog ─┬─▶ TrembusGallery   live app   (feel it)
   values only       primitives    contract +       ├─▶ TrembusSnap      PNG sheets (see it)
   thread-safe       components    specimens        ├─▶ Xcode previews   canvas
                     main-actor                     └─▶ tests            the gate
```

**tokens → primitives → components.** Every component carries a machine-checked contract:
_Reveal State · Afford Action · Acknowledge Input_.

## The loop

```
edit ──▶ make snap NAME=X ──▶ READ Snapshots/X.png ──▶ make gallery NAME=X ──▶ make validate
          every specimen          Claude's eyes            how it feels             the gate
          × every theme
```

| Command | What it does |
| --- | --- |
| `make snap [NAME=X]` | PNG contact sheets → `Snapshots/`. `ARGS='--singles --scale 3'` for close-ups. |
| `make gallery [NAME=X THEME=dark]` | Builds + opens the live gallery as a real app (`com.trembus.gallery`). |
| `make new NAME=X [LEAD=…]` | Scaffolds the three-file shape. Gate stays red until the contract TODOs are real. |
| `make validate` | **The gate**: lint + build + test. Run before calling anything done. |
| `make format` · `lint` · `doctor` · `clean` | House style · check only · which toolchain · wipe `.build` + `Snapshots`. |

**Always go through `make` or `Scripts/swiftw` — never bare `swift`.** See the first gotcha.

**CI** (`.github/workflows/ci.yml`, `macos-26`) runs `make validate` then `make snap` on every push and PR,
and attaches the sheets as the `snapshots` artifact. The runner is a headless 1× machine — the same
conditions that once made snapshots blurry — so a green run also proves the density fix off this Mac.
The repo is **public**: a push to `main` is a publication.

Skills: **`/new-component <Name>`** scaffolds. **`/finish-component <Name>`** is the done-bar
(look in 3 themes → feel it live → adversarial review → fixes WITH tests → re-gate).

## House rules

- **Styles for what SwiftUI has, views for what it lacks.** Button and Switch are a `ButtonStyle` /
  `ToggleStyle` (you keep roles, shortcuts, accessibility). Badge and Meter are views.
  Never name a type after a SwiftUI type — `Scripts/new-component` refuses.
- **Tokens only.** `.theme(.surface)` · `.tone(.success, .bg)` · `Space.s4` · `Radius.md` ·
  `.font(.trembus(.sm))`. Never a hex, never a magic number. Need a plain `Color` (shadows,
  Canvas)? `@Environment(\.theme)` then `theme.color.border.color`.
- **No `size:` parameters.** Components read SwiftUI's `controlSize`. All size tables live in
  ONE file: `Primitives/ControlMetrics.swift`. Heights there are **Mac density (24/30/38)**, not the
  web's 28/36/44 — tokens are shared with the web, control heights deliberately are not.
- **Every state must be photographable.** Interactive things build on `Pressable` /
  `InteractionReader`, so `.interactionOverride(.hovered)` can freeze them for a still.
- **`.motion(_:value:)`, never bare `.animation`.** It swaps in a plain fade under Reduce Motion.
  Curves (`Motion.calm`) for color/layout; springs (`Motion.spring(.snap)`) for anything the pointer touches.
- **Tone is never the only signal.** Always a word; the dot becomes a glyph under Differentiate Without Color.
- **Haptics for snaps and thresholds, not clicks** — a trackpad click already is one.
- **Three-file shape**: `Components/<Name>/` + `Entries/Components/<Name>Entry.swift` +
  `Tests/…/<Name>Tests.swift`. Specimens named `Default` / `States` / `Interaction`. `contract.name` = directory name.

## Tokens: the web CSS is the source of truth

`Sources/TrembusTokens/Themes.swift` is copied **hex-for-hex** from
[`packages/tokens/src/css/tokens.{light,dark,reliquary}.css`](https://github.com/nicholasosto/Trembus-Component-Library/tree/main/packages/tokens/src/css)
in the React repo (locally: `../Trembus-Component-Library/…`).
When that CSS changes, re-sync here. Don't fork a value locally — fix it there.

Two deliberate differences from the web, both proven by `ContrastTests`:

- **Hover / pressed fills step AWAY from their ink** (`ToneColors.steppedAwayFromInk`). The web Button
  always mixes toward black; in dark themes that walks a bright fill toward its dark label
  (pressed `danger` hits 3.7:1). Accent uses the authored `accentHover` / `accentActive` tokens.
- **Known inherited gap**: light `textFaint` on `surfaceSunken` / `surfaceHover` is 4.35–4.40:1.
  Recorded with `withKnownIssue` in `ContrastTests.inheritedGaps` — it turns red by itself once the CSS is fixed.

## Gotchas — each of these cost real time once

**1 · `@State` is a macro in the macOS 27 SDK, and Command Line Tools can't expand it.**
CLT has no `SwiftUIMacros` plugin. If `xcode-select` points at CLT (common — CLT updates itself
ahead of Xcode; it was the case on the machine this was built on), bare `swift build` dies on every `@State`. `Scripts/swiftw` picks a working
toolchain per-command (full Xcode, else CLT + a pre-27 SDK) without touching system settings.
`make doctor` shows what it picked. For the same reason: **`PreviewProvider`, not `#Preview`; hand-written
`EnvironmentKey`, not `@Entry`** — so the package still builds on the CLT fallback.

**2 · Every file imports what it uses. No re-exports.** `MemberImportVisibility` is on.
When the catalog reached tokens through `@_exported import`, SwiftPM's incremental build couldn't
see the dependency: changing a token struct's layout left the catalog un-rebuilt and the next test
run **segfaulted**. If you ever see a bus error / segfault right after editing a struct: `make clean`.

**3 · TrembusUI is main-actor by default; TrembusTokens is not.** SwiftUI evaluates some things off
the main thread, so in the main-actor modules mark these `nonisolated` (the compiler errors if you
forget — it never crashes): `Shape` / `ShapeStyle` / `Layout` types · `EnvironmentKey` + its
`EnvironmentValues` extension · plain value types. Nested types inside a **generic** view are a
different type per specialization — hoist them out (see `SurfaceLevel`).

**4 · Swift Testing evaluates `@Test(arguments:)` off the main actor.** Catalog entries hold view
builders and can't leave it. Render tests loop inside one test and name entry/specimen/theme per failure.

**5 · The snapshot camera is a software renderer, and it lies in three known ways.**
`Snapshotter` corrects the first two on the capture copy only — never bend a component to suit the camera.
   - *Density*: an offscreen window rasterizes text at the **main screen's** scale. On a 1× display
     (an external monitor, most CI runners) "2×" snapshots were blurry enlargements. Fixed by forcing `contentsScale`
     on the layer tree. Guarded by `snapshotsHaveTruePixelDensityOnAnyDisplay` (only TEXT discriminates).
   - *Pills*: `Capsule()` is a continuous-corner layer; the software renderer draws stray ticks
     on full pills. Fixed by falling back to circular for the photo, as the GPU does on screen.
   - *Glass / materials*: not capturable at all. `Surface(.glass)` is blank in stills — check it live.
   A live macOS 26 window can't be self-captured either (we tried a `--screenshot` flag; it came out blank and was removed).

**6 · Specimens need a definite size.** A bare flexible view makes `Snapshotter` throw
`emptyLayout` — give it a `.frame(width:)`.

**7 · `make gallery` wraps the binary in a `.app` bundle on purpose.** A bare `swift run` executable has
no bundle id: no Dock name, invisible to Accessibility Inspector and screen-driving tools, and it
blocks the terminal. If an `app_screenshot` of it comes back as a tiny thumbnail, the window is on
another Space or in a side dock.

## Not verified yet

- The **live keyboard focus ring**. It draws correctly when frozen (`.interactionOverride(.focused)`),
  but real Tab focus was never observed — needs System Settings → Keyboard → Keyboard navigation ON.
  Open question: a `ButtonStyle` can't call `.focusEffectDisabled()` on its own button from the inside,
  so macOS may draw its blue ring as well as ours.
