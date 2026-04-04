import SwiftUI

struct ClockListView: View {
    @ObservedObject var clockManager: ClockManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text(currentDateString())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()
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

            // Time slider
            TimeSliderView(clockManager: clockManager)

            // Search
            CitySearchView(clockManager: clockManager)

            // Footer
            FooterView()
        }
        .frame(width: 320)
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd MMMM"
        return formatter.string(from: Date())
    }
}

struct FooterView: View {
    var body: some View {
        HStack(spacing: 12) {
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
            .help("Quit WorldTick")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
