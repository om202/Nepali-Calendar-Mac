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
        window.center()
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
