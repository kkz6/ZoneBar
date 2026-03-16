import SwiftUI
import EventKit

struct ClockListView: View {
    @ObservedObject var clockManager: ClockManager
    @ObservedObject var calendarService: CalendarService

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Timely")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if let timeUntil = calendarService.timeUntilNextEvent() {
                    NextMeetingBadge(
                        timeUntil: timeUntil,
                        eventTitle: calendarService.nextEvent?.title ?? "Meeting"
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Date display
            if clockManager.showDate {
                HStack {
                    Text(currentDateString())
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }

            Divider()
                .padding(.horizontal, 12)

            // Clock list
            if clockManager.clocks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("No clocks added")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text("Search for a city below")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(clockManager.clocks) { clock in
                            ClockRowView(
                                clock: clock,
                                offset: clockManager.sliderOffset,
                                is24Hour: clockManager.is24Hour,
                                compact: clockManager.compactMode,
                                onToggleVisibility: {
                                    clockManager.toggleMenuBarVisibility(id: clock.id)
                                },
                                onRename: { newName in
                                    clockManager.renameClock(id: clock.id, name: newName)
                                },
                                onDelete: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        clockManager.removeClock(id: clock.id)
                                    }
                                }
                            )
                        }
                        .onMove { source, destination in
                            clockManager.moveClock(from: source, to: destination)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }

            // Next meeting details
            if calendarService.hasAccess, let event = calendarService.nextEvent {
                Divider()
                    .padding(.horizontal, 12)
                MeetingDetailView(
                    event: event,
                    clocks: clockManager.clocks,
                    is24Hour: clockManager.is24Hour,
                    calendarService: calendarService
                )
            }

            Divider()
                .padding(.horizontal, 12)

            // Time slider
            TimeSliderView(clockManager: clockManager)
                .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 12)

            // Search
            CitySearchView(clockManager: clockManager)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 12)

            // Footer
            FooterView(calendarService: calendarService)
        }
        .frame(width: 340)
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd MMMM yyyy"
        return formatter.string(from: Date())
    }
}

struct NextMeetingBadge: View {
    let timeUntil: String
    let eventTitle: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(size: 10))
            Text("in \(timeUntil)")
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
        .foregroundStyle(.blue)
        .help(eventTitle)
    }
}

struct MeetingDetailView: View {
    let event: EKEvent
    let clocks: [WorldClock]
    let is24Hour: Bool
    let calendarService: CalendarService

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
                Text("Next: \(event.title ?? "Meeting")")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }

            // Show meeting time in each clock's timezone
            ForEach(clocks.prefix(5)) { clock in
                if let tz = clock.timeZone {
                    HStack(spacing: 6) {
                        Text(clock.compactName)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                        Text(calendarService.eventTime(event: event, in: tz, is24Hour: is24Hour))
                            .font(.system(size: 11, design: .monospaced))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct FooterView: View {
    @ObservedObject var calendarService: CalendarService

    var body: some View {
        HStack {
            if !calendarService.hasAccess {
                Button(action: {
                    calendarService.requestAccess()
                }) {
                    Label("Enable Calendar", systemImage: "calendar.badge.plus")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            Spacer()

            SettingsLink {
                Image(systemName: "gear")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "power")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Quit Timely")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
