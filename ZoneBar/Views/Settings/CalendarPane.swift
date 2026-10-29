import EventKit
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

            if calendarService.accessState.canReadEvents {
                SettingsGroup(header: "Calendars") {
                    if calendarService.availableCalendars.isEmpty {
                        Text("No calendars found. Add an account in Calendar on this Mac.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(SettingsLayout.cardHorizontalInset)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { calendar in
                                CalendarSelectionRow(calendar: calendar)
                                if calendar.calendarIdentifier != calendarService.availableCalendars.last?.calendarIdentifier {
                                    SettingsDivider()
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                    }
                }

                SettingsNote(text: "Choose which calendars and items appear on the timeline. Uncheck every calendar to hide all items.")
            }

            SettingsNote(
                text: "ZoneBar reads calendar titles, times, and availability on this Mac. It never edits your calendar."
            )

            SettingsNote(
                text: "Unavailable blocks appear separately. Titles containing ‘Out of office’, ‘OOO’, ‘PTO’, or ‘Annual leave’ are recognized automatically. Title matching may not always be accurate."
            )

            if let error = calendarService.lastError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
        }
        .onAppear { calendarService.refreshCalendars() }
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

private struct CalendarSelectionRow: View {
    @Environment(CalendarEventService.self) private var calendarService
    let calendar: EKCalendar

    private var identifier: String { calendar.calendarIdentifier }
    private var isEnabled: Bool { calendarService.isCalendarEnabled(identifier) }
    private var calendarColor: Color { calendar.cgColor.map { Color(cgColor: $0) } ?? .accentColor }

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Toggle(isOn: Binding(
                get: { isEnabled },
                set: { calendarService.setCalendarEnabled(identifier, enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: calendar.title)
                        .font(.system(size: 13))
                        .foregroundStyle(isEnabled ? .primary : .secondary)
                        .lineLimit(1)
                    if let account = calendar.source?.title, !account.isEmpty {
                        Text(verbatim: account)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(CalendarCheckboxStyle(color: calendarColor))
            .help(Text(verbatim: [calendar.title, calendar.source?.title].compactMap { $0 }.joined(separator: "\n")))

            Picker("Calendar items", selection: Binding(
                get: { calendarService.displayMode(for: identifier) },
                set: { calendarService.setDisplayMode($0, for: identifier) }
            )) {
                Text("Both").tag(CalendarDisplayMode.both)
                Text("Events").tag(CalendarDisplayMode.events)
                Text("Unavailable").tag(CalendarDisplayMode.unavailable)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(width: 100)
            .disabled(!isEnabled)
            .accessibilityLabel(Text("Items shown from \(calendar.title)"))
        }
        .padding(.horizontal, SettingsLayout.cardHorizontalInset)
        .frame(minHeight: DS.Size.rowHeight)
    }
}

private struct CalendarCheckboxStyle: ToggleStyle {
    let color: Color

    private var checkmarkColor: Color {
        guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return .white }
        let brightness = 0.2126 * rgb.redComponent + 0.7152 * rgb.greenComponent + 0.0722 * rgb.blueComponent
        return brightness > 0.6 ? .black : .white
    }

    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: DS.Spacing.sm) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(configuration.isOn ? color : Color.secondary.opacity(0.18))
                    .frame(width: 16, height: 16)
                    .overlay {
                        if configuration.isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(checkmarkColor)
                                .shadow(color: .black.opacity(0.3), radius: 1)
                        }
                    }
                    .accessibilityHidden(true)
                configuration.label
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.checkbox)
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
