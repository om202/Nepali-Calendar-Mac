//
//  BikramSambatConverter.swift
//  Nepali-Calendar-App
//
//  AD ↔ BS date conversion algorithms.
//  Ported from Noble-Calendar/src/utils/BikramSambatUtils.ts
//  and Noble-Calendar/refer_help/nepali_calendar.php
//

import Foundation

// MARK: - BS Date Model

/// A date in the Bikram Sambat calendar.
struct BSDate: Equatable {
    let year: Int
    let month: Int   // 1–12
    let day: Int     // 1–32
}

// MARK: - Converter

/// Converts between Gregorian (AD) and Bikram Sambat (BS) dates.
///
/// The algorithm uses a day-counting method from known reference dates:
///   BS 2000/9/17 ↔ AD 1944/1/1 (for AD→BS)
///   BS 2000/1/1  ↔ AD 1943/4/14 (for BS→AD)
enum BikramSambat {

    // MARK: AD → BS

    /// Convert a Gregorian date to Bikram Sambat.
    ///
    /// - Parameters:
    ///   - yy: Gregorian year (1943–2034)
    ///   - mm: Gregorian month (1–12)
    ///   - dd: Gregorian day (1–31)
    /// - Returns: The equivalent `BSDate`.
    static func adToBS(year yy: Int, month mm: Int, day dd: Int) -> BSDate {
        let defEyy = 1944
        let defNyy = 2000
        let defNmm = 9      // Poush
        let defNdd = 17 - 1

        let monthDays  = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        let lMonthDays = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

        // Count total Gregorian days from reference
        var totalEDays = 0
        for i in 0..<(yy - defEyy) {
            let days = isLeapYear(defEyy + i) ? lMonthDays : monthDays
            for j in 0..<12 { totalEDays += days[j] }
        }
        for i in 0..<(mm - 1) {
            let days = isLeapYear(yy) ? lMonthDays : monthDays
            totalEDays += days[i]
        }
        totalEDays += dd

        // Convert total days to BS
        var j = defNmm
        var totalNDays = defNdd
        var m = defNmm
        var y = defNyy
        var i = 0

        while totalEDays != 0 {
            let bsYear = bsMonthData[y]
            let a = bsYear?[j - 1] ?? 30

            totalNDays += 1

            if totalNDays > a {
                m += 1
                totalNDays = 1
                j += 1
            }

            if m > 12 {
                y += 1
                m = 1
            }

            if j > 12 {
                j = 1
                i += 1
            }

            totalEDays -= 1
        }

        return BSDate(year: y, month: m, day: totalNDays)
    }

    // MARK: BS → AD

    /// Convert a Bikram Sambat date to Gregorian.
    ///
    /// - Parameters:
    ///   - yy: BS year (2000–2090)
    ///   - mm: BS month (1–12)
    ///   - dd: BS day
    /// - Returns: A `Date` in UTC representing the Gregorian equivalent.
    static func bsToAD(year yy: Int, month mm: Int, day dd: Int) -> Date {
        let defEyy = 1943
        let defEmm = 4      // April
        let defEdd = 14 - 1
        let defNyy = 2000

        let monthDays:  [Int] = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        let lMonthDays: [Int] = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

        // Count total BS days from reference
        var totalNDays = 0
        for i in 0..<(yy - defNyy) {
            if let bsYear = bsMonthData[defNyy + i] {
                for j in 0..<12 { totalNDays += bsYear[j] }
            }
        }
        if let targetYear = bsMonthData[yy] {
            for j in 0..<(mm - 1) { totalNDays += targetYear[j] }
        }
        totalNDays += dd

        // Convert to AD
        var totalEDays = defEdd
        var m = defEmm
        var y = defEyy

        while totalNDays != 0 {
            let days = isLeapYear(y) ? lMonthDays : monthDays
            let a = days[m]

            totalEDays += 1

            if totalEDays > a {
                m += 1
                totalEDays = 1
                if m > 12 {
                    y += 1
                    m = 1
                }
            }

            totalNDays -= 1
        }

        var components = DateComponents()
        components.year = y
        components.month = m
        components.day = totalEDays
        components.timeZone = TimeZone(identifier: "UTC")

        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }

    // MARK: Valid Range

    /// The supported BS year range based on available lookup data.
    static let validBSRange = 2000...2090

    /// Check if a BS year is within the supported data range.
    static func isDateInRange(_ date: BSDate) -> Bool {
        validBSRange.contains(date.year)
    }

    // MARK: Convenience

