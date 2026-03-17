import SwiftUI
import EventKit

struct ClockListView: View {
    @ObservedObject var clockManager: ClockManager
    @ObservedObject var calendarService: CalendarService

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text(currentDateString())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if let timeUntil = calendarService.timeUntilNextEvent() {
                    NextMeetingBadge(
                        timeUntil: timeUntil,
                        eventTitle: calendarService.nextEvent?.title ?? "Meeting"
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)

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
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
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
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        clockManager.removeClock(id: clock.id)
                                    }
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
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
                MeetingDetailView(
                    event: event,
                    clocks: clockManager.clocks,
                    is24Hour: clockManager.is24Hour,
                    calendarService: calendarService
                )
            }

            // Time slider
            TimeSliderView(clockManager: clockManager)

            // Search
            CitySearchView(clockManager: clockManager)

            // Footer
            FooterView(calendarService: calendarService)
        }
        .frame(width: 320)
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd MMMM"
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
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.blue.opacity(0.1), in: Capsule())
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct FooterView: View {
    @ObservedObject var calendarService: CalendarService

    var body: some View {
        HStack(spacing: 12) {
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
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Settings")

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Image(systemName: "power")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Quit Timely")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
