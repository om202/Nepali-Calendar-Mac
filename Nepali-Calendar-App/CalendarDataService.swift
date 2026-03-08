//
//  CalendarDataService.swift
//  Nepali-Calendar-App
//
//  Loads and caches festival, holiday, and tithi data from bundled JSON files.
//  Data files are sourced from Noble-Calendar (years 2080–2085 BS).
//

import Foundation

// MARK: - JSON Models (Codable)

/// A single day's data from the calendar JSON.
struct DayData: Codable {
    let n: String       // Nepali numeral date
    let e: String       // English date (day of month)
    let t: String       // Tithi
    let f: String       // Festival name(s)
    let h: Bool         // IsHoliday
    let d: Int          // Day of week (from source, unused — we compute our own)
}

/// Metadata for a month.
struct MonthMetadata: Codable {
    let en: String      // English month description
    let np: String      // Nepali month description
}

/// A full month's data from the calendar JSON.
struct MonthData: Codable {
    let metadata: MonthMetadata
    let days: [DayData]
    let holiFest: [String]
    let marriage: [String]
    let bratabandha: [String]
}

// MARK: - Event Info (Processed)

/// A processed event (festival or holiday) with its BS date.
struct CalendarEvent {
    let bsDate: BSDate
    let festival: String
    let isHoliday: Bool
}

// MARK: - CalendarDataService

/// Loads bundled calendar JSON and provides lookup functions for festivals, holidays, and tithi.
@Observable
class CalendarDataService {
    static let shared = CalendarDataService()

    /// Data range available in the bundle.
    static let minYear = 2080
    static let maxYear = 2085

    /// In-memory cache: "year-month" → MonthData
    private var cache: [String: MonthData] = [:]

    private init() {}

    // MARK: - Loading

    /// Load a month's data from the bundle. Returns nil if unavailable.
    func loadMonth(year: Int, month: Int) -> MonthData? {
        let key = "\(year)-\(month)"
        if let cached = cache[key] { return cached }

        guard year >= Self.minYear, year <= Self.maxYear,
              month >= 1, month <= 12 else { return nil }

        // JSON files are flat in Resources: {year}_{month}.json
        guard let url = Bundle.main.url(
            forResource: "\(year)_\(month)",
            withExtension: "json"
        ) else {
            print("CalendarData: Missing \(year)_\(month).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(MonthData.self, from: data)
            cache[key] = decoded
            return decoded
        } catch {
            print("CalendarData: Failed to decode \(year)/\(month).json — \(error)")
            return nil
        }
    }

    /// Get the DayData for a specific BS date. Returns nil if outside data range.
    func dayInfo(for bsDate: BSDate) -> DayData? {
        guard let monthData = loadMonth(year: bsDate.year, month: bsDate.month) else {
            return nil
        }
        // Days array is 0-indexed but bsDay is 1-indexed
        return monthData.days.first { nepaliToInt($0.n) == bsDate.day }
    }

    /// Get the DayData for today's Nepal date.
    func todayInfo() -> DayData? {
        let today = BikramSambat.currentNepaliDate()
        return dayInfo(for: today)
    }

    // MARK: - Upcoming Events

    /// Get the next N upcoming festivals/holidays starting from tomorrow.
    func upcomingEvents(from bsDate: BSDate, limit: Int = 3) -> [CalendarEvent] {
        var events: [CalendarEvent] = []
        var year = bsDate.year
        var month = bsDate.month
        var day = bsDate.day + 1 // start from tomorrow

        // Walk forward through days
        while events.count < limit {
            // Ensure we don't go beyond data range
            guard year <= Self.maxYear else { break }

            let daysInMonth = BikramSambat.daysInMonth(year: year, month: month)

            // Wrap to next month if needed
            if day > daysInMonth {
                day = 1
                month += 1
                if month > 12 {
                    month = 1
                    year += 1
                }
                continue
            }

            let date = BSDate(year: year, month: month, day: day)
            if let info = dayInfo(for: date) {
                let hasFestival = !info.f.isEmpty
                let isHoliday = info.h
                if hasFestival || isHoliday {
                    events.append(CalendarEvent(
                        bsDate: date,
                        festival: info.f,
                        isHoliday: isHoliday
                    ))
                }
            }

            day += 1
        }

        return events
    }

    // MARK: - Helpers

    /// Convert Nepali numeral string to Int (e.g. "२३" → 23).
    private func nepaliToInt(_ nepali: String) -> Int {
        let nepaliDigits = "०१२३४५६७८९"
        var result = ""
        for char in nepali {
            if let idx = nepaliDigits.firstIndex(of: char) {
                result += String(nepaliDigits.distance(from: nepaliDigits.startIndex, to: idx))
            } else if char.isNumber {
                result += String(char)
            }
        }
        return Int(result) ?? 0
    }
}
