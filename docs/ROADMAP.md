# Roadmap

Feature roadmap for WorldTick, organized by phase. Each phase builds on the previous one.

## Phase 1 -- Core (v1.0) :white_check_mark:

The foundation. A working menu bar world clock app with meeting awareness.

- [x] Multiple world clocks (add, remove, reorder, rename)
- [x] City search with 176 cities across 124 timezones
- [x] Day/night indicators and relative day labels
- [x] Menu bar display with selected clock times
- [x] Compact mode for abbreviated names
- [x] 12/24 hour time format toggle
- [x] Date display option
- [x] Interactive time slider with working hours overlap
- [x] Calendar integration (next meeting, multi-timezone display)
- [x] Settings window (General, Appearance, About)
- [x] Launch at login
- [x] System/Light/Dark appearance

## Phase 2 -- Polish & Productivity

Refining the experience and adding power-user features.

- [ ] **macOS Widgets (WidgetKit)** -- Show selected clocks on the desktop and in Notification Center. Reuse SwiftUI clock views for consistency.
- [ ] **Global keyboard shortcut** -- Configurable hotkey to toggle the popover open/closed. Arrow key navigation within the clock list.
- [ ] **Custom working hours per clock** -- Override the default 9-5 per timezone. Useful for colleagues with non-standard schedules.
- [ ] **Timezone abbreviation display** -- Option to show PST, EST, CET alongside or instead of city names.
- [ ] **Spotlight & Shortcuts integration** -- "What time is it in Tokyo?" via Siri and the Shortcuts app. Uses the App Intents framework.
- [ ] **App icon** -- Custom app icon for the dock (when Settings is open) and App Store listing.

## Phase 3 -- Calendar Deep Integration

Making WorldTick the go-to tool for scheduling across timezones.

- [ ] **Inline calendar events** -- Show today's events beneath each clock, converted to that clock's timezone.
- [ ] **Best meeting time finder** -- Algorithm to find optimal meeting times where all selected timezones overlap within working hours. Visual display of overlap windows.
- [ ] **Meeting countdown in menu bar** -- Option to show "Meeting in 12m" in the menu bar label alongside clock times.
- [ ] **Calendar event creation** -- Create events directly from WorldTick with automatic timezone conversion for attendees in different zones.

## Phase 4 -- Personal Productivity

Tools for individuals working across timezones daily.

- [ ] **Focus timer / Pomodoro** -- Start a 25-minute focus session that shows the end time in all configured zones. Optional break reminders.
- [ ] **Do Not Disturb hours** -- Mark off-hours per clock. Grey out clocks outside working hours for a quick visual scan of who's available now.
- [ ] **Quick time converter** -- Type "3pm NYC" in the search field to instantly see that time in all other zones. Natural language input.
- [ ] **Date/time math** -- Queries like "What's 3 hours from now in London?" with results shown inline.
- [ ] **Travel mode** -- Temporarily set "I'm currently in X" to shift your local time reference without removing your home timezone clock.

## Phase 5 -- Platform Expansion

Taking WorldTick beyond a single Mac.

- [ ] **iCloud sync** -- Sync clock configurations and settings across multiple Macs via CloudKit. Shared App Group container.
- [ ] **iOS companion app** -- iPhone app with the same clock list, synced via iCloud.
- [ ] **watchOS complication** -- Show a key timezone on your Apple Watch face.
- [ ] **Share configurations** -- Export/import clock sets as files. Presets like "US West Coast Team" or "APAC Partners."

---

## Suggesting Features

Have an idea that's not on this list? Open an issue describing the feature and its use case. Bonus points if you explain why it matters for people working across timezones.
