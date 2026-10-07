import SwiftUI

struct ClocksPane: View {
    @Environment(ClockStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(TimeTicker.self) private var ticker
    @Environment(FocusClockFilter.self) private var focusFilter

    @State private var dragSession = ClockDragSession()

    var body: some View {
        SettingsPane(section: SettingsSection.clocks) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                SectionHeader(title: "Add a city")
                CitySearchView()
            }

            if store.clocks.isEmpty {
                emptyState
            } else {
                SettingsGroup(header: "Your clocks") {
                    VStack(spacing: 0) {
                        ForEach(Array(store.clocks.enumerated()), id: \.element.id) { index, clock in
                            ClockManageRow(clock: clock, now: ticker.now, settings: settings, store: store, dragSession: dragSession)
                                .clockReordering(clock: clock, store: store, dragSession: dragSession)
                            if index < store.clocks.count - 1 {
                                SettingsDivider()
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                }

                SettingsNote(
                    text: "Toggle the switch to show a clock in the menu bar. Hover over a row and drag its handle to reorder."
                )
                if focusFilter.isFiltering {
                    SettingsNote(text: "A Focus filter controls the menu bar right now. These switches update your normal selection.")
                }
            }
        }
        .onDisappear { dragSession.finish() }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("No clocks yet")
                .font(.system(size: 14, weight: .medium))
            Text("Search above to add your first city.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

private struct ClockManageRow: View {
    let clock: WorldClock
    let now: Date
    let settings: AppSettings
    let store: ClockStore
    let dragSession: ClockDragSession

    @State private var name = ""
    @State private var isHovering = false
    @FocusState private var focused: Bool

    var body: some View {
        let day = clock.isDaytime(at: now)
        HStack(spacing: DS.Spacing.md) {
            ClockReorderTile(
                clock: clock, store: store, dragSession: dragSession,
                symbol: day ? "sun.max.fill" : "moon.fill",
                color: day ? .orange : .indigo,
                isHovering: isHovering
            )

            VStack(alignment: .leading, spacing: 2) {
                TextField("City name", text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .focused($focused)
                    .onSubmit(commit)
                    .onChange(of: focused) { _, isFocused in
                        if !isFocused { commit() }
                    }
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: DS.Spacing.md)

            if isHovering {
                Button {
                    store.removeClock(id: clock.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Remove clock")
            } else {
                Text(
                    clock.formattedTime(
                        at: now,
                        is24Hour: settings.is24Hour,
                        locale: settings.locale
                    )
                )
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Toggle("", isOn: Binding(
                get: {
                    store.clocks.first(where: { $0.id == clock.id })?
                        .showInMenuBar ?? false
                },
                set: { store.setMenuBarVisibility(id: clock.id, visible: $0) }
            ))
            .settingsToggle()
            .help("Show in menu bar")
        }
        .padding(.horizontal, SettingsLayout.cardHorizontalInset)
        .frame(minHeight: DS.Size.rowHeight)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onAppear { name = clock.name }
    }

    private var subtitle: String {
        [clock.country, clock.gmtOffsetString].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func commit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            name = clock.name
        } else if trimmed != clock.name {
            store.renameClock(id: clock.id, name: trimmed)
        }
    }
}

#if DEBUG
#Preview("Clocks") {
    ClocksPane()
        .settingsPreviewEnvironment()
        .frame(width: 400, height: 520, alignment: .top)
}
#endif
