# ZoneBar Revamp — Design

Date: 2026-06-22

A full visual revamp plus an internals refactor of ZoneBar, the pure-SwiftUI
macOS menu-bar world-clock app. No AppKit — SwiftUI everything.

## Decisions

- **Scope:** Redesign + polish internals (no major new features).
- **Settings nav:** General, Menu Bar, Clocks, Appearance, About.
- **Accent:** Respect the macOS system accent color.
- **Popover:** Streamlined — clean read-only clock rows + collapsible time slider.
- **Settings window:** Custom sidebar window via SwiftUI `NavigationSplitView`.
- **Tech:** Pure SwiftUI, Observation framework (`@Observable`), macOS 14+.

## 1. Internals refactor

Split the `ClockManager` god-object into focused, testable pieces:

```
Services/
  ClockStore.swift      owns [WorldClock], CRUD, JSON persistence, reindex
  TimeTicker.swift      minute-aligned timer, publishes `now`
  AppSettings.swift     @Observable wrapper over all @AppStorage keys
  LaunchAtLogin.swift   SMAppService wrapper (no UI)
  MenuBarRenderer.swift pure (clocks, settings, now) -> String
Models/
  WorldClock.swift      data + formatting helpers
  AppTheme.swift        appearance mode -> ColorScheme
```

- `AppSettings` injected via environment; single home for menu-bar options.
- Slider state (`offset`, `isActive`) becomes a popover-scoped `@Observable` view model.
- Same JSON persistence format — refactor, not rewrite.

## 2. Design system (`DesignSystem.swift`)

- Grouped cards: `RoundedRectangle(cornerRadius: 10)` over `.background.secondary`,
  rows split by thin dividers.
- `SettingRow`: optional `IconTile`, title, optional subtitle, trailing control.
- `IconTile(symbol:, color:)`: SF Symbol on rounded gradient square.
- Section headers: small secondary labels above card groups.
- Native `Toggle(.switch).tint(.accentColor)` — respects system accent.
- Spacing/typography/corner-radius constants for consistency.
- `.regularMaterial` backgrounds for the translucent macOS look.

## 3. Settings window

`NavigationSplitView` in the `Settings` scene. Sidebar (~215pt) is a
`List(.sidebar)` bound to a `SettingsSection` enum with colored `IconTile`s.
Detail = scrollable stack of card groups with a large titled header.

Panes:
- **General:** launch at login, time format (12/24), show date, show seconds.
- **Menu Bar:** compact names, separator style, day/night icon, live preview row.
- **Clocks:** editable list — add (search), reorder (drag), delete, rename,
  per-clock "show in menu bar" toggle. Moved out of the popover.
- **Appearance:** theme (System/Light/Dark) segmented picker.
- **About:** icon, name, version/build, links.

Window ~720×560.

## 4. Streamlined popover

```
Header: title · settings button · quick-add
Clock rows (read-only): day/night tile · name + GMT offset · time · relative-day pill
Collapsible time slider: slider + working-hours indicator + Now reset (collapsed default)
Footer: only when slider active
```

Management lives in Settings → Clocks; popover is for glancing + planning.

## 5. Build plan

1. Foundation: design system + service split + env wiring.
2. Settings window + 5 panes.
3. Streamlined popover + collapsible slider + quick-add.
4. Unit tests: `MenuBarRenderer`, `WorldClock`/formatting.
5. Build, verify in Xcode, update docs.
