import SwiftUI

/// A clearly-labelled time scrubber for the popover. Drag the bar to preview what
/// time it is across every clock at any moment of the day; the clocks update live
/// and the "match" dot turns green when all zones fall inside working hours.
struct TimeScrubberView: View {
    @Environment(ClockStore.self) private var store
    @Environment(AppSettings.self) private var settings

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

            ScrubberTrack(minute: previewMinute, isDragging: $isDragging) { newMinute in
                offset = (newMinute - baseMinuteOfDay) * 60
            }

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
                Spacer()
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
    }
}

private struct ScrubberTrack: View {
    let minute: Double
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
