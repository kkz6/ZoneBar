import SwiftUI

struct ClocksPane: View {
    @Environment(ClockStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(TimeTicker.self) private var ticker

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
                    ForEach(Array(store.clocks.enumerated()), id: \.element.id) { index, clock in
                        ClockManageRow(clock: clock, now: ticker.now, settings: settings, store: store)
                            .draggable(clock.id.uuidString) {
                                Text(clock.name)
                                    .padding(6)
                                    .background(
                                        .regularMaterial,
                                        in: RoundedRectangle(
                                            cornerRadius: DS.Radius.tile,
                                            style: .continuous
                                        )
                                    )
                            }
                            .dropDestination(for: String.self) { items, _ in
                                reorder(draggedID: items.first, onto: clock)
                            }
                        if index < store.clocks.count - 1 {
                            SettingsDivider()
                        }
                    }
                }

                SettingsNote(
                    text: "Toggle the switch to show a clock in the menu bar. Drag a row to reorder."
                )
            }
        }
    }

    private func reorder(draggedID: String?, onto target: WorldClock) -> Bool {
        guard let draggedID,
              let from = store.clocks.firstIndex(where: { $0.id.uuidString == draggedID }),
              let to = store.clocks.firstIndex(where: { $0.id == target.id }),
              from != to else { return false }
        store.moveClock(from: IndexSet(integer: from), to: to > from ? to + 1 : to)
        return true
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

    @State private var name = ""
    @State private var isHovering = false
    @FocusState private var focused: Bool

    var body: some View {
        let day = clock.isDaytime(at: now)
        HStack(spacing: DS.Spacing.md) {
            IconTile(symbol: day ? "sun.max.fill" : "moon.fill", color: day ? .orange : .indigo)

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
                Text(clock.formattedTime(at: now, is24Hour: settings.is24Hour))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Toggle("", isOn: Binding(
                get: { clock.showInMenuBar },
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
