import AppKit
import SwiftUI

/// AppKit-owned configuration for a fixed-size SwiftUI settings window.
///
/// Keeping window chrome outside the SwiftUI view hierarchy prevents hosting
/// view intrinsic-size updates from changing the frame or relaying out native
/// titlebar controls after the settings content has appeared.
struct SettingsWindowConfiguration {
    let identifier: NSUserInterfaceItemIdentifier
    let title: String
    let size: CGSize
    let trafficLightLeading: CGFloat
    let trafficLightCenterFromTop: CGFloat
}

/// Reusable owner for a fixed-size settings window containing arbitrary SwiftUI
/// content. AppKit owns frame and chrome; SwiftUI owns only the rendered body.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let configuration: SettingsWindowConfiguration
    private var windowController: NSWindowController?

    init(configuration: SettingsWindowConfiguration) {
        self.configuration = configuration
        super.init()
    }

    func show<Content: View>(_ rootView: Content) {
        let window = prepareWindow(rootView)
        NSApplication.shared.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        configureNativeTrafficLights(in: window)
    }

    /// Creates the window once and returns the same instance on later calls.
    /// Kept internal so window-level regression tests can validate the actual
    /// AppKit contract without displaying or controlling the user's screen.
    @discardableResult
    func prepareWindow<Content: View>(_ rootView: Content) -> NSWindow {
        if let window = windowController?.window {
            return window
        }

        let window = makeWindow()
        let hostingController = NSHostingController(rootView: rootView)

        // The window controller is the only sizing authority. Without this,
        // NSHostingController converts its 560-point intrinsic content height
        // into a 592-point titled frame after the window has been configured.
        hostingController.sizingOptions = []

        let containerController = NSViewController()
        let container = NSView(frame: NSRect(origin: .zero, size: configuration.size))
        containerController.view = container
        containerController.addChild(hostingController)

        hostingController.view.frame = container.bounds
        hostingController.view.autoresizingMask = [.width, .height]
        container.addSubview(hostingController.view)

        window.contentViewController = containerController
        configureFrame(of: window)
        window.contentView?.superview?.layoutSubtreeIfNeeded()
        configureNativeTrafficLights(in: window)
        window.delegate = self

        let controller = NSWindowController(window: window)
        windowController = controller
        return window
    }

    func close() {
        windowController?.window?.close()
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: configuration.size),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.identifier = configuration.identifier
        window.title = configuration.title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        // A unified native titlebar gives the system controls enough vertical
        // room to align with the settings header without clipping their edges.
        let toolbar = NSToolbar(identifier: "SettingsToolbar")
        toolbar.showsBaselineSeparator = false
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.isMovableByWindowBackground = true
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        window.collectionBehavior.insert(.fullScreenNone)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        return window
    }

    private func configureFrame(of window: NSWindow) {
        let size = configuration.size
        window.minSize = size
        window.maxSize = size

        var frame = window.frame
        frame.origin.y += frame.height - size.height
        frame.size = size
        window.setFrame(frame, display: false)
        window.center()
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        configureNativeTrafficLights(in: window)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        configureNativeTrafficLights(in: window)
    }

    private func configureNativeTrafficLights(in window: NSWindow) {
        // Some AppKit versions add unified-toolbar height to the limits
        // assigned to a full-size content window. Compensate for the reported
        // difference so both limits describe the actual fixed window frame.
        if window.minSize != configuration.size {
            window.minSize = configuration.size
            let reportedSize = window.minSize
            if reportedSize != configuration.size {
                window.minSize = NSSize(
                    width: configuration.size.width * 2 - reportedSize.width,
                    height: configuration.size.height * 2 - reportedSize.height
                )
            }
        }
        if window.maxSize != configuration.size {
            window.maxSize = configuration.size
            let reportedSize = window.maxSize
            if reportedSize != configuration.size {
                window.maxSize = NSSize(
                    width: configuration.size.width * 2 - reportedSize.width,
                    height: configuration.size.height * 2 - reportedSize.height
                )
            }
        }
        guard let contentView = window.contentView else { return }
        let types: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        for (index, type) in types.enumerated() {
            guard let button = window.standardWindowButton(type), let parent = button.superview else { continue }
            button.isHidden = false
            button.isEnabled = type == .closeButton
            // Preserve each system control's size and AppKit-owned titlebar
            // parent so rendering, hover tracking, and accessibility stay native.
            let origin = NSPoint(
                x: configuration.trafficLightLeading + CGFloat(index) * 23,
                y: contentView.bounds.height - configuration.trafficLightCenterFromTop - button.frame.height / 2
            )
            button.setFrameOrigin(contentView.convert(origin, to: parent))
        }
    }
}

/// Environment action used by menu content without coupling it to a SwiftUI
/// Window scene. Any app reusing the settings framework supplies its own action.
struct SettingsWindowOpeningAction {
    private let handler: () -> Void

    init(_ handler: @escaping () -> Void = {}) {
        self.handler = handler
    }

    func callAsFunction() {
        handler()
    }
}

private struct SettingsWindowOpeningKey: EnvironmentKey {
    static let defaultValue = SettingsWindowOpeningAction()
}

extension EnvironmentValues {
    var openSettingsWindow: SettingsWindowOpeningAction {
        get { self[SettingsWindowOpeningKey.self] }
        set { self[SettingsWindowOpeningKey.self] = newValue }
    }
}
