import SwiftUI
import AppKit

/// MenuBarExtra renders its label inside an `NSStatusBarButton`, which draws a
/// grey "active" highlight while the popover is open. SwiftUI exposes no switch
/// for this, so we embed a zero-size probe in the label, walk up to the status
/// button, and disable its highlight drawing.
struct StatusItemConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { Self.disableHighlight(from: view) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { Self.disableHighlight(from: nsView) }
    }

    private static func disableHighlight(from view: NSView) {
        var current: NSView? = view
        while let node = current {
            if let button = node as? NSStatusBarButton {
                // Highlighting "by nothing" => the active state draws no background.
                (button.cell as? NSButtonCell)?.highlightsBy = []
                return
            }
            current = node.superview
        }
    }
}
