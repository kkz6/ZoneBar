import SwiftUI

struct TimeSliderView: View {
    @ObservedObject var clockManager: ClockManager
    @State private var sliderMinutes: Double = 0

    private var currentMinuteOfDay: Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
    }

    private var previewMinute: Int {
        Int(sliderMinutes)
    }

    private var previewTimeString: String {
        let hours = previewMinute / 60
        let minutes = previewMinute % 60
        if clockManager.is24Hour {
            return String(format: "%02d:%02d", hours, minutes)
        } else {
            let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
            let ampm = hours < 12 ? "AM" : "PM"
            return String(format: "%d:%02d %@", displayHour, minutes, ampm)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Time preview")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                if clockManager.isSliderActive {
                    Button("Now") {
                        withAnimation(.easeOut(duration: 0.2)) {
                            sliderMinutes = currentMinuteOfDay
                            clockManager.resetSlider()
                        }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }

            HStack(spacing: 8) {
                Text("00:00")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)

                Slider(value: $sliderMinutes, in: 0...1439, step: 1)
                    .onChange(of: sliderMinutes) { _, newValue in
                        let currentMinute = currentMinuteOfDay
                        let offsetMinutes = newValue - currentMinute
                        clockManager.sliderOffset = offsetMinutes * 60
                        clockManager.isSliderActive = abs(offsetMinutes) > 0.5
                    }

                Text("23:59")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            if clockManager.isSliderActive {
                Text("Previewing \(previewTimeString) local time")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
            }

            // Working hours overlap indicator
            WorkingHoursOverlay(clocks: clockManager.clocks, offset: clockManager.sliderOffset)
        }
        .padding(.horizontal, 12)
        .onAppear {
            sliderMinutes = currentMinuteOfDay
        }
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