    /// Get the current date/time in Nepal (Kathmandu) and return the BS equivalent.
    /// If the converted date falls outside the supported 2000–2090 BS range,
    /// it is clamped to the nearest boundary to prevent lookup failures.
    static func currentNepaliDate() -> BSDate {
        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = nepalTimeZone

        let year  = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let day   = calendar.component(.day, from: now)

        let result = adToBS(year: year, month: month, day: day)

        // Clamp to valid range to prevent nil table lookups
        if result.year < validBSRange.lowerBound {
            return BSDate(year: 2000, month: 1, day: 1)
        } else if result.year > validBSRange.upperBound {
            return BSDate(year: 2090, month: 12, day: 30)
        }
        return result
    }

    /// Get the current Nepal time components.
    static func currentNepalTimeComponents() -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = nepalTimeZone
        return calendar.dateComponents([.hour, .minute, .weekday], from: Date())
    }

    /// Number of days in a BS month.
    static func daysInMonth(year: Int, month: Int) -> Int {
        guard let yearData = bsMonthData[year],
              month >= 1, month <= 12 else {
            return month <= 6 ? 31 : 30  // fallback
        }
        return yearData[month - 1]
    }

    // MARK: Formatting

    /// Format a BS date in Nepali script (e.g. "२३ फागुन २०८२").
    static func formatNepali(_ date: BSDate) -> String {
        let monthName = bsMonthNamesNepali[date.month - 1]
        return "\(toNepaliNumeral(date.day)) \(monthName) \(toNepaliNumeral(date.year))"
    }

    /// Format a BS date in English (e.g. "23 Falgun 2082").
    static func formatEnglish(_ date: BSDate) -> String {
        let monthName = bsMonthNamesEnglish[date.month - 1]
        return "\(date.day) \(monthName) \(date.year)"
    }

    /// Format Nepal time in 12-hour Nepali numerals (e.g. "०४:३४").
    static func formatNepalTime(_ components: DateComponents) -> String {
        let h = components.hour ?? 0
        let m = components.minute ?? 0
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        let hStr = padNepali(h12)
        let mStr = padNepali(m)
        return "\(hStr):\(mStr)"
    }

    /// Nepali period-of-day label (बिहान/दिउँसो/साँझ/राति).
    static func nepaliPeriod(_ components: DateComponents) -> String {
        let h = components.hour ?? 0
        if h >= 4 && h < 12 { return "बिहान" }      // Morning
        if h >= 12 && h < 16 { return "दिउँसो" }     // Afternoon
        if h >= 16 && h < 20 { return "साँझ" }       // Evening
        return "राति"                                  // Night
    }

    /// English AM/PM period.
    static func englishPeriod(_ components: DateComponents) -> String {
        let h = components.hour ?? 0
        return h >= 12 ? "PM" : "AM"
    }

    /// Format Nepal time in 24-hour Nepali numerals (e.g. "१६:३४").
    static func formatNepalTime24h(_ components: DateComponents) -> String {
        let h = components.hour ?? 0
        let m = components.minute ?? 0
        let hStr = padNepali(h)
        let mStr = padNepali(m)
        return "\(hStr):\(mStr)"
    }

    /// Format Nepal time in English 12-hour format (e.g. "4:34 AM").
    static func formatNepalTime12hEnglish(_ components: DateComponents) -> String {
        let h = components.hour ?? 0
        let m = components.minute ?? 0
        let period = h >= 12 ? "PM" : "AM"
        let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return String(format: "%d:%02d %@", h12, m, period)
    }

    /// Left-pad a number to 2 digits as Nepali numerals (e.g. 4 → "०४").
    private static func padNepali(_ num: Int) -> String {
        let str = toNepaliNumeral(num)
        return str.count < 2 ? "०" + str : str
    }

    /// Day of week name in Nepali for a given BS date.
    static func dayOfWeekNepali(_ date: BSDate) -> String {
        let adDate = bsToAD(year: date.year, month: date.month, day: date.day)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let weekday = cal.component(.weekday, from: adDate) - 1 // 0=Sun
        return dayNamesNepali[weekday]
    }

    /// Day of week name in English for a given BS date.
    static func dayOfWeekEnglish(_ date: BSDate) -> String {
        let adDate = bsToAD(year: date.year, month: date.month, day: date.day)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let weekday = cal.component(.weekday, from: adDate) - 1 // 0=Sun
        return dayNamesEnglish[weekday]
    }

    // MARK: Helpers

    /// Check if a Gregorian year is a leap year.
    static func isLeapYear(_ year: Int) -> Bool {
        if year % 100 == 0 { return year % 400 == 0 }
        return year % 4 == 0
    }
}
