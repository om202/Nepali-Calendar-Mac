//
//  Nepali_Calendar_AppApp.swift
//  Nepali-Calendar-App
//
//  macOS Menu Bar app showing today's Nepali (BS) date and Nepal time.
//

import SwiftUI
import Combine
import Aptabase

@main
struct Nepali_Calendar_AppApp: App {
    @State private var currentBSDate = BikramSambat.currentNepaliDate()
    @State private var currentTime = BikramSambat.currentNepalTimeComponents()

    private let settings = AppSettings.shared

    init() {
        Aptabase.shared.initialize(appKey: "A-US-0338874577")
        Aptabase.shared.trackEvent("app_launched")
        NetworkMonitor.shared.start()
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
                currentBSDate = BikramSambat.currentNepaliDate()
                currentTime = BikramSambat.currentNepalTimeComponents()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
