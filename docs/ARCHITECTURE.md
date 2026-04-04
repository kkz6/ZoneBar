# Architecture

WorldTick is a pure SwiftUI macOS menu bar app. This document covers key architectural decisions and patterns.

## Overview

```
┌─────────────────────────────────────────────────┐
│                  WorldTickApp                       │
│  ┌──────────────────┐  ┌─────────────────────┐  │
│  │   MenuBarExtra    │  │   Settings Scene     │  │
│  │   (.window)       │  │   (SwiftUI Window)   │  │
│  │                   │  │                      │  │
│  │  ClockListView    │  │  SettingsView        │  │
│  │  ├─ ClockRowView  │  │  ├─ GeneralSettings  │  │
│  │  ├─ TimeSlider    │  │  ├─ Appearance       │  │
│  │  ├─ CitySearch    │  │  └─ About            │  │
│  │  └─ Footer        │  │                      │  │
│  └────────┬─────────┘  └──────────┬───────────┘  │
│           │                       │               │
│  ┌────────▼───────────────────────▼───────────┐  │
│  │          Shared State Layer                  │  │
│  │  ┌─────────────────┐  ┌──────────────────┐  │  │
│  │  │  ClockManager   │  │ CalendarService  │  │  │
│  │  │  (Observable)   │  │  (Observable)    │  │  │
│  │  └────────┬────────┘  └────────┬─────────┘  │  │
│  │           │                    │             │  │
│  │  ┌────────▼────────┐  ┌───────▼──────────┐  │  │
│  │  │   JSON File     │  │    EventKit      │  │  │
│  │  │   (clocks)      │  │    (calendar)    │  │  │
│  │  └─────────────────┘  └──────────────────┘  │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## App Lifecycle

WorldTick is an **accessory app** (`LSUIElement = true`), meaning it has no dock icon and lives entirely in the menu bar. The app uses two SwiftUI scenes:

1. **MenuBarExtra** (`.window` style) -- The main popover shown when clicking the menu bar item
2. **Settings** -- A standard macOS settings window opened from the popover footer

## State Management

### ClockManager

The central state object. Owns the clock list, slider offset, and user preferences.

```
ClockManager (ObservableObject, singleton)
├── @Published clocks: [WorldClock]       ← persisted to JSON
├── @Published sliderOffset: TimeInterval ← transient
├── @Published isSliderActive: Bool       ← transient
├── @AppStorage is24Hour, showDate, compactMode ← UserDefaults
└── Timer (aligned to minute boundary)    ← triggers objectWillChange
```

**Persistence:** Clocks are encoded as JSON and written to `~/Library/Application Support/WorldTick/clocks.json`. Settings use `@AppStorage` (backed by `UserDefaults`).

**Timer:** Rather than a fixed 60-second interval (which drifts), the timer calculates seconds until the next minute boundary for its first fire, then repeats every 60 seconds. This keeps the displayed time accurate to the second.

## Data Flow
Views observe the shared state objects:

```
WorldTickApp
├── @StateObject clockManager = ClockManager.shared
│
├── MenuBarExtra label ← reads clockManager.menuBarText()
├── ClockListView ← observes ClockManager
│   ├── ClockRowView ← reads clock + offset from ClockManager
│   ├── TimeSliderView ← reads/writes sliderOffset on ClockManager
│   └── CitySearchView ← calls clockManager.addClock()
│
└── SettingsView ← reads/writes @AppStorage directly
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

Time formatting, day/night detection, compact names, and relative day labels are computed properties on the model. This keeps view code thin.

## Known Limitations

### MenuBarExtra `.window` Style

1. **No programmatic dismiss** -- The popover can't be closed from code. Users click outside to dismiss.
2. **Settings window activation** -- `SettingsLink` doesn't reliably work from MenuBarExtra context. Current workaround uses the standard `SettingsLink` which works on macOS 14+.
3. **Menu bar highlight** -- The status item doesn't maintain highlight while the popover is open.

### Sandbox Constraints

The app runs in App Sandbox. This means:
- No access to arbitrary files
- No network access (city data is fully bundled)

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Pure SwiftUI (no AppKit) | Simpler codebase, automatic dark mode, widget reuse potential |
| Singleton services | Menu bar apps have a single window; singletons simplify state sharing |
| JSON file for clocks | More flexible than UserDefaults for ordered arrays; easy to debug |
| Bundled city data | No network dependency; works offline; instant search |
| Minute-aligned timer | Prevents time display drift that fixed-interval timers cause |
| LSUIElement = true | Menu bar apps shouldn't appear in the dock |
