// Rasterize the mascot SVG into an .iconset directory, one PNG per
// macOS icon size. Run via `make icon`:
//
//   swift scripts/make-icon.swift mascot.svg .build/AppIcon.iconset

import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <svg> <iconset-dir>\n".utf8))
    exit(1)
}
guard let svg = NSImage(contentsOfFile: arguments[1]) else {
    FileHandle.standardError.write(Data("can't load \(arguments[1])\n".utf8))
    exit(1)
}
let outDir = URL(fileURLWithPath: arguments[2])

let variants: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

for (name, pixels) in variants {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Fit the artwork into the Apple icon grid: content inside ~82% of
    // the canvas, centered, with transparent margins around it.
    let box = 0.82 * CGFloat(pixels)
    let scale = min(box / svg.size.width, box / svg.size.height)
    let size = NSSize(width: svg.size.width * scale, height: svg.size.height * scale)
    let origin = NSPoint(
        x: (CGFloat(pixels) - size.width) / 2, y: (CGFloat(pixels) - size.height) / 2)
    svg.draw(in: NSRect(origin: origin, size: size))

    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    try png.write(to: outDir.appendingPathComponent(name))
}
