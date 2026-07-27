# Changelog

All notable changes to ZoneBar will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
