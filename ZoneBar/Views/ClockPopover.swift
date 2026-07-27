import SwiftUI

struct ClockPopover: View {
    @Environment(ClockStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(TimeTicker.self) private var ticker
    @Environment(\.openWindow) private var openWindow

    @State private var addExpanded = false
    @State private var offset: TimeInterval = 0

    private let rowHeight: CGFloat = 46
    private let maxVisibleRows = 6

    private var previewDate: Date { ticker.now.addingTimeInterval(offset) }

    var body: some View {
        VStack(spacing: 0) {
            header

            if addExpanded {
                // Dedicate the popover to searching so suggestions have room.
                CitySearchView(autoFocus: true) { addExpanded = false }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.sm)
            } else if store.clocks.isEmpty {
                emptyState
            } else {
                clockList

                Divider().opacity(0.4)
                TimeScrubberView(offset: $offset, baseDate: ticker.now)
            }

            Divider().opacity(0.4)
            footer
        }
        .frame(width: DS.Size.popoverWidth)
        .onDisappear { offset = 0; addExpanded = false }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: DS.Spacing.sm) {
            Text(dateString)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                withAnimation(.snappy(duration: 0.2)) { addExpanded.toggle() }
            } label: {
                Image(systemName: addExpanded ? "xmark" : "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(addExpanded ? "Close" : "Add a city")
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.sm)
    }

    // MARK: - Clock list

    @ViewBuilder
    private var clockList: some View {
        if store.clocks.count <= maxVisibleRows {
            clockRows
        } else {
            ScrollView(.vertical, showsIndicators: true) {
                clockRows
            }
            .frame(height: CGFloat(maxVisibleRows) * rowHeight)
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var clockRows: some View {
        VStack(spacing: 0) {
            ForEach(store.clocks) { clock in
                ClockRow(clock: clock, now: previewDate, settings: settings, height: rowHeight)
                if clock.id != store.clocks.last?.id {
                    Divider().padding(.leading, 54)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: DS.Spacing.md) {
            Text("\(store.clocks.count) \(store.clocks.count == 1 ? "clock" : "clocks")")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)

            Spacer()

            Button {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openWindow(id: SettingsWindow.windowID)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Settings")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Quit ZoneBar")
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.xs)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: "globe")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("No clocks yet")
                .font(.system(size: 13, weight: .medium))
            Text("Tap + to add a city")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd MMMM"
        return formatter.string(from: ticker.now)
    }
}

// MARK: - Clock Row (read-only)

private struct ClockRow: View {
    let clock: WorldClock
    let now: Date
    let settings: AppSettings
    let height: CGFloat

    var body: some View {
        let day = clock.isDaytime(at: now)
        HStack(spacing: DS.Spacing.md) {
            IconTile(
                symbol: day ? "sun.max.fill" : "moon.fill",
                color: day ? .orange : .indigo
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(settings.compactMode ? clock.compactName : clock.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(clock.gmtOffsetString)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: DS.Spacing.sm)

            if let dayLabel = clock.relativeDayLabel(at: now) {
                Text(dayLabel)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }

            Text(clock.formattedTime(at: now, is24Hour: settings.is24Hour))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(day ? .primary : .secondary)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .frame(height: height)
    }
}
