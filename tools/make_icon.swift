import Cocoa
let dir = CommandLine.arguments[1]
try! FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
func draw(_ s: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    let k = CGFloat(s) / 1024.0
    NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 32*k, y: 32*k, width: 960*k, height: 960*k), xRadius: 220*k, yRadius: 220*k).fill()
    let scr = NSRect(x: 160*k, y: 300*k, width: 704*k, height: 440*k)
    NSColor(calibratedWhite: 0.18, alpha: 1).setFill()
    NSBezierPath(roundedRect: scr, xRadius: 40*k, yRadius: 40*k).fill()
    let inner = scr.insetBy(dx: 14*k, dy: 14*k)
    NSColor(calibratedRed: 0.05, green: 0.6, blue: 0.55, alpha: 1).setFill()
    NSBezierPath(roundedRect: inner, xRadius: 28*k, yRadius: 28*k).fill()
    let dash = inner.insetBy(dx: 40*k, dy: 40*k)
    let p = NSBezierPath(roundedRect: dash, xRadius: 18*k, yRadius: 18*k)
    p.lineWidth = 10*k; p.setLineDash([24*k, 18*k], count: 2, phase: 0)
    NSColor.white.setStroke(); p.stroke()
    NSColor(calibratedWhite: 0.30, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 462*k, y: 220*k, width: 100*k, height: 80*k), xRadius: 12*k, yRadius: 12*k).fill()
    NSBezierPath(roundedRect: NSRect(x: 360*k, y: 200*k, width: 304*k, height: 30*k), xRadius: 15*k, yRadius: 15*k).fill()
    img.unlockFocus()
    return img
}
for (name, px) in [("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),
                   ("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),
                   ("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)] {
    let rep = NSBitmapImageRep(data: draw(px).tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
}
