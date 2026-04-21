//
//  NepaliEditorWindow.swift
//  Nepali-Calendar-App
//
//  Floating wordpad-style window that hosts a full-size NepaliTyperView
//  so the user can type and organize notes outside the menu-bar popover.
//

import AppKit
import SwiftUI

enum NepaliEditorWindow {
    /// Strong reference — NSWindow doesn't retain itself when shown via makeKeyAndOrderFront.
    private static var controller: NSWindowController?

    /// Opens the editor window, or brings it to the front if already open.
    static func show() {
        if let existing = controller?.window {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }

        var typer = NepaliTyperView()
        typer.showsFullEditorButton = false
        typer.showsClearButton = true
        let root = typer
            .frame(minWidth: 520, minHeight: 420)

        let hosting = NSHostingController(rootView: root)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Nepali Editor"
        window.contentViewController = hosting
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 520, height: 420)
        positionOnLeft(window, size: NSSize(width: 640, height: 480))
        window.setFrameAutosaveName("NepaliEditorWindow")

        let wc = NSWindowController(window: window)
        controller = wc

        // Drop the reference when user closes the window.
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            controller = nil
        }

        NSApp.activate(ignoringOtherApps: true)
        wc.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}

/// Place a newly-created window on the left side of the main screen so it
/// doesn't get covered by the menu-bar popover on the right edge. No-op
/// after the first launch — `setFrameAutosaveName` will restore the user's
/// preferred position.
func positionOnLeft(_ window: NSWindow, size: NSSize) {
    guard let screen = NSScreen.main else { return }
    let visible = screen.visibleFrame
    let margin: CGFloat = 24
    let origin = NSPoint(
        x: visible.minX + margin,
        y: visible.maxY - size.height - margin
    )
    window.setFrame(NSRect(origin: origin, size: size), display: false)
}
