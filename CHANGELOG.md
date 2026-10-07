# Changelog

All notable changes to ZoneBar will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Native Focus filters for selecting the clocks shown in the menu bar and dropdown
- Focus settings with setup guidance, active-filter status, and a temporary Show all option
- Restore normal clock visibility when the Focus filter ends without changing saved selections
- Reorder and compare the clocks shown by a Focus filter
- English and Japanese Focus interface text

## [0.4.1] - Unreleased

### Changed
- Keep settings section headers fixed while their content scrolls underneath
- Show a translucent header background on scroll, with full coverage through
  the header midpoint and a soft fade to transparent below
- Animate the header background and respect Reduce Motion
- Use native macOS traffic lights with Close enabled and Minimize and Zoom disabled
- Remove the docs folder and update README and contributing links

## [0.4.0] - 2026-10-07

### Added
- Hover-revealed drag handles for reordering clocks in the menu bar dropdown and
  Clocks settings
- In-place row dragging with animated neighboring rows and snap-to-position
  transitions that respect Reduce Motion
- Accessible actions for moving clocks up and down

### Fixed
- Keep clock ordering synchronized with the menu bar and saved across restarts
- Preserve day/night tile colors while showing the drag handle
- Clip dragged settings rows to the card's rounded border

## [0.3.0] - 2026-08-11

### Added
- Optional macOS Calendar connection with explicit full-access permission
- Blue timed-event ranges on the comparison scrubber and active event details
- Clickable event details that open the selected event in macOS Calendar
- A subtle, Reduce Motion-aware menu panel presentation animation
- English and Japanese Calendar permission and interface text

### Fixed
- Move Settings frame sizing and close-only traffic lights under one reusable
  AppKit window controller, preventing resizing, split control alignment, and
  transparent overflow below the SwiftUI content

## [0.2.3] - 2026-07-27

### Added
- Complete English and Japanese interface localization
- Automatic language detection based on macOS settings
- An in-app language selector for Automatic, English, and Japanese

### Changed
- Localize dates, time formatting, relative-day labels, settings, tooltips,
  and accessibility text
- Extend reusable settings components for future languages

## [0.2.2] - 2026-07-27

### Changed
- Build releases with macOS 26 and Xcode 26.5 to match local SDK styling
- Added more top spacing to the DMG installation artwork
- Open the DMG layout in a dedicated Finder window when generating releases

### Fixed
- Keep Settings in accessory-app mode so opening it does not restyle the
  menu-bar popover
- Activate the Settings window after creation without changing the process-wide
  application policy

## [0.2.1] - 2026-07-27

### Added
- User-controlled automatic update checks in About settings
- Curated compact abbreviations for bundled cities

### Fixed
- Made the first manual update check wait until Sparkle is ready
- Corrected settings traffic-light hover and click targets
- Kept disabled minimize and zoom indicators free of hover glyphs
- Migrated existing clocks to their curated compact abbreviations

## [0.2.0] - 2026-07-27

### Added
- Secure automatic update checks and installation through Sparkle
- Manual “Check for Updates…” actions in Settings and the application menu
- Signed appcast generation for every GitHub release

### Changed
- Refined settings spacing, alignment, typography, and rounded surfaces
- Redesigned the DMG installation window
- Improved release build numbering and reproducibility

### Fixed
- Prevented redundant launch-at-login registration
- Restored native menu bar popover borders across display scales
- Removed settings window layout recursion and inconsistent window controls

## [0.1.0] - 2026-07-27

### Added
- Multiple world clocks with add, remove, reorder, and inline rename
- City search across 176 cities and 124 timezones with Apple TimeZone API fallback
- Day/night indicators (sun/moon icons) and relative day labels
- Menu bar display with selected clock times
- Compact mode for abbreviated city names
- 12-hour and 24-hour time format toggle
- Date display option in menu bar
- Interactive time scrubber to preview times across all zones
- Working hours overlap indicator on the time slider
- Reusable sidebar settings window with General, Clocks, Menu Bar, Appearance,
  and About sections
- Launch at login via SMAppService
- System/Light/Dark appearance modes
- Automatic local timezone detection on first launch
- JSON-based clock persistence
- App sandbox
- Xcode previews and visual regression tests for the settings interface
- Automated GitHub release workflow for signed and notarized DMG artifacts
