import SwiftUI

/// A clearly-labelled time scrubber for the popover. Drag the bar to preview what
/// time it is across every clock at any moment of the day; the clocks update live
/// and the "match" dot turns green when all zones fall inside working hours.
struct TimeScrubberView: View {
    @Environment(ClockStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(CalendarEventService.self) private var calendarService

    @Binding var offset: TimeInterval
    let baseDate: Date

    @State private var isDragging = false

    private var baseMinuteOfDay: Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: baseDate)
        return Double((c.hour ?? 0) * 60 + (c.minute ?? 0))
    }

    /// Absolute minute-of-day currently being previewed (0...1439).
    private var previewMinute: Double {
        min(1439, max(0, baseMinuteOfDay + offset / 60))
    }

    private var isPreviewing: Bool { abs(offset) > 30 }

    private var previewDate: Date { baseDate.addingTimeInterval(offset) }

    private var previewTimeString: String {
        let formatter = DateFormatter()
        formatter.locale = settings.locale
        formatter.setLocalizedDateFormatFromTemplate(settings.is24Hour ? "HHmm" : "hmma")
        return formatter.string(from: previewDate)
    }

    private var allInWorkingHours: Bool {
        guard !store.clocks.isEmpty else { return false }
        return store.clocks.allSatisfy { $0.isInWorkingHours(at: previewDate) }
    }

    private var visibleEvents: [CalendarTimelineEvent] {
        guard settings.showCalendarEvents,
              calendarService.accessState.canReadEvents else { return [] }
        return calendarService.events
    }

    private var activeEvents: [CalendarTimelineEvent] {
        guard isPreviewing,
              settings.showCalendarEvents,
              calendarService.accessState.canReadEvents else { return [] }
        return calendarService.events(at: previewDate)
    }

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(isPreviewing ? LocalizedStringKey("Previewing") : LocalizedStringKey("Drag to compare times"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(previewTimeString)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isPreviewing ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))

                Button {
                    withAnimation(.easeOut(duration: 0.25)) { offset = 0 }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(isPreviewing ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                .disabled(!isPreviewing)
                .help("Reset to now")
            }

            ScrubberTrack(
                minute: previewMinute,
                date: baseDate,
                events: visibleEvents,
                isDragging: $isDragging
            ) { newMinute in
                offset = (newMinute - baseMinuteOfDay) * 60
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: DS.Spacing.xs) {
                    Circle()
                        .fill(allInWorkingHours ? .green : .orange)
                        .frame(width: 6, height: 6)
                    Text(
                        allInWorkingHours
                            ? LocalizedStringKey("All clocks in working hours (9–5)")
                            : LocalizedStringKey("Not all in working hours")
                    )
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: DS.Spacing.sm)

                    if !visibleEvents.isEmpty {
                        Circle()
                            .fill(.blue)
                            .frame(width: 6, height: 6)
                        Text("Calendar event")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                if let event = activeEvents.first {
                    ActiveCalendarEventRow(
                        event: event,
                        additionalEventCount: activeEvents.count - 1,
                        locale: settings.locale,
                        is24Hour: settings.is24Hour,
                        onOpen: { calendarService.openInCalendar(event) }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeOut(duration: 0.16), value: activeEvents.map(\.id))
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .onAppear {
            if settings.showCalendarEvents {
                calendarService.refresh(for: baseDate)
            }
        }
        .onChange(of: settings.showCalendarEvents) { _, isEnabled in
            if isEnabled {
                calendarService.refresh(for: baseDate)
            }
        }
        .onChange(of: Calendar.current.startOfDay(for: baseDate)) { _, _ in
            if settings.showCalendarEvents {
                calendarService.refresh(for: baseDate)
            }
        }
    }
}

private struct ScrubberTrack: View {
    let minute: Double
    let date: Date
    let events: [CalendarTimelineEvent]
    @Binding var isDragging: Bool
    let onChange: (Double) -> Void

    private let totalMinutes: Double = 1439
    private let barHeight: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let markerX = max(0, min(width, (minute / totalMinutes) * width))

            ZStack(alignment: .leading) {
                // Track with hour ticks (every 6 hours = quarters).
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: barHeight)

                HStack(spacing: 0) {
                    ForEach(1..<4) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 1, height: barHeight)
                    }
                    Spacer()
                }

                Capsule()
                    .fill(Color.zoneAccent)
                    .frame(width: markerX, height: barHeight)

                ForEach(events) { event in
                    if let range = event.minuteRange(on: date) {
                        let startX = (range.lowerBound / totalMinutes) * width
                        let endX = (range.upperBound / totalMinutes) * width
                        RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                            .fill(.blue)
                            .frame(width: max(2, endX - startX), height: barHeight)
                            .offset(x: startX)
                            .accessibilityLabel(Text("Calendar event"))
                            .accessibilityValue(
                                event.title.isEmpty
                                    ? Text("Untitled event")
                                    : Text(verbatim: event.title)
                            )
                    }
                }

                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .frame(width: isDragging ? 16 : 13, height: isDragging ? 16 : 13)
                    .overlay(
                        Circle()
                            .fill(Color.zoneAccent)
                            .frame(width: isDragging ? 6 : 5, height: isDragging ? 6 : 5)
                    )
                    .position(x: markerX, y: geo.size.height / 2)
                    .animation(.easeOut(duration: 0.12), value: isDragging)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        isDragging = true
                        let fraction = max(0, min(1, g.location.x / width))
                        onChange(fraction * totalMinutes)
                    }
                    .onEnded { _ in isDragging = false }
            )
        }
        .frame(height: 18)
    }
}

private struct ActiveCalendarEventRow: View {
    let event: CalendarTimelineEvent
    let additionalEventCount: Int
    let locale: Locale
    let is24Hour: Bool
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.blue)

                Group {
                    if event.title.isEmpty {
                        Text("Untitled event")
                    } else {
                        Text(verbatim: event.title)
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)

                if additionalEventCount > 0 {
                    Text("+\(additionalEventCount)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.blue)
                }

                Spacer(minLength: DS.Spacing.xs)

                Text(timeRange)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, DS.Spacing.sm)
            .frame(height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.blue.opacity(0.09), in: RoundedRectangle(cornerRadius: 7))
        .help("Open in Calendar")
        .accessibilityHint(Text("Open in Calendar"))
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(is24Hour ? "HHmm" : "hmma")
        return "\(formatter.string(from: event.startDate))–\(formatter.string(from: event.endDate))"
    }
}
