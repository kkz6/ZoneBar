# Design Spec

Original design spec for the WorldTick rewrite from Hovrly (Electron) to native Swift.

## Background

WorldTick is the successor to [Hovrly](https://hovrly.com), an Electron-based menubar world clock app (v2.4.5). The rewrite was motivated by:

1. **Performance** -- Electron apps are ~200MB and memory-heavy. WorldTick targets <20MB.
2. **Native integration** -- Deep macOS features: Widgets, Shortcuts, calendar, notifications.
3. **App Store distribution** -- Sandboxed, signed, notarized for the Mac App Store.

## Design Decisions

### Why Pure SwiftUI (no AppKit)?

We evaluated three approaches:

| Approach | Pros | Cons |
|----------|------|------|
| **SwiftUI + AppKit hybrid** | Full control over NSStatusItem/NSPopover | More boilerplate, AppKit knowledge required |
| **Pure AppKit** | Maximum pixel control | Significantly more code, no widget reuse |
| **Pure SwiftUI with MenuBarExtra** | Cleanest code, modern, zero AppKit | Less control over popover behavior |

**Chosen: Pure SwiftUI with MenuBarExtra.** The simplicity and maintainability outweigh the control tradeoffs, especially for a v1 where iteration speed matters.

### Why Hybrid City Data?

The original Hovrly used a remote MySQL database for city search. This had problems:
- Required network connectivity
- Added latency to every search
- Single point of failure (db.hovrly.com)

WorldTick bundles a `cities.json` with 176 major cities and falls back to Apple's `TimeZone.knownTimeZoneIdentifiers` for cities not in the database. This gives:
- Instant, offline search
- Zero external dependencies
- Reasonable coverage (176 cities cover all major timezones)

### Why EventKit for Meeting Awareness?

Meeting awareness was identified as the key differentiator over the original Hovrly. EventKit provides:
- Read access to all calendars (with permission)
- Real-time notifications when events change
- Works with iCloud, Google, Exchange, and local calendars
- Sandboxed access via entitlement

### Why No Data Migration from Hovrly?

Hovrly stores settings via `electron-settings` in `~/Library/Application Support/Hovrly/Settings`. We chose not to build a migration tool for v1 because:
- WorldTick is a fresh brand with a new target audience
- City search makes re-adding 3-5 clocks trivial (<30 seconds)
- The settings format is different enough that mapping is non-trivial
- Users installing from the App Store likely haven't used Hovrly

A migration tool can be added in Phase 2 if demand arises.

## Known Platform Limitations

### MenuBarExtra `.window` Style

1. **No programmatic dismiss.** The popover can't be closed from within its content. Users click outside to dismiss. Acceptable for v1.
2. **Settings window from MenuBarExtra.** `SettingsLink` has historically been unreliable from MenuBarExtra context. macOS 14 improved this significantly. For older OS workarounds, the [SettingsAccess](https://github.com/orchetect/SettingsAccess) library is available.
3. **Menu bar highlight.** The status item doesn't maintain highlight while the popover is open. Cosmetic issue with no current workaround.

### App Sandbox

The sandbox limits what the app can access:
- Calendar: Requires `com.apple.security.personal-information.calendars` entitlement
- No network access needed (city data is bundled)
- File access limited to app container

## Error Handling Strategy

| Scenario | Behavior |
|----------|----------|
| EventKit permission denied | Show inline message with link to System Settings. Hide meeting UI. |
| cities.json fails to load | Fall back to Apple TimeZone identifiers only. Search still works. |
| Clock list JSON corrupted | Reset to defaults (local timezone + UTC). Log error. |
| Invalid timezone identifier | Show "--:--" for time. Clock remains functional. |
