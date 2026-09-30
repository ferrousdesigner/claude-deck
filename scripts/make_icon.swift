// Renders the app icon: `swift scripts/make_icon.swift <out.png>`
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// macOS squircle-ish tile with the standard inset.
let inset: CGFloat = 100
let tile = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let path = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
NSGradient(colors: [NSColor(red: 0.93, green: 0.55, blue: 0.40, alpha: 1), NSColor(red: 0.70, green: 0.31, blue: 0.22, alpha: 1)])!
    .draw(in: path, angle: -60)

// Dashboard bars.
NSColor.white.withAlphaComponent(0.22).setFill()
let bars: [(CGFloat, CGFloat)] = [(0.30, 0.34), (0.42, 0.52), (0.54, 0.40), (0.66, 0.62)]
for (x, h) in bars {
    NSBezierPath(roundedRect: NSRect(x: size * x, y: size * 0.22, width: size * 0.08, height: size * h * 0.8), xRadius: 26, yRadius: 26).fill()
}

// Sparkle.
func sparkle(center c: NSPoint, r: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    let k: CGFloat = 0.22
    p.move(to: NSPoint(x: c.x, y: c.y + r))
    p.curve(to: NSPoint(x: c.x + r, y: c.y), controlPoint1: NSPoint(x: c.x + r * k, y: c.y + r * k), controlPoint2: NSPoint(x: c.x + r * k, y: c.y + r * k))
    p.curve(to: NSPoint(x: c.x, y: c.y - r), controlPoint1: NSPoint(x: c.x + r * k, y: c.y - r * k), controlPoint2: NSPoint(x: c.x + r * k, y: c.y - r * k))
    p.curve(to: NSPoint(x: c.x - r, y: c.y), controlPoint1: NSPoint(x: c.x - r * k, y: c.y - r * k), controlPoint2: NSPoint(x: c.x - r * k, y: c.y - r * k))
    p.curve(to: NSPoint(x: c.x, y: c.y + r), controlPoint1: NSPoint(x: c.x - r * k, y: c.y + r * k), controlPoint2: NSPoint(x: c.x - r * k, y: c.y + r * k))
    p.close()
    return p
}
NSColor.white.setFill()
sparkle(center: NSPoint(x: size * 0.5, y: size * 0.56), r: size * 0.25).fill()
NSColor.white.withAlphaComponent(0.85).setFill()
sparkle(center: NSPoint(x: size * 0.72, y: size * 0.74), r: size * 0.08).fill()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
