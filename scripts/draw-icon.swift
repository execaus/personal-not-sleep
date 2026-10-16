import AppKit
import Foundation

// Native AppKit artwork: a warm wakeful sun on a quiet night-blue tile.
guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift draw-icon.swift OUTPUT.png\n", stderr)
    exit(1)
}
let size = 1024
guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                    isPlanar: false, colorSpaceName: .deviceRGB,
                                    bytesPerRow: 0, bitsPerPixel: 0),
      let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Could not create icon canvas\n", stderr)
    exit(1)
}
func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics
graphics.shouldAntialias = true
let tile = NSBezierPath(roundedRect: NSRect(x: 32, y: 32, width: 960, height: 960),
                        xRadius: 215, yRadius: 215)
NSGradient(starting: color(0.07, 0.14, 0.27), ending: color(0.12, 0.28, 0.40))!
    .draw(in: tile, angle: 125)

let halo = NSBezierPath(ovalIn: NSRect(x: 160, y: 160, width: 704, height: 704))
color(0.98, 0.72, 0.30, 0.11).setFill()
halo.fill()
let innerHalo = NSBezierPath(ovalIn: NSRect(x: 230, y: 230, width: 564, height: 564))
color(0.99, 0.81, 0.40, 0.10).setFill()
innerHalo.fill()

let center = NSPoint(x: 512, y: 512)
for index in 0..<12 {
    let angle = CGFloat(index) * .pi / 6
    let near = CGPoint(x: center.x + cos(angle) * 275, y: center.y + sin(angle) * 275)
    let far = CGPoint(x: center.x + cos(angle) * 352, y: center.y + sin(angle) * 352)
    let ray = NSBezierPath()
    ray.move(to: near)
    ray.line(to: far)
    ray.lineWidth = 27
    ray.lineCapStyle = .round
    color(1, 0.86, 0.49, 0.96).setStroke()
    ray.stroke()
}
let disc = NSBezierPath(ovalIn: NSRect(x: 320, y: 320, width: 384, height: 384))
NSGradient(starting: color(1, 0.91, 0.56), ending: color(0.98, 0.61, 0.23))!
    .draw(in: disc, angle: 135)
disc.lineWidth = 7
color(1, 0.97, 0.75, 0.65).setStroke()
disc.stroke()

graphics.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not encode icon PNG\n", stderr)
    exit(1)
}
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
