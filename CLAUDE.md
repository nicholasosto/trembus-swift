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
| `make neighbors NAME=X` | Harmonics: what to re-look at when X changes — every component that builds on it **and every example that composes it**, ≤2 hops. |
| `make forms` | Platonics: every Form + what each Shape builds on, as JSON. For consumers / a Relay House. Read-only. |
| `make new NAME=X [LEAD=…]` | Scaffolds the three-file shape. Gate stays red until the contract TODOs are real. |
| `make validate` | **The gate**: lint + build + test. Run before calling anything done. |
| `make format` · `lint` · `doctor` · `clean` | House style · check only · which toolchain · wipe `.build` + `Snapshots`. |

**Always go through `make` or `Scripts/swiftw` — never bare `swift`.** See the first gotcha.

**CI** (`.github/workflows/ci.yml`, `macos-26`) runs `make validate` then `make snap` on every push and PR,
and attaches the sheets as the `snapshots` artifact. The runner is a headless 1× machine — the same
conditions that once made snapshots blurry — so a green run also proves the density fix off this Mac.
The repo is **public**: a push to `main` is a publication.

**`main` is ruled** (GitHub ruleset "main: PR + green gate", since 2026-09-17): changes land by **branch → PR →
green `validate` check → merge**. Zero approvals required (solo repo — you cannot approve your own PR). Admins can
bypass for an emergency; don't make it the habit. The check is named after the CI job id — rename the `validate`
job in `ci.yml` and every PR blocks forever until the ruleset is updated to match.

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
- **Labeled controls share `FieldShell`** (label → helper → control → error), like the web's — and its
  `fieldBox` (fill · edge · focus ring · disabled look). Input and Textarea use both; Select should too. Spoken-text rules live in `FieldText` / `FieldStatus` so they are testable.
- **Three-file shape**: `Components/<Name>/` + `Entries/Components/<Name>Entry.swift` +
  `Tests/…/<Name>Tests.swift`. Specimens named `Default` / `States` / `Interaction`. `contract.name` = directory name.

## Examples — mockups of several components together

```
                  contract?   gated by                                     lives in
 component        ✅ 3 jobs    contract · 3 specimens · buildsOn · render   Components/<Name>/ + Entries/Components/
 example          ❌ none      composes · ≥2 components · render            Entries/Examples/<Name>Entry.swift   (ONE file)

 change Input ──▶ make neighbors NAME=Input ──▶ … ProjectSettings ──▶ re-snap + READ it
```

An example answers a different question from a component's specimens: not "does this do its three
jobs" but **"do these sit well together"** — heights line up, spacing holds, a whole-screen state
reads as one thing in every theme. Same rule as the web's `src/examples/`: a page that groups
components is NOT a component and gets no contract.

- **One file**: `Entries/Examples/<Name>Entry.swift`, `kind: .example`, listed under `// Examples` in
  `Catalog.entries` (below the `scaffold:entries` marker). No `make new` — there is nothing else to scaffold.
- **`composes:`** — primitive FILE names + component names, like `buildsOn`. `composesMatchesWhatTheExampleReallyUses`
  reads the entry's source, so it cannot rot; that list is what puts the example on the `make neighbors` walk.
  Only CODE counts as a use — comments and the inside of strings are skipped, because the `composes:` list sits
  in the very file being read and would otherwise vouch for itself.
  Style components are found by their modifier (`.buttonStyle(.trembus)` → Button, `.toggleStyle(.trembus)` → Switch).
- **Public API only.** The catalog reaches the library through a plain `import TrembusUI`, as a consumer does.
  If a mockup needs something internal, that is a finding about the library — never `@testable` your way in.
- **Specimens are SCREEN states, not control states**: `Default` (happy path) · `States` (empty · invalid ·
  busy …, side by side) · `Interaction` (live). Drive the stills and the live one from ONE layout fed plain
  data (see `ProjectForm`), so the still cannot drift from the real thing.
- **A mockup finds things; it does not fix them.** What looks wrong in a group (a Meter that does not dim in a
  disabled form, accent and danger colliding in reliquary) goes back to the component or the tokens.
  Never patch it inside the example — and never bend a component to suit one mockup.
- The done-bar is lighter than `/finish-component`: snap → READ all three themes → gallery → `make validate`.

## Form → Shape → Instance (Platonics) · what moves together (Harmonics)

```
Form      what a component IS: meaning · invariants · prohibitions · variation     authored on the WEB
 └▶ Shape     the React component · this SwiftUI one  (+ `buildsOn:` — what it is made of)
     └▶ Instance  a specimen · a card on a consumer's screen

change X ──▶ make neighbors NAME=X ──▶ re-snap + READ those sheets ──▶ a human judges
```

