import SwiftUI
import AppKit

enum BrandIcon {
    // MenuBarExtra bridges to NSStatusItem and can use NSImage's intrinsic size,
    // even when the SwiftUI Image has a frame. Keep the header master untouched.
    static let menuBarImage: NSImage = {
        let icon = image.copy() as! NSImage
        icon.size = NSSize(width: 18, height: 18)
        icon.isTemplate = false
        return icon
    }()

    static let image: NSImage = {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            icon.isTemplate = false
            return icon
        }
        return NSImage(systemSymbolName: "gauge.with.dots.needle.50percent", accessibilityDescription: "Codex Quota Bar")!
    }()
}
