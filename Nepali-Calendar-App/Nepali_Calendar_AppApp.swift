//
//  Nepali_Calendar_AppApp.swift
//  Nepali-Calendar-App
//
//  macOS Menu Bar app showing today's Nepali (BS) date and Nepal time.
//

import SwiftUI
import Combine
import WidgetKit
import Aptabase

@main
struct Nepali_Calendar_AppApp: App {
    @State private var currentBSDate = BikramSambat.currentNepaliDate()
    @State private var currentTime = BikramSambat.currentNepalTimeComponents()

    private let settings = AppSettings.shared

    init() {
        // Short flush interval so menu-bar sessions (often <60s) don't lose events.
        Aptabase.shared.initialize(
            appKey: "A-US-0338874577",
            with: InitOptions(flushInterval: NSNumber(value: 2.0))
        )
        Aptabase.shared.trackEvent("app_launched")
        NetworkMonitor.shared.start()
        // Refresh widgets on launch in case the system/timezone/day changed
        // while the app was closed. Widget itself pre-generates 4 daily
        // entries, so routine use does not need further reloads.
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Timer: 30s with 5s tolerance — at most ~30s stale for HH:MM display.
    private let timer = Timer.publish(every: 30, tolerance: 5, on: .main, in: .common).autoconnect()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView()
        } label: {
            HStack(spacing: 4) {
                Image("NepaliFlag")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                Text(" \(settings.menuBarStyle.format(bsDate: currentBSDate, time: currentTime))")
            }
            .onReceive(timer) { _ in
                let newBSDate = BikramSambat.currentNepaliDate()
                let dayRolled = newBSDate != currentBSDate
                currentBSDate = newBSDate
                currentTime = BikramSambat.currentNepalTimeComponents()
                if dayRolled {
                    // Belt-and-suspenders: widget already pre-generates the
                    // next few days, but this catches extended sleep/resume.
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
