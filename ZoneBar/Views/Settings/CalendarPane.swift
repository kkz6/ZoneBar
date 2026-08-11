import SwiftUI

struct CalendarPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(CalendarEventService.self) private var calendarService

    var body: some View {
        @Bindable var settings = settings

        SettingsPane(section: SettingsSection.calendar) {
            SettingsGroup {
                SettingRow(
                    icon: "calendar",
                    iconColor: .blue,
                    title: "Calendar access",
                    subtitle: accessDescription
                ) {
                    accessControl
                }

                SettingsDivider()

                SettingRow(
                    title: "Show events on timeline",
                    subtitle: "Show timed events while comparing."
                ) {
                    Toggle("", isOn: $settings.showCalendarEvents)
                        .settingsToggle()
                        .disabled(!calendarService.accessState.canReadEvents)
                }
            }

            SettingsNote(
                text: "ZoneBar only reads event times and titles on this Mac. It never edits your calendar."
            )

            if let error = calendarService.lastError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: calendarService.accessState) { _, state in
            if !state.canReadEvents {
                settings.showCalendarEvents = false
            }
        }
    }

    @ViewBuilder
    private var accessControl: some View {
        switch calendarService.accessState {
        case .connected:
            Button("Privacy Settings") {
                calendarService.openPrivacySettings()
            }
            .controlSize(.small)

        case .notDetermined:
            Button("Connect") {
                Task {
                    if await calendarService.requestAccess() {
                        settings.showCalendarEvents = true
                    }
                }
            }
            .controlSize(.small)
            .disabled(calendarService.isRequestingAccess)

        case .denied, .restricted, .writeOnly:
            Button("Open Settings") {
                calendarService.openPrivacySettings()
            }
            .controlSize(.small)
        }
    }

    private var accessDescription: LocalizedStringKey {
        switch calendarService.accessState {
        case .notDetermined: "Not connected"
        case .connected: "Connected"
        case .denied: "Access denied"
        case .restricted: "Access restricted"
        case .writeOnly: "Read access required"
        }
    }
}

#if DEBUG
#Preview("Calendar") {
    CalendarPane()
        .settingsPreviewEnvironment()
        .frame(width: 400, height: 520, alignment: .top)
}
#endif
