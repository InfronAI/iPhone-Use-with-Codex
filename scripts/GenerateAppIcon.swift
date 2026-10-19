import AppKit

// Reproducible vector artwork, matching the in-game fighter.
let side = 1024
let canvas = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
    bytesPerRow: side * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let context = NSGraphicsContext(cgContext: canvas, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
let cyan = NSColor(red: 0.32, green: 0.95, blue: 1, alpha: 1)
let background = NSBezierPath(rect: NSRect(x: 0, y: 0, width: side, height: side))
NSGradient(starting: NSColor(red: 0.035, green: 0.13, blue: 0.22, alpha: 1),
           ending: NSColor(red: 0.01, green: 0.02, blue: 0.06, alpha: 1))!.draw(in: background, angle: -90)
cyan.withAlphaComponent(0.08).setStroke()
for coordinate in stride(from: 32, to: side, by: 80) {
    let line = NSBezierPath()
    line.move(to: NSPoint(x: coordinate, y: 0)); line.line(to: NSPoint(x: coordinate, y: side))
    line.move(to: NSPoint(x: 0, y: coordinate)); line.line(to: NSPoint(x: side, y: coordinate))
    line.lineWidth = 2; line.stroke()
}
let ring = NSBezierPath(ovalIn: NSRect(x: 155, y: 155, width: 714, height: 714))
ring.lineWidth = 3
cyan.withAlphaComponent(0.35).setStroke(); ring.stroke()

func shape(_ points: [(Double, Double)], fill: NSColor, stroke: NSColor, lineWidth: Double) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: points[0].0, y: points[0].1))
    for point in points.dropFirst() { path.line(to: NSPoint(x: point.0, y: point.1)) }
    path.close()
    path.lineJoinStyle = .round
    fill.setFill(); path.fill()
    stroke.setStroke(); path.lineWidth = lineWidth; path.stroke()
}

let shadow = NSShadow()
shadow.shadowColor = cyan.withAlphaComponent(0.7)
shadow.shadowBlurRadius = 35
shadow.shadowOffset = .zero
NSGraphicsContext.saveGraphicsState()
shadow.set()
shape([(512, 830), (600, 540), (785, 365), (770, 288), (600, 350), (512, 295),
       (424, 350), (254, 288), (239, 365), (424, 540)],
      fill: NSColor(red: 0.055, green: 0.2, blue: 0.3, alpha: 1), stroke: cyan, lineWidth: 12)
NSGraphicsContext.restoreGraphicsState()
shape([(512, 790), (578, 395), (512, 335), (446, 395)],
      fill: NSColor(red: 0.7, green: 0.89, blue: 0.95, alpha: 1), stroke: .white, lineWidth: 6)
shape([(512, 675), (545, 492), (512, 433), (479, 492)], fill: cyan, stroke: cyan, lineWidth: 3)
for x in [374.0, 650.0] {
    shape([(x - 28, 316), (x + 28, 316), (x, 160)], fill: cyan.withAlphaComponent(0.8), stroke: cyan, lineWidth: 2)
}
NSGraphicsContext.restoreGraphicsState()
let folder = URL(fileURLWithPath: "HelloWorld/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
let bitmap = NSBitmapImageRep(cgImage: canvas.makeImage()!)
try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("AppIcon.png"))
print("Generated AppIcon.png (1024 × 1024)")
