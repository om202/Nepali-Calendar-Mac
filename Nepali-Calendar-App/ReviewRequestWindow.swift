//
//  ReviewRequestWindow.swift
//  Nepali-Calendar-App
//
//  Standalone window that hosts the StoreKit review request. Required
//  because MenuBarExtra(.window) popovers are panel-style and the app
//  runs as LSUIElement=YES (.accessory policy) — StoreKit's review UI
//  needs a regular NSWindow in a foreground app to attach its sheet.
//  We temporarily elevate the activation policy to .regular while the
//  window is open, then revert when it closes.
//
//  Also exposes a direct App Store write-review URL as a visible fallback
//  button in case StoreKit still suppresses (rate limiting, etc.).
//

import AppKit
import SwiftUI
import StoreKit
import Aptabase

enum ReviewRequestWindow {
    /// Mac App Store product ID for Nepali Calendar (Pro).
    static let appStoreID = "6760244964"

    /// Deep link that opens the App Store directly on the write-review page.
    static let writeReviewURL = URL(string:
        "macappstore://apps.apple.com/app/id\(appStoreID)?action=write-review"
    )!

    /// Strong reference — NSWindow doesn't retain itself when shown via makeKeyAndOrderFront.
    private static var controller: NSWindowController?
    /// Saved so we can restore .accessory after the window closes.
    private static var previousActivationPolicy: NSApplication.ActivationPolicy = .accessory

    /// Opens the review window, or brings it to front if already open.
    static func show() {
        if let existing = controller?.window {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }

        previousActivationPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)

        // Apply the frame externally (matches NepaliEditorWindow pattern).
        // .resizable is required so SwiftUI's intrinsic-size adjustments
        // don't trip the AppKit layout assertion that fires on non-resizable
        // windows; we set a minSize so users can't shrink it into uselessness.
        let root = ReviewRequestView()
            .frame(minWidth: 380, minHeight: 280)
        let hosting = NSHostingController(rootView: root)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Rate Nepali Calendar"
        window.contentViewController = hosting
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 380, height: 280)
        window.center()

        let wc = NSWindowController(window: window)
        controller = wc

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            Aptabase.shared.trackEvent("review_window_closed")
            controller = nil
            NSApp.setActivationPolicy(previousActivationPolicy)
        }

        Aptabase.shared.trackEvent("review_window_opened")
        NSApp.activate(ignoringOtherApps: true)
        wc.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }

    /// Hand off to the App Store app on the review page. Reliable fallback
    /// when SKStoreReviewController silently suppresses.
    static func openAppStoreReviewPage() {
        Aptabase.shared.trackEvent("review_store_url_opened")
        NSWorkspace.shared.open(writeReviewURL)
    }

    static func close() {
        controller?.close()
    }
}

struct ReviewRequestView: View {
    @Environment(\.requestReview) private var requestReview
    @State private var hasRequested = false
    /// Hidden for the first 2s so Apple's system sheet gets the stage
    /// uncontested — the fallback only reveals if the sheet didn't show
    /// (rate-limited, no App Store account, etc.). Keeps us firmly in the
    /// spirit of guideline 5.6.1, where SKStoreReviewController is the
    /// primary means of requesting a rating.
    @State private var showFallback = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(nepaliCrimson.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "heart.fill")
                    .font(.title)
                    .foregroundStyle(nepaliCrimson)
            }
            .padding(.top, 6)

            Text("Thanks for using Nepali Calendar!")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Apple's rating sheet should appear in a moment.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                if showFallback {
                    Button {
                        ReviewRequestWindow.openAppStoreReviewPage()
                    } label: {
                        Text("Rate in App Store")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(nepaliCrimson)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                Button {
                    ReviewRequestWindow.close()
                } label: {
                    Text("Close")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)
            .animation(.easeInOut(duration: 0.2), value: showFallback)
        }
        .padding(.vertical, 24)
        .onAppear {
            guard !hasRequested else { return }
            hasRequested = true
            // Let the window finish becoming key before asking StoreKit —
            // the sheet attaches to the current key window, and without
            // this delay it may race against window activation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                requestReview()
            }
            // Reveal the fallback only after Apple's sheet has had a chance
            // to appear on its own.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showFallback = true
            }
        }
    }
}
