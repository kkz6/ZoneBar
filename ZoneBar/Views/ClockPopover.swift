import SwiftUI

struct ClockPopover: View {
    @Environment(ClockStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(TimeTicker.self) private var ticker
    @Environment(FocusClockFilter.self) private var focusFilter
    @Environment(\.openSettingsWindow) private var openSettingsWindow

    @State private var addExpanded = false
    @State private var offset: TimeInterval = 0

    private let rowHeight: CGFloat = 46
    private let maxVisibleRows = 6

    private var visibleClocks: [WorldClock] { focusFilter.popoverClocks(from: store.clocks) }

    private var previewDate: Date { ticker.now.addingTimeInterval(offset) }

    @State private var dragSession = ClockDragSession()

    var body: some View {
        VStack(spacing: 0) {
            header

            if focusFilter.hasConfiguredFilter && !addExpanded {
                focusBanner
            }

            if addExpanded {
                // Dedicate the popover to searching so suggestions have room.
                CitySearchView(autoFocus: true) { addExpanded = false }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.sm)
            } else if visibleClocks.isEmpty {
                emptyState
            } else {
                clockList

                Divider().opacity(0.4)
                TimeScrubberView(offset: $offset, baseDate: ticker.now, clocks: visibleClocks)
            }

            Divider().opacity(0.4)
            footer
        }
        .frame(width: DS.Size.popoverWidth)
        .task { await focusFilter.refresh() }
        .onChange(of: visibleClocks.map(\.id)) { _, _ in dragSession.finish() }
        .onDisappear { offset = 0; addExpanded = false; dragSession.finish() }
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
            .help(
                Text(
                    addExpanded
                        ? LocalizedStringKey("Close")
                        : LocalizedStringKey("Add a city")
                )
            )
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.sm)
    }

    private var focusBanner: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "moon.fill")
                .foregroundStyle(.indigo)
            Text(focusFilter.isShowingAll ? LocalizedStringKey("Focus filter paused") : LocalizedStringKey("Filtered by Focus"))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Button {
                focusFilter.toggleShowAll()
            } label: {
                Text(focusFilter.isShowingAll ? LocalizedStringKey("Resume") : LocalizedStringKey("Show all"))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
        .font(.system(size: 11))
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .background(.indigo.opacity(0.06))
    }

    // MARK: - Clock list

    @ViewBuilder
    private var clockList: some View {
        if visibleClocks.count <= maxVisibleRows {
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
            ForEach(visibleClocks) { clock in
                ClockRow(clock: clock, now: previewDate, settings: settings, height: rowHeight, store: store, dragSession: dragSession, displayedClocks: visibleClocks)
                    .clockReordering(clock: clock, store: store, dragSession: dragSession)
                if clock.id != visibleClocks.last?.id {
                    Divider().padding(.leading, 54)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: DS.Spacing.md) {
            Group {
                if visibleClocks.count == 1 {
                    Text("1 clock")
                } else {
                    Text("\(visibleClocks.count) clocks")
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)

            Spacer()

            Button {
                openSettingsWindow()
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
            Text(focusFilter.isFiltering ? LocalizedStringKey("No clocks in this Focus") : LocalizedStringKey("No clocks yet"))
                .font(.system(size: 13, weight: .medium))
            Text(focusFilter.isFiltering ? LocalizedStringKey("Show all clocks or update your Focus filter.") : LocalizedStringKey("Tap + to add a city"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = settings.locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEddMMMM")
        return formatter.string(from: ticker.now)
    }
}

// MARK: - Clock Row

private struct ClockRow: View {
    let clock: WorldClock
    let now: Date
    let settings: AppSettings
    let height: CGFloat
    let store: ClockStore
    let dragSession: ClockDragSession
    let displayedClocks: [WorldClock]

    @State private var isHovering = false

    var body: some View {
        let day = clock.isDaytime(at: now)
        HStack(spacing: DS.Spacing.md) {
            ClockReorderTile(
                clock: clock, store: store, dragSession: dragSession,
                symbol: day ? "sun.max.fill" : "moon.fill",
                color: day ? .orange : .indigo,
                isHovering: isHovering,
                displayedClocks: displayedClocks
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

            if let dayLabel = clock.relativeDayLabel(at: now, language: settings.language) {
                Text(dayLabel)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }

            Text(
                clock.formattedTime(
                    at: now,
                    is24Hour: settings.is24Hour,
                    locale: settings.locale
                )
            )
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(day ? .primary : .secondary)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .frame(height: height)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }
}
