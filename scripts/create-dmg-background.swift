#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: create-dmg-background.swift <app-icon.png> <output.png>\n", stderr)
    exit(1)
}

let iconURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let canvasSize = NSSize(width: 680, height: 430)
let scale: CGFloat = 2

guard
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width * scale),
        pixelsHigh: Int(canvasSize.height * scale),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ),
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
else {
    fputs("Unable to create the DMG background canvas.\n", stderr)
    exit(1)
}

// Preserve a 680 × 430 point canvas while encoding twice as many pixels for
// sharp Finder text and artwork on Retina displays.
bitmap.size = canvasSize

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.cgContext.scaleBy(x: scale, y: scale)

let bounds = NSRect(origin: .zero, size: canvasSize)
NSColor(red: 0.955, green: 0.970, blue: 0.988, alpha: 1).setFill()
bounds.fill()

let titleStyle = NSMutableParagraphStyle()
titleStyle.alignment = .center
let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 25, weight: .semibold),
    .foregroundColor: NSColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1),
    .paragraphStyle: titleStyle,
    .kern: -0.45,
]
"Install ZoneBar".draw(
    in: NSRect(x: 80, y: 336, width: 520, height: 36),
    withAttributes: titleAttributes
)

let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .regular),
    .foregroundColor: NSColor(red: 0.34, green: 0.38, blue: 0.45, alpha: 1),
    .paragraphStyle: titleStyle,
]
"Drag ZoneBar into Applications".draw(
    in: NSRect(x: 80, y: 308, width: 520, height: 24),
    withAttributes: subtitleAttributes
)

if let icon = NSImage(contentsOf: iconURL) {
    icon.draw(
        in: NSRect(x: 318, y: 368, width: 44, height: 44),
        from: .zero,
        operation: .sourceOver,
        fraction: 0.92
    )
}

let linePath = NSBezierPath()
linePath.move(to: NSPoint(x: 282, y: 218))
linePath.line(to: NSPoint(x: 397, y: 218))
linePath.lineWidth = 2
let lineColor = NSColor(red: 0.22, green: 0.48, blue: 0.84, alpha: 0.34)
lineColor.setStroke()
linePath.setLineDash([5, 6], count: 2, phase: 0)
linePath.stroke()

let arrowPath = NSBezierPath()
arrowPath.move(to: NSPoint(x: 388, y: 227))
arrowPath.line(to: NSPoint(x: 398, y: 218))
arrowPath.line(to: NSPoint(x: 388, y: 209))
arrowPath.lineWidth = 2.5
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
NSColor(red: 0.14, green: 0.42, blue: 0.82, alpha: 0.72).setStroke()
arrowPath.stroke()

let footerAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 11, weight: .medium),
    .foregroundColor: NSColor(red: 0.38, green: 0.43, blue: 0.50, alpha: 0.82),
    .paragraphStyle: titleStyle,
    .kern: 0.15,
]
"MACOS 14 OR LATER  ·  APPLE SILICON + INTEL".draw(
    in: NSRect(x: 80, y: 38, width: 520, height: 18),
    withAttributes: footerAttributes
)

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode the DMG background.\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try png.write(to: outputURL, options: .atomic)
