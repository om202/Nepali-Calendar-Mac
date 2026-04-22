//
//  NepaliTyperHelpWindow.swift
//  Nepali-Calendar-App
//
//  Floating window that hosts the Nepali typing guide. Separate from
//  the full editor window so users can keep both open side-by-side.
//

import AppKit
import SwiftUI
import Aptabase

enum NepaliTyperHelpWindow {
    private static var controller: NSWindowController?

    static func show() {
        if let existing = controller?.window {
            Aptabase.shared.trackEvent("typer_help_reopened")
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingController(rootView: NepaliTyperHelpView())

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Nepali Typing Guide"
        window.contentViewController = hosting
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 400, height: 420)
        window.setContentSize(NSSize(width: 440, height: 520))
        positionOnLeft(window, size: NSSize(width: 440, height: 520))
        window.setFrameAutosaveName("NepaliTyperHelpWindow")

        let wc = NSWindowController(window: window)
        controller = wc

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            Aptabase.shared.trackEvent("typer_help_closed")
            controller = nil
        }

        NSApp.activate(ignoringOtherApps: true)
        wc.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
