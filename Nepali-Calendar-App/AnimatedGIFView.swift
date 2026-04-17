//
//  AnimatedGIFView.swift
//  Nepali-Calendar-App
//
//  NSViewRepresentable wrapping an NSImageView that auto-animates a bundled
//  GIF resource. Respects Reduce Motion — falls back to a static first frame
//  when the user has disabled animations in Accessibility settings.
//

import SwiftUI
import AppKit

struct AnimatedGIFView: NSViewRepresentable {
    /// Resource name in the app bundle, without the `.gif` extension.
    let resourceName: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.image = Self.cachedImage(for: resourceName)
        view.imageScaling = .scaleProportionallyUpOrDown
        view.animates = !reduceMotion
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        view.animates = !reduceMotion
    }

    // Cache the decoded NSImage so we don't re-decode on every view rebuild.
    private static var cache: [String: NSImage] = [:]

    private static func cachedImage(for name: String) -> NSImage? {
        if let hit = cache[name] { return hit }
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif"),
              let image = NSImage(contentsOf: url)
        else { return nil }
        cache[name] = image
        return image
    }
}
