import AppKit

let root = CommandLine.arguments[1]
let folder = URL(fileURLWithPath: root).appendingPathComponent("Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
NSGradient(starting: NSColor(calibratedRed: 0.39, green: 0.40, blue: 0.95, alpha: 1),
           ending: NSColor(calibratedRed: 0.13, green: 0.09, blue: 0.35, alpha: 1))!
    .draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024), angle: -55)
NSColor.white.setFill()
for (index, height) in [130, 260, 430, 600, 430, 260, 130].enumerated() {
    let rect = NSRect(x: CGFloat(190 + index * 94), y: CGFloat(1024 - height) / 2, width: 58, height: CGFloat(height))
    NSBezierPath(roundedRect: rect, xRadius: 29, yRadius: 29).fill()
}
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("icon.png"))
let contents: [String: Any] = ["images": [["filename": "icon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"]],
    "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: folder.appendingPathComponent("Contents.json"))
