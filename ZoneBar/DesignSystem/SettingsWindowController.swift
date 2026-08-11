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
final class SettingsWindowController {
    private let configuration: SettingsWindowConfiguration
    private var windowController: NSWindowController?

    init(configuration: SettingsWindowConfiguration) {
        self.configuration = configuration
    }

    func show<Content: View>(_ rootView: Content) {
        let window = prepareWindow(rootView)
        NSApplication.shared.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
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

        let trafficLights = SettingsTrafficLightGroup()
        trafficLights.identifier = .settingsTrafficLightGroup
        trafficLights.frame = NSRect(
            x: configuration.trafficLightLeading,
            y: configuration.size.height
                - configuration.trafficLightCenterFromTop
                - SettingsTrafficLightGroup.lightDiameter / 2,
            width: SettingsTrafficLightGroup.width,
            height: SettingsTrafficLightGroup.lightDiameter
        )
        trafficLights.autoresizingMask = [.minYMargin]
        container.addSubview(trafficLights)

        window.contentViewController = containerController
        configureFrame(of: window)
        hideNativeTrafficLights(in: window)

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

    private func hideNativeTrafficLights(in window: NSWindow) {
        for type in [
            NSWindow.ButtonType.closeButton,
            .miniaturizeButton,
            .zoomButton,
        ] {
            window.standardWindowButton(type)?.isHidden = true
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

private final class SettingsTrafficLightGroup: NSView {
    static let lightDiameter: CGFloat = 14
    static let lightGap: CGFloat = 9
    static let width = lightDiameter * 3 + lightGap * 2

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let closeButton = CloseTrafficLightButton(frame: lightFrame(at: 0))
        closeButton.identifier = .settingsCloseTrafficLight
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        addSubview(closeButton)

        for index in 1...2 {
            let indicator = DisabledTrafficLightView(frame: lightFrame(at: index))
            indicator.identifier = .settingsDisabledTrafficLight
            addSubview(indicator)
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

    @objc private func closeWindow() {
        window?.performClose(nil)
    }

    private func lightFrame(at index: Int) -> NSRect {
        NSRect(
            x: CGFloat(index) * (Self.lightDiameter + Self.lightGap),
            y: 0,
            width: Self.lightDiameter,
            height: Self.lightDiameter
        )
    }
}

private final class CloseTrafficLightButton: NSButton {
    private var trackingAreaReference: NSTrackingArea?
    private var isHovering = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isBordered = false
        imagePosition = .noImage
        title = ""
        SettingsTrafficLightAppearance.apply(
            to: self,
            color: NSColor(calibratedRed: 1, green: 0.37, blue: 0.34, alpha: 1)
        )
        toolTip = String(localized: "Close")
        setAccessibilityLabel(String(localized: "Close"))
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaReference {
            removeTrackingArea(trackingAreaReference)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self
        )
        addTrackingArea(trackingArea)
        trackingAreaReference = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard isHovering else { return }
        let inset: CGFloat = 4.25
        let cross = NSBezierPath()
        cross.move(to: NSPoint(x: inset, y: inset))
        cross.line(to: NSPoint(x: bounds.maxX - inset, y: bounds.maxY - inset))
        cross.move(to: NSPoint(x: inset, y: bounds.maxY - inset))
        cross.line(to: NSPoint(x: bounds.maxX - inset, y: inset))
        cross.lineWidth = 1.1
        cross.lineCapStyle = .round
        NSColor.black.withAlphaComponent(0.55).setStroke()
        cross.stroke()
    }
}

private final class DisabledTrafficLightView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        SettingsTrafficLightAppearance.apply(
            to: self,
            color: NSColor.systemGray.withAlphaComponent(0.50)
        )
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

/// One renderer for every traffic light keeps their visible diameter and border
/// identical. The close control only draws its hover glyph above this layer.
private enum SettingsTrafficLightAppearance {
    static func apply(to view: NSView, color: NSColor) {
        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
        view.layer?.borderColor = NSColor.black.withAlphaComponent(0.18).cgColor
        view.layer?.borderWidth = 0.5
        view.layer?.cornerRadius = SettingsTrafficLightGroup.lightDiameter / 2
        view.layer?.masksToBounds = true
    }
}

extension NSUserInterfaceItemIdentifier {
    static let settingsTrafficLightGroup = Self("SettingsTrafficLightGroup")
    static let settingsCloseTrafficLight = Self("SettingsCloseTrafficLight")
    static let settingsDisabledTrafficLight = Self("SettingsDisabledTrafficLight")
}