Vocabulary is Relay's (Form / Shape / Instance; Recorded ≠ Accept). Two fields on `ComponentContract`:

- **`form:`** — mirrored **word for word** from `<Name>.contract.ts` next door, same rule as the tokens:
  change it THERE first, bump `revision`. `everyFormMirrorsTheWebContractWordForWord` fails on drift
  (it skips when the sibling isn't checked out, e.g. CI). Optional for now — only Card and Textarea have one; back-fill
  the others as their web contracts gain a `form`.
- **`buildsOn:`** — primitive FILE names + component names. `buildsOnMatchesWhatTheSourceReallyUses` reads
  the source, so the list cannot rot. (It uses `NSRegularExpression`: Swift Regex's `\b` follows Unicode
  word rules, where the "." in `ControlMetrics.button` does not end a word.)

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

**8 · A native macOS text field does several things you would not guess.** All found building `Input`;
each has a regression test that was seen failing first.
   - It **ignores any styling on `prompt:`** (even pure red) and paints a dark system gray — dark enough
     that an empty field looks pre-filled. So `Input` draws its own placeholder in `textFaint`.
   - With no prompt it **paints its TITLE as a placeholder**. So the native field gets `""` as its title
     and the accessible name comes from `.accessibilityLabel`.
   - A plain field has **zero text inset** (measured by overlay), so a hand-drawn placeholder sits at
     offset 0 — but it must follow `\.multilineTextAlignment`, and `.leading` reaches AppKit as NATURAL
     alignment, which follows the APP's direction, not SwiftUI's `layoutDirection`.
   - While an **input method composes** (CJK, dead-key accents) the text lives in the field editor and the
     binding stays `""` — watch `NSText.didChangeNotification` + `hasMarkedText()` or the placeholder shows through.
   - A **programmatic focus selects everything**, so the next keystroke replaces the field. `Input` collapses
     the selection to the end when IT hands focus over (a click on the box's chrome, the secure ⇄ plain
     swap) — never for Tab, where select-all is what a keyboard user expects.
   - Swapping `TextField` ⇄ `SecureField` is a different native view: **focus is dropped** unless handed back.
   - Focus-dependent tests need a real (never shown) window that claims to be key — see `LiveWindowTests`.
     A main-actor test IS a main-queue job, so anything the component defers only runs once the test `await`s.

**9 · A native macOS text VIEW (`TextEditor`) is not a text field — six more surprises.** All found building
`Textarea`; each has a test in `TextareaLiveTests` that was seen failing first.
   - It has **no height of its own** — it fills what it is given. An invisible `Text` (same font, same
     5pt `lineFragmentPadding`) decides the height and the editor is laid over it.
   - With **classic scroll bars** (shown whenever a mouse is plugged in) it gives 17pt of width to the bar
     even with nothing to scroll, so its text wraps narrower than you think. The sizer reserves the same
     gutter, or the box comes out lines too short. Held by `theBoxIsExactlyAsTallAsTheNativeTextInsideIt` —
     which only bites on a machine with classic bars; on a trackpad-only Mac the gutter is 0.
   - **Tab types a tab.** In a form Tab means "next field", so `Textarea` catches it and moves the key view.
     **Shift-Tab is not Tab + shift**: it arrives as its own character, backtab (`U+0019`).
   - `NSApp.keyWindow` is **nil whenever the app is not active**. Ask the windows (`isKeyWindow`) instead.
   - While an input method composes it posts **no `NSText.didChangeNotification`** (a field editor does).
     Its selection does move on every composing keystroke — watch `didChangeSelectionNotification`.
   - **Two "always key" test windows steal focus from each other.** Every suite that mounts a window lives in
     an `extension LiveWindowTests { … }`, whose `.serialized` runs them one at a time across files.

## Not verified yet

- **Textarea inside a scrolling page** — does its native scroll view swallow the scroll wheel when it has
  nothing to scroll, so the page stops under the pointer? Suspected, never observed. Feel it in the gallery.
- **Textarea: Tab while an input method composes** (Option-E, then Tab). Tab is let through on purpose —
  the input method may want it — so AppKit may commit the accent AND type a tab.

- The **live keyboard focus ring**. It draws correctly when frozen (`.interactionOverride(.focused)`),
  but real Tab focus was never observed — needs System Settings → Keyboard → Keyboard navigation ON.
  Open question: a `ButtonStyle` can't call `.focusEffectDisabled()` on its own button from the inside,
  so macOS may draw its blue ring as well as ours.
