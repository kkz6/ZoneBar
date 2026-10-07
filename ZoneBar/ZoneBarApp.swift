import SwiftUI

@main
struct ZoneBarApp: App {
    @State private var store = ClockStore()
    @State private var settings = AppSettings()
    @State private var ticker = TimeTicker()
    @State private var focusFilter = FocusClockFilter.shared
    @State private var updater = AppUpdater()
    @State private var calendarService = CalendarEventService()
    @State private var settingsWindowController = SettingsWindowController(
        configuration: SettingsWindowConfiguration(
            identifier: NSUserInterfaceItemIdentifier(SettingsWindow.windowID),
            title: String(localized: "Settings"),
            size: SettingsLayout.windowSize,
            trafficLightLeading: SettingsLayout.trafficLightLeading,
            trafficLightCenterFromTop: SettingsLayout.titlebarControlCenterFromTop
        )
    )

    var body: some Scene {
        MenuBarExtra {
            ClockPopover()
                .environment(store)
                .environment(settings)
                .environment(ticker)
                .environment(updater)
                .environment(calendarService)
                .environment(focusFilter)
                .environment(
                    \.openSettingsWindow,
                    SettingsWindowOpeningAction { openSettings() }
                )
                .environment(\.locale, settings.locale)
                .tint(.zoneAccent)
                .preferredColorScheme(settings.theme.colorScheme)
                .modifier(MenuPanelPresentationAnimation())
        } label: {
            MenuBarLabel(store: store, settings: settings, ticker: ticker, focusFilter: focusFilter)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                OpenSettingsButton(
                    updater: updater,
                    openSettings: openSettings
                )
            }
        }
    }

    private func openSettings() {
        settingsWindowController.show(
            ZoneBarSettingsRoot(
                store: store,
                settings: settings,
                ticker: ticker,
                updater: updater,
                calendarService: calendarService,
                focusFilter: focusFilter
            )
        )
    }
}

/// Keeps locale and appearance modifiers reactive inside the independently
/// hosted AppKit window.
private struct ZoneBarSettingsRoot: View {
    let store: ClockStore
    let settings: AppSettings
    let ticker: TimeTicker
    let updater: AppUpdater
    let calendarService: CalendarEventService
    let focusFilter: FocusClockFilter

    var body: some View {
        SettingsWindow()
            .environment(store)
            .environment(settings)
            .environment(ticker)
            .environment(updater)
            .environment(calendarService)
            .environment(focusFilter)
            .environment(\.locale, settings.locale)
            .tint(.zoneAccent)
            .preferredColorScheme(settings.theme.colorScheme)
    }
}

private struct MenuPanelPresentationAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.985, anchor: .top)
            .offset(y: isVisible ? 0 : -3)
            .onAppear {
                if reduceMotion {
                    isVisible = true
                } else {
                    withAnimation(.easeOut(duration: 0.18)) {
                        isVisible = true
                    }
                }
            }
            .onDisappear { isVisible = false }
    }
}

/// Menu command (⌘,) that opens the custom settings window.
private struct OpenSettingsButton: View {
    let updater: AppUpdater
    let openSettings: () -> Void

    var body: some View {
        Group {
            Button("Check for Updates…") {
                updater.checkForUpdates()
            }

            Divider()

            Button("Settings…") {
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
