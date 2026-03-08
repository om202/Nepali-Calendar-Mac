//
//  Nepali_Calendar_AppApp.swift
//  Nepali-Calendar-App
//
//  macOS Menu Bar app showing today's Nepali (BS) date and Nepal time.
//

import SwiftUI
import Combine

@main
struct Nepali_Calendar_AppApp: App {
    @State private var currentBSDate = BikramSambat.currentNepaliDate()
    @State private var currentTime = BikramSambat.currentNepalTimeComponents()

    private let settings = AppSettings.shared

    /// Timer that updates the menu bar title every 30s (HH:MM only — no seconds displayed).
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView()
        } label: {
            Text(settings.menuBarStyle.format(bsDate: currentBSDate, time: currentTime))
                .onReceive(timer) { _ in
                    currentBSDate = BikramSambat.currentNepaliDate()
                    currentTime = BikramSambat.currentNepalTimeComponents()
                }
        }
        .menuBarExtraStyle(.window)
    }
}
