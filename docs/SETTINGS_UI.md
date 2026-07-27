# Reusable Settings UI

ZoneBar's settings window is built on a small reusable SwiftUI shell. The app
provides destinations and pane content; the shell owns window geometry,
materials, sidebar alignment, titlebar controls, and detail gutters.

## Layout contract

All geometry lives in `SettingsLayout`:

- fixed window and sidebar size;
- sidebar outer and row insets;
- sidebar row height and first-row position;
- detail header height and content gutters;
- spacing between the detail header and groups;
- traffic-light leading edge and vertical center.

The default compact macOS grid uses a 20pt titlebar/sidebar leading line, a
26pt titlebar control center, a 16pt detail gutter, and 14pt between the detail
title row and its first content group. Labelled groups use a 6pt label-to-card
gap, and every card row uses a 12pt internal horizontal inset. Standard rows
are 46pt tall; expanded controls use a 10pt vertical inset.

The titlebar buttons and the detail header use the same vertical center. The
close button and sidebar icons use the same leading grid line. Avoid adding
pane-specific top or horizontal padding; change the shared tokens instead.

Section headers, search fields, cards, and notes all start at the
`detailHorizontalInset` supplied by `SettingsPane`. `SectionHeader` and
`SettingsNote` deliberately add no local horizontal padding. This keeps every
pane on one leading and trailing grid line.

## Add settings to another app

1. Define a hashable destination type conforming to `SettingsDestination`.
2. Create `SettingsSidebarGroup` values for the sidebar.
3. Bind the selection to `SettingsShell`.
4. Return a `SettingsPane` for each destination.
5. Set the app's accent using `.tint(...)`; `settingsToggle()` inherits it.

```swift
enum PreferencesPage: String, Identifiable, SettingsDestination {
    case general, appearance

    var id: String { rawValue }
    // Supply title, SF Symbol name, and semantic Color.
}

struct PreferencesWindow: View {
    @State private var selection = PreferencesPage.general

    private let groups = [
        SettingsSidebarGroup(
            "main",
            destinations: [PreferencesPage.general, .appearance]
        )
    ]

    var body: some View {
        SettingsShell(selection: $selection, groups: groups) { page in
            SettingsPane(section: page) {
                // SettingsGroup, SettingRow, or SegmentedRow
            }
        }
    }
}
```

## Component rules

- `SettingsShell`: window chrome, sidebar, detail scrolling, and materials.
- `SettingsPane`: one aligned detail header and its vertical content stack.
- `SettingsGroup`: optional label plus a divided `SettingsCard`.
- `SettingsDivider`: separator placed explicitly between card rows.
- `SettingRow`: leading text or icon with one trailing control.
- `SegmentedRow`: labelled, full-width choice group.
- `SettingsNote`: supplemental text aligned to the pane gutter.
- `settingsToggle()`: compact native switch inheriting environment tint.

Keep controls keyboard accessible, use SF Symbols by name, and prefer semantic
foreground/background styles so the framework works in light and dark mode.
Use `SettingsLayout.cardHorizontalInset` for custom card rows so they remain
aligned with `SettingRow` and `SegmentedRow`.

## Preview and snapshot workflow

Every settings pane includes an isolated Xcode `#Preview`. Preview fixtures use
temporary clock storage, preview-only user defaults, and a fixed time, so Canvas
does not read or modify the user's ZoneBar data.

Snapshot tests compare rendered screens with approved SHA-256 image fingerprints
in `SnapshotTests.swift`. After an intentional visual change, review the Canvas
and print updated fingerprints with:

```sh
xcodebuild \
  -project ZoneBar.xcodeproj \
  -scheme ZoneBar \
  -destination 'platform=macOS' \
  'OTHER_SWIFT_FLAGS=$(inherited) -D RECORD_SNAPSHOTS' \
  test
```

Copy the reviewed `SNAPSHOT_HASH` values into `approvedHashes`. On a mismatch,
the actual PNG is written to the temporary `zonebar_snapshots` diagnostics
directory.
