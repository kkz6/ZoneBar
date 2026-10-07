import SwiftUI

struct FocusPane: View {
    @Environment(ClockStore.self) private var store
    @Environment(FocusClockFilter.self) private var focusFilter

    var body: some View {
        @Bindable var focusFilter = focusFilter
        SettingsPane(section: SettingsSection.focus) {
            SettingsGroup(header: "Focus filters") {
                SettingRow(title: "Follow Focus filters", subtitle: "Switch clocks with your Focus.") {
                    Toggle("", isOn: $focusFilter.followsFocus)
                        .settingsToggle()
                }
            }

            SettingsGroup(header: "Current filter") {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Label(status, systemImage: "moon.fill")
                        .font(.system(size: 13, weight: .medium))
                    if focusFilter.hasConfiguredFilter {
                        let clocks = store.clocks.filter {
                            focusFilter.selectedTimezones?.contains($0.timezone) == true
                        }
                        if clocks.isEmpty {
                            Text("The selected clocks are no longer saved. Update this filter in Focus settings.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(clocks.map(\.name).joined(separator: " · "))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Button {
                            focusFilter.toggleShowAll()
                        } label: {
                            Text(focusFilter.isShowingAll ? LocalizedStringKey("Resume Focus filter") : LocalizedStringKey("Show all clocks"))
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(SettingsLayout.cardHorizontalInset)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            SettingsGroup(header: "Set up") {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    Text("1. Open System Settings → Focus.")
                    Text("2. Choose a Focus, then add a ZoneBar filter.")
                    Text("3. Select the clocks to show for that Focus.")
                    Button("Open Focus Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Focus-Settings.extension")!)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .font(.system(size: 12))
                .padding(SettingsLayout.cardHorizontalInset)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            SettingsNote(text: "Your normal clock selection returns when the Focus filter ends. Showing all clocks temporarily pauses the filter.")
        }
        .task { await focusFilter.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await focusFilter.refresh() }
        }
    }

    private var status: LocalizedStringKey {
        if !focusFilter.followsFocus { return "Focus filtering is turned off" }
        if focusFilter.statusUnavailable { return "Focus status unavailable" }
        if !focusFilter.hasConfiguredFilter { return "No Focus filter active" }
        if focusFilter.isShowingAll { return "Showing all clocks" }
        return "Following Focus clocks"
    }
}

#if DEBUG
#Preview("Focus") {
    FocusPane().settingsPreviewEnvironment().frame(width: 400, height: 520)
}
#endif
