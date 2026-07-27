import Observation
import Sparkle

/// Owns Sparkle's updater for the lifetime of the application.
///
/// Sparkle performs scheduled background checks and presents its standard,
/// accessible update UI when a newer signed release is available.
@MainActor
@Observable
final class AppUpdater: NSObject, @preconcurrency SPUStandardUserDriverDelegate {
    @ObservationIgnored
    private let startsAutomatically: Bool
    @ObservationIgnored
    private var hasStarted: Bool
    @ObservationIgnored
    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: startsAutomatically,
        updaterDelegate: nil,
        userDriverDelegate: self
    )

    init(startingUpdater: Bool? = nil) {
        let shouldStart = startingUpdater ?? AppUpdater.defaultAutomaticStart
        startsAutomatically = shouldStart
        hasStarted = shouldStart
        super.init()
        _ = controller
    }

    func checkForUpdates() {
        if !hasStarted {
            controller.startUpdater()
            hasStarted = true
        }
        controller.checkForUpdates(nil)
    }

    /// ZoneBar is dockless, so explicitly opting into Sparkle's background-app
    /// behavior prevents scheduled update windows from stealing focus.
    var supportsGentleScheduledUpdateReminders: Bool { true }

    private static var defaultAutomaticStart: Bool {
#if DEBUG
        false
#else
        true
#endif
    }
}
