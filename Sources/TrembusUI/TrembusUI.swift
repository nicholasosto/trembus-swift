// ┌─ ISOLATION RULE ───────────────────────────────────────────────────────────────┐
// │ This module is main-actor by default (see Package.swift). SwiftUI evaluates a   │
// │ few things OFF the main thread, so these three kinds of declaration must be     │
// │ marked `nonisolated` — the compiler errors if you forget, it never crashes:     │
// │   1. `Shape` / `ShapeStyle` / `Layout` / `Animatable` types                     │
// │   2. `EnvironmentKey` types and their `EnvironmentValues` extension             │
// │   3. plain value types you want usable from any thread                          │
// └────────────────────────────────────────────────────────────────────────────────┘
//
// ┌─ IMPORT RULE ──────────────────────────────────────────────────────────────────┐
// │ Tokens are NOT re-exported from here. Every file — in this package and in apps  │
// │ that use it — imports what it uses:                                             │
// │       import TrembusTokens                                                      │
// │       import TrembusUI                                                          │
// │ Why: see `strictImports` in Package.swift (a re-export once hid a dependency    │
// │ from the incremental build and produced a segfault).                            │
// └────────────────────────────────────────────────────────────────────────────────┘
