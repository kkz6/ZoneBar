# Timely

A lightweight native macOS menu bar app for tracking world clocks with meeting awareness. Built with pure SwiftUI, targeting macOS 14+ (Sonoma).

Timely replaces heavy Electron-based world clock apps with a fast, native experience that integrates deeply with macOS -- calendar events, system appearance, launch at login, and more.

## Features

### World Clocks
- Add clocks by searching 176+ cities across 124 timezones
- Day/night indicators with sun and moon icons
- Relative day labels (Today, Tomorrow, Yesterday)
- Inline rename by double-clicking the city name
- Drag-and-drop reordering
- Swipe or hover to delete
- Toggle which clocks appear in the menu bar

### Menu Bar
- Displays selected clock times directly in the macOS menu bar
- Compact mode abbreviates city names (New York → NY)
- Optional date display
- 12-hour or 24-hour time format
- Falls back to a clock icon when no clocks are selected for display

### Time Slider
- Preview what time it will be across all zones at any point in the day
- Working hours overlap indicator (green when all zones are within 9–5)
- Snap back to "Now" with one click

### Meeting Awareness
- Calendar integration via EventKit
- Next meeting countdown badge in the popover
- Upcoming meeting time shown in every clock's timezone
- Permission request with graceful fallback when calendar access is denied

### Settings
- **General:** 12/24hr format, date display, compact mode, launch at login
- **Appearance:** System, Light, or Dark theme
- **About:** Version info

### System Integration
- Pure menu bar app (no dock icon)
- Launch at login via SMAppService
- Respects system dark/light mode
- App sandbox with calendar entitlement
- Ready for Mac App Store distribution

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (for building)

## Getting Started

### Build from Source

```bash
git clone https://github.com/kkz6/Timely.git
cd Timely
open Timely.xcodeproj
```

Then press **Cmd+R** in Xcode to build and run.

### First Launch

On first launch, Timely detects your local timezone and adds it along with UTC as default clocks. Use the search field in the popover to add more cities.

## Project Structure

```
Timely/
├── TimelyApp.swift              # App entry point, MenuBarExtra + Settings
├── Models/
│   ├── WorldClock.swift          # Clock model, time formatting, day/night logic
│   └── CityDatabase.swift        # Hybrid city search (bundled JSON + Apple API)
├── Views/
│   ├── ClockListView.swift       # Main popover content
│   ├── ClockRowView.swift        # Individual clock row
│   ├── TimeSliderView.swift      # Time preview slider
│   ├── CitySearchView.swift      # City search and add
│   ├── SettingsView.swift        # Settings window (3 tabs)
│   └── MenuBarLabel.swift        # Dynamic menu bar label
├── Services/
│   ├── ClockManager.swift        # Central state manager, persistence, timer
│   └── CalendarService.swift     # EventKit calendar integration
└── Resources/
    └── cities.json               # 176 cities, 124 timezones, all continents
```

## Architecture

- **Pure SwiftUI** with `MenuBarExtra` (`.window` style)
- **State management:** `ObservableObject` + `@Published` + `@AppStorage`
- **Persistence:** JSON file for clocks, UserDefaults for settings
- **Timer:** Minute-boundary aligned for accurate clock updates
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
