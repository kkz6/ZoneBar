import SwiftUI

struct TimeSliderView: View {
    @ObservedObject var clockManager: ClockManager
    @State private var sliderMinutes: Double = 0
    @State private var isDragging: Bool = false

    private var currentMinuteOfDay: Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
    }

    private var displayMinute: Int {
        Int(sliderMinutes)
    }

    private var displayTimeString: String {
        let hours = displayMinute / 60
        let minutes = displayMinute % 60
        if clockManager.is24Hour {
            return String(format: "%02d:%02d", hours, minutes)
        } else {
            let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
            let ampm = hours < 12 ? "AM" : "PM"
            return String(format: "%d:%02d %@", displayHour, minutes, ampm)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // Labels row
            HStack {
                Text("00:00")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)

                Spacer()

                Text(displayTimeString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(isDragging ? .blue : .secondary)

                Spacer()

                Text("23:59")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            // Custom timeline bar
            TimelineBar(
                value: $sliderMinutes,
                isDragging: $isDragging,
                onChange: { newValue in
                    let currentMinute = currentMinuteOfDay
                    let offsetMinutes = newValue - currentMinute
                    clockManager.sliderOffset = offsetMinutes * 60
                    clockManager.isSliderActive = abs(offsetMinutes) > 0.5
                },
                onRelease: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        sliderMinutes = currentMinuteOfDay
                        clockManager.resetSlider()
                    }
                }
            )

            // Working hours indicator
            WorkingHoursOverlay(clocks: clockManager.clocks, offset: clockManager.sliderOffset)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .onAppear {
            sliderMinutes = currentMinuteOfDay
        }
    }
}

struct TimelineBar: View {
    @Binding var value: Double
    @Binding var isDragging: Bool
    let onChange: (Double) -> Void
    let onRelease: () -> Void

    private let totalMinutes: Double = 1439
    private let barHeight: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let markerX = max(0, min(width, (value / totalMinutes) * width))

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: barHeight)

                // Filled portion
                Capsule()
                    .fill(Color.blue)
                    .frame(width: markerX, height: barHeight)

                // Drag handle
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                    .frame(width: isDragging ? 14 : 10, height: isDragging ? 14 : 10)
                    .overlay(
                        Circle()
                            .fill(Color.blue)
                            .frame(width: isDragging ? 5 : 3, height: isDragging ? 5 : 3)
                    )
                    .position(x: markerX, y: geometry.size.height / 2)
                    .animation(.easeOut(duration: 0.15), value: isDragging)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let fraction = max(0, min(1, gesture.location.x / width))
                        value = fraction * totalMinutes
                        onChange(value)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onRelease()
                    }
            )
        }
        .frame(height: 16)
    }
}

struct WorkingHoursOverlay: View {
    let clocks: [WorldClock]
    let offset: TimeInterval

    private var allInWorkingHours: Bool {
        guard !clocks.isEmpty else { return false }
        return clocks.allSatisfy { clock in
            let hour = clock.currentHour(offset: offset)
            return hour >= 9 && hour < 17
        }
    }

    var body: some View {
        if !clocks.isEmpty {
            HStack(spacing: 4) {
                Circle()
                    .fill(allInWorkingHours ? .green : .orange)
                    .frame(width: 6, height: 6)
                Text(allInWorkingHours ? "All in working hours (9-5)" : "Some outside working hours")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
