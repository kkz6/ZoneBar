# Architecture

ZoneBar is a pure SwiftUI macOS menu bar app, built with the Observation
framework (`@Observable`). This document covers key architectural decisions and
patterns.

## Overview

```
┌──────────────────────────────────────────────────────┐
│                      ZoneBarApp                         │
│  ┌────────────────────┐   ┌────────────────────────┐  │
│  │   MenuBarExtra      │   │   Settings Scene        │  │
│  │   (.window)         │   │   (hidden title bar)    │  │
│  │                     │   │                         │  │
│  │  MenuBarLabel       │   │  SettingsWindow         │  │
│  │  ClockPopover       │   │  ├─ custom sidebar      │  │
│  │  ├─ ClockRow        │   │  ├─ GeneralPane         │  │
│  │  ├─ TimeScrubberView│   │  ├─ MenuBarPane         │  │
│  │  └─ CitySearchView  │   │  ├─ ClocksPane          │  │
│  │                     │   │  ├─ AppearancePane      │  │
│  │                     │   │  └─ AboutPane           │  │
│  └─────────┬───────────┘   └───────────┬────────────┘  │
│            │     environment objects    │               │
│  ┌─────────▼────────────────────────────▼───────────┐  │
│  │                  Service Layer                      │  │
│  │  ClockStore     @Observable  clocks + JSON CRUD    │  │
│  │  AppSettings    @Observable  UserDefaults-backed   │  │
│  │  TimeTicker     @Observable  minute-aligned `now`  │  │
│  │  MenuBarRenderer  pure  (clocks, settings) → text  │  │
│  │  LaunchAtLogin    SMAppService wrapper             │  │
│  └────────────────────────────────────────────────────┘  │
│                                                            │
│  DesignSystem: IconTile · SettingsCard · SettingRow …      │
└──────────────────────────────────────────────────────┘
```

The old monolithic `ClockManager` has been decomposed into focused, single-
responsibility services. Pure logic (`MenuBarRenderer`, `WorldClock`
formatting) is unit-tested in the `ZoneBarTests` target.

## App Lifecycle

ZoneBar is an **accessory app** (`LSUIElement = true`), meaning it has no dock icon and lives entirely in the menu bar. The app uses two SwiftUI scenes:

1. **MenuBarExtra** (`.window` style) -- The main popover shown when clicking the menu bar item
2. **Window** (`.hiddenTitleBar`) -- The settings window, opened via `openWindow` from the popover gear (or ⌘,). The hidden title bar lets the custom sidebar run to the top with the traffic lights overlaid, matching the reference design.

## State Management

State is split across three `@Observable` services, owned by `ZoneBarApp` as
`@State` and injected into both scenes via `.environment(...)`:

```
ClockStore (@Observable)
└── clocks: [WorldClock]   ← persisted to JSON, all CRUD lives here

AppSettings (@Observable)
└── is24Hour, showDate, compactMode, showDayNightIcon,
    separatorStyle, theme   ← each backed by UserDefaults via didSet

TimeTicker (@Observable)
└── now: Date   ← minute-aligned; views observing `now` re-render each minute
```

`MenuBarRenderer` and `LaunchAtLogin` are stateless helpers (an enum each).
The time-scrubber offset is **transient popover state** (`@State` in
`ClockPopover`, reset when the popover closes): it shifts the previewed time in
the clock rows only and never affects the menu bar.

**Persistence:** Clocks are encoded as JSON and written to
`~/Library/Application Support/ZoneBar/clocks.json`. Settings live in
`UserDefaults`.

**Timer:** `TimeTicker` calculates seconds until the next minute boundary for
its first fire, then repeats every 60 seconds — no drift. `WorldClock`'s
formatting methods take the `now` value explicitly, which both ties rendering to
the ticker and makes them pure/testable.

## Data Flow

```
ZoneBarApp
├── @State store    = ClockStore()
├── @State settings = AppSettings()
├── @State ticker   = TimeTicker()
│
├── MenuBarLabel ← MenuBarRenderer.text(store, settings, ticker.now)
├── ClockPopover ← @Environment(ClockStore/AppSettings/TimeTicker)
│   ├── ClockRow          ← reads clock + (ticker.now + scrubber offset)
│   ├── TimeScrubberView  ← reads/writes local offset binding
│   └── CitySearchView    ← store.addClock()
│
└── SettingsWindow ← @Environment(...) ; panes use @Bindable bindings
```

## City Search

The hybrid search approach combines two data sources:

1. **Bundled `cities.json`** -- 176 major cities with population-based ranking. Searched with case-insensitive substring match on name and aliases.
2. **Apple `TimeZone.knownTimeZoneIdentifiers`** -- ~400 IANA timezone identifiers as fallback. Catches cities not in the bundled database.

Results are merged (deduplicated by timezone identifier), limited to 10 results, and sorted by population descending.

## WorldClock Model

Each clock stores its IANA timezone identifier and computes display values on demand:

```swift
struct WorldClock: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String         // Editable display name
    var country: String      // Country code (e.g., "US")
    var timezone: String     // IANA identifier (e.g., "America/New_York")
    var showInMenuBar: Bool
    var sortOrder: Int
}
```

Time formatting, day/night detection, compact names, and relative day labels are
methods on the model that take an explicit `now: Date`. This keeps view code thin
and the logic pure (no hidden `Date()` calls), so it can be unit-tested.

## Design System

`DesignSystem.swift` defines the shared visual language used by both the popover
and the settings window:

- `IconTile` — SF Symbol on a rounded, tinted gradient square.
- `SettingsCard` — grouped card that lays children out as rows split by hairline
  dividers (via `_VariadicView`).
- `SettingRow` — icon + title/subtitle + trailing control.
- `SectionHeader`, `SettingsGroup`, `SettingsPane` — section scaffolding.
- `DS` — spacing, radius, and size tokens.

Toggles use the native switch style tinted with the macOS system accent colour.

## Testing

The `ZoneBarTests` target (Swift Testing) covers the pure logic: `MenuBarRenderer`
output across formats/separators/visibility, and `WorldClock` formatting, day/
night, working-hours, compact-name, and GMT-offset computations. Tests pin a
fixed `Date`, so they are deterministic regardless of wall-clock time.

## Known Limitations

### MenuBarExtra `.window` Style

1. **No programmatic dismiss** -- The popover can't be closed from code. Users click outside to dismiss.
2. **Settings window activation** -- Opened via `SettingsLink` from the popover footer (works on macOS 14+).
3. **Menu bar highlight** -- The status item doesn't maintain highlight while the popover is open.

### Sandbox Constraints

The app runs in App Sandbox. This means:
- No access to arbitrary files
- No network access (city data is fully bundled)

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Pure SwiftUI (no AppKit views) | Simpler codebase, automatic dark mode, widget reuse potential |
| `@Observable` services via environment | Decoupled, single-responsibility state; no global singletons |
| Pure `MenuBarRenderer` / formatting | Unit-testable logic isolated from UI and global state |
| File-system-synchronized project group | New Swift files are picked up automatically — no pbxproj churn |
| JSON file for clocks | More flexible than UserDefaults for ordered arrays; easy to debug |
| Bundled city data | No network dependency; works offline; instant search |
| Minute-aligned timer | Prevents time display drift that fixed-interval timers cause |
| LSUIElement = true | Menu bar apps shouldn't appear in the dock |
