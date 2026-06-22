import SwiftUI
import AppKit

/// Bridges `NSVisualEffectView` so the settings window can show the real
/// behind-window vibrancy (desktop blurred through) that SwiftUI's
/// `containerBackground(for: .window)` only offers on macOS 15+.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = .active
        // Let the desktop blur through by making the host window non-opaque.
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = true
            }
        }
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blending
        view.state = .active
    }
}

/// Pins the host window to a fixed size and disables resizing / frame restoration,
/// so the settings window always opens at the intended dimensions.
struct WindowConfigurator: NSViewRepresentable {
    let size: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { apply(from: view) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { apply(from: nsView) }
    }

    private func apply(from view: NSView) {
        guard let window = view.window else { return }
        window.styleMask.remove(.resizable)
        window.isRestorable = false
        window.minSize = size
        window.maxSize = size
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.collectionBehavior.insert(.fullScreenNone)

        // Force the window frame to exactly the content size, anchored at the
        // top-left, clearing any stale/restored larger frame that would leave an
        // uncovered (transparent) strip.
        let target = window.frameRect(forContentRect: NSRect(origin: .zero, size: size)).size
        if window.frame.size != target {
            var frame = window.frame
            frame.origin.y += frame.size.height - target.height
            frame.size = target
            window.setFrame(frame, display: true)
        }
    }
}
