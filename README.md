# ZoneBar

A lightweight native macOS menu bar app for tracking world clocks. Built with pure SwiftUI, targeting macOS 14+ (Sonoma).

ZoneBar replaces heavy Electron-based world clock apps with a fast, native experience that integrates deeply with macOS -- system appearance, launch at login, and more.

## Features

### World Clocks
- Add clocks by searching 176+ cities across 124 timezones
- Day/night indicators with sun and moon icons
- Relative day labels (Tomorrow, Yesterday)
- Per-clock GMT offset display
- Drag-and-drop reordering, inline rename, and delete from the Clocks settings
- Toggle which clocks appear in the menu bar

### Streamlined Popover
- Clean, glanceable clock rows with day/night icon, GMT offset, and large time
- Whole-row scrolling list (no clipped rows) that scrolls past six clocks
- **Time scrubber** — drag the bar to compare what time it is across every clock,
  with a green "match" dot when all zones are in working hours, and a Now reset
- Quick-add a city inline with the **+** button
- Settings and quit in the footer

### Menu Bar
- Displays selected clock times directly in the macOS menu bar
- Compact mode abbreviates city names (New York → NY)
- Optional date and day/night (☀/☾) prefixes
- Configurable separator between clocks
- 12-hour or 24-hour time format
- Falls back to a clock icon when no clocks are selected for display

### Settings (sidebar window)
- **General:** time format, date display, launch at login
- **Menu Bar:** compact names, day/night icon, separator, live preview
- **Clocks:** add, reorder, rename, delete, and choose menu-bar visibility
- **Appearance:** System, Light, or Dark theme (accent follows macOS)
- **About:** version and links

### System Integration
- Pure menu bar app (no dock icon)
- Launch at login via SMAppService
- Signed automatic updates and manual update checks via Sparkle
- Respects system dark/light mode
- App sandbox
- Hardened runtime and direct-download distribution support

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.0 or later (for building; the project uses file-system-synchronized groups)

## Getting Started

### Build from Source

```bash
git clone https://github.com/kkz6/ZoneBar.git
cd ZoneBar
open ZoneBar.xcodeproj
```

Then press **Cmd+R** in Xcode to build and run.

### First Launch

On first launch, ZoneBar detects your local timezone and adds it along with UTC as default clocks. Use the search field in the popover to add more cities.

## Project Structure

```
ZoneBar/
├── ZoneBarApp.swift              # App entry point, MenuBarExtra + Settings
├── DesignSystem/
│   ├── DesignSystem.swift        # Reusable controls and visual tokens
│   └── SettingsLayout.swift      # Reusable settings-window framework
├── Models/
│   ├── WorldClock.swift          # Clock model, time formatting, day/night logic
│   └── CityDatabase.swift        # Hybrid city search (bundled JSON + Apple API)
├── Views/
│   ├── ClockPopover.swift        # Main popover and clock rows
│   ├── TimeScrubberView.swift    # Cross-timezone time preview
│   ├── CitySearchView.swift      # City search and add
│   ├── Settings/                 # Settings shell and five panes
│   └── MenuBarLabel.swift        # Dynamic menu bar label
├── Services/
│   ├── ClockStore.swift          # Clock persistence and CRUD
│   ├── AppSettings.swift         # UserDefaults-backed preferences
│   └── TimeTicker.swift          # Minute-aligned clock updates
└── Resources/
    └── cities.json               # 176 cities, 124 timezones, all continents
```

## Architecture

- **Pure SwiftUI** with `MenuBarExtra` (`.window` style)
- **State management:** Observation (`@Observable`) with environment injection
- **Persistence:** JSON file for clocks, UserDefaults for settings
- **Timer:** Minute-boundary aligned for accurate clock updates
- **Updates:** Sparkle appcast generated and Ed25519-signed by the release workflow
- **City data:** Hybrid approach -- bundled city database + Apple `TimeZone` API fallback

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for the full feature roadmap, organized into phases:

- **Phase 2:** Widgets, keyboard shortcuts, Spotlight/Shortcuts integration
- **Phase 3:** Calendar deep integration, best meeting time finder
- **Phase 4:** Focus timer, quick time converter, travel mode
- **Phase 5:** iCloud sync, iOS app, watchOS complication

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

MIT
