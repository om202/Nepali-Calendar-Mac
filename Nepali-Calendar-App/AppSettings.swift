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
    case dateAndTime   = "dateAndTime"
    case nepaliDate    = "nepaliDate"
    case englishDate   = "englishDate"
    case nepalTime     = "nepalTime"
    case dayAndDate    = "dayAndDate"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nepaliDate:  return "नेपाली मिति (२४ फागुन २०८२)"
        case .englishDate: return "English Date (24 Falgun 2082)"
        case .nepalTime:   return "Nepal Time (०४:३४ AM)"
        case .dateAndTime: return "Date + Time (२४ फागुन · ०४:३४)"
        case .dayAndDate:  return "Day + Date (आइत २४ फागुन)"
        }
    }

    /// Format the menu bar string for the current Nepal date/time.
    func format(bsDate: BSDate, time: DateComponents) -> String {
        switch self {
        case .nepaliDate:
            return "🇳🇵 \(BikramSambat.formatNepali(bsDate))"

        case .englishDate:
            return "🇳🇵 \(BikramSambat.formatEnglish(bsDate))"

        case .nepalTime:
            let h = time.hour ?? 0
            let m = time.minute ?? 0
            let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
            let hStr = toNepaliNumeral(h12).count < 2 ? "०" + toNepaliNumeral(h12) : toNepaliNumeral(h12)
            let mStr = toNepaliNumeral(m).count < 2 ? "०" + toNepaliNumeral(m) : toNepaliNumeral(m)
            let period = BikramSambat.englishPeriod(time)
            return "🇳🇵 \(hStr):\(mStr) \(period)"

        case .dateAndTime:
            let monthName = bsMonthNamesNepali[bsDate.month - 1]
            let h = time.hour ?? 0
            let m = time.minute ?? 0
            let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
            let hStr = toNepaliNumeral(h12).count < 2 ? "०" + toNepaliNumeral(h12) : toNepaliNumeral(h12)
            let mStr = toNepaliNumeral(m).count < 2 ? "०" + toNepaliNumeral(m) : toNepaliNumeral(m)
            let period = BikramSambat.englishPeriod(time)
            return "🇳🇵 \(toNepaliNumeral(bsDate.day)) \(monthName) · \(hStr):\(mStr) \(period)"

        case .dayAndDate:
            let adDate = BikramSambat.bsToAD(year: bsDate.year, month: bsDate.month, day: bsDate.day)
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            let weekday = cal.component(.weekday, from: adDate) - 1
            let dayName = dayNamesNepaliShort[weekday]
            let monthName = bsMonthNamesNepali[bsDate.month - 1]
            return "🇳🇵 \(dayName) \(toNepaliNumeral(bsDate.day)) \(monthName)"
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

    /// Whether to show the 🇳🇵 flag emoji in menu bar.
    var showFlag: Bool {
        didSet { UserDefaults.standard.set(showFlag, forKey: "showFlag") }
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
                    print("Launch at login error: \(error)")
                }
            }
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        }
    }

    private init() {
        // Load persisted values
        let styleRaw = UserDefaults.standard.string(forKey: "menuBarStyle") ?? MenuBarDisplayStyle.dateAndTime.rawValue
        self.menuBarStyle = MenuBarDisplayStyle(rawValue: styleRaw) ?? .dateAndTime
        self.showFlag = UserDefaults.standard.object(forKey: "showFlag") as? Bool ?? true
        self.launchAtLogin = UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? false
    }
}
