//
//  AppSettings.swift
//  Nepali-Calendar-App
//
//  User-configurable settings persisted via UserDefaults.
//

import Foundation
import ServiceManagement

// MARK: - Menu Bar Display Style

/// What to show in the macOS menu bar text.
enum MenuBarDisplayStyle: String, CaseIterable, Identifiable, Hashable {
    // Nepali variants
    case dateAndTime       = "dateAndTime"
    case nepaliDate        = "nepaliDate"
    case nepalTime         = "nepalTime"
    case dayAndDate        = "dayAndDate"
    // English variants
    case englishDateAndTime = "englishDateAndTime"
    case englishDate       = "englishDate"
    case englishTime       = "englishTime"
    case englishDayAndDate = "englishDayAndDate"

    var id: String { rawValue }

    /// Live preview of what this style looks like with the current date/time.
    var label: String {
        let bsDate = BikramSambat.currentNepaliDate()
        let time = BikramSambat.currentNepalTimeComponents()
        return format(bsDate: bsDate, time: time)
    }

    /// Section: "नेपाली" or "English"
    var section: String {
        switch self {
        case .dateAndTime, .nepaliDate, .nepalTime, .dayAndDate:
            return "नेपाली"
        case .englishDateAndTime, .englishDate, .englishTime, .englishDayAndDate:
            return "English"
        }
    }

    /// Format the menu bar string for the current Nepal date/time.
    func format(bsDate: BSDate, time: DateComponents) -> String {
        let h = time.hour ?? 0
        let m = time.minute ?? 0
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        let period = BikramSambat.englishPeriod(time)

        // Pad a Nepali-numeral hour/minute string to at least 2 digits with "०".
        func padNepali(_ n: Int) -> String {
            let s = toNepaliNumeral(n)
            return s.count < 2 ? "०" + s : s
        }

        switch self {
        case .nepaliDate:
            return BikramSambat.formatNepali(bsDate)

        case .englishDate:
            return BikramSambat.formatEnglish(bsDate)

        case .nepalTime:
            return "\(padNepali(h12)):\(padNepali(m)) \(period)"

        case .englishTime:
            return "\(String(format: "%d:%02d", h12, m)) \(period)"

        case .dateAndTime:
            let monthName = bsMonthNamesNepali[bsDate.month - 1]
            return "\(toNepaliNumeral(bsDate.day)) \(monthName) · \(padNepali(h12)):\(padNepali(m)) \(period)"

        case .englishDateAndTime:
            let monthName = bsMonthNamesEnglish[bsDate.month - 1]
            return "\(bsDate.day) \(monthName) · \(String(format: "%d:%02d", h12, m)) \(period)"

        case .dayAndDate:
            let adDate = BikramSambat.bsToAD(year: bsDate.year, month: bsDate.month, day: bsDate.day)
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            let weekday = cal.component(.weekday, from: adDate) - 1
            let dayName = dayNamesNepaliShort[weekday]
            let monthName = bsMonthNamesNepali[bsDate.month - 1]
            return "\(dayName) \(toNepaliNumeral(bsDate.day)) \(monthName)"

        case .englishDayAndDate:
            let adDate = BikramSambat.bsToAD(year: bsDate.year, month: bsDate.month, day: bsDate.day)
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            let weekday = cal.component(.weekday, from: adDate) - 1
            let dayShort = String(dayNamesEnglish[weekday].prefix(3))
            let monthName = bsMonthNamesEnglish[bsDate.month - 1]
            return "\(dayShort) \(bsDate.day) \(monthName)"
        }
    }
}

// MARK: - Settings Store

@Observable
class AppSettings {
    /// Singleton
    static let shared = AppSettings()

    /// What to display in the menu bar.
    var menuBarStyle: MenuBarDisplayStyle {
        didSet { UserDefaults.standard.set(menuBarStyle.rawValue, forKey: "menuBarStyle") }
    }

    /// Whether the app launches at login.
    var launchAtLogin: Bool {
        didSet {
            if #available(macOS 13.0, *) {
                do {
                    if launchAtLogin {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    // Login item registration failed — non-critical, ignore silently
                }
            }
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        }
    }

    private init() {
        // Load persisted values
        let styleRaw = UserDefaults.standard.string(forKey: "menuBarStyle") ?? MenuBarDisplayStyle.dateAndTime.rawValue
        self.menuBarStyle = MenuBarDisplayStyle(rawValue: styleRaw) ?? .dateAndTime
        self.launchAtLogin = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? false
    }
}
