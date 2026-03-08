//
//  NepaliCalendarWidget.swift
//  NepaliCalendarWidget
//
//  macOS Widget displaying today's Nepali (BS) date.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct NepaliDateEntry: TimelineEntry {
    let date: Date

    // BS (Nepali) date parts
    let bsDay: String          // Nepali numeral, e.g. "२४"
    let bsMonthYear: String    // e.g. "फागुन २०८२"
    let bsDayOfWeek: String    // e.g. "आइतबार"

    // AD (English) date parts
    let adDay: String          // e.g. "8"
    let adMonthYear: String    // e.g. "March 2026"
    let adDayOfWeek: String    // e.g. "Sunday"
}

// MARK: - Timeline Provider

struct NepaliCalendarProvider: TimelineProvider {

    func placeholder(in context: Context) -> NepaliDateEntry {
        makeEntry(from: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (NepaliDateEntry) -> Void) {
        completion(makeEntry(from: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NepaliDateEntry>) -> Void) {
        let entry = makeEntry(from: Date())

        // Refresh at next midnight Nepal time
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = nepalTimeZone
        let nextMidnight = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)

        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func makeEntry(from date: Date) -> NepaliDateEntry {
        let bsDate = BikramSambat.currentNepaliDate()

        // BS parts
        let bsDay = toNepaliNumeral(bsDate.day)
        let bsMonthName = bsMonthNamesNepali[bsDate.month - 1]
        let bsMonthYear = "\(bsMonthName) \(toNepaliNumeral(bsDate.year))"
        let bsDayOfWeek = BikramSambat.dayOfWeekNepali(bsDate)

        // AD parts
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = nepalTimeZone
        let now = Date()
        let adDay = "\(calendar.component(.day, from: now))"
        let monthFormatter = DateFormatter()
        monthFormatter.timeZone = nepalTimeZone
        monthFormatter.dateFormat = "MMMM yyyy"
        let adMonthYear = monthFormatter.string(from: now)
        let adDayOfWeek = BikramSambat.dayOfWeekEnglish(bsDate)

        return NepaliDateEntry(
            date: date,
            bsDay: bsDay,
            bsMonthYear: bsMonthYear,
            bsDayOfWeek: bsDayOfWeek,
            adDay: adDay,
            adMonthYear: adMonthYear,
            adDayOfWeek: adDayOfWeek
        )
    }
}

// MARK: - Widget Entry View (routes to correct size)

struct NepaliCalendarEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NepaliDateEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: NepaliDateEntry

    var body: some View {
        VStack(spacing: 4) {
            Text(entry.bsMonthYear)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            Text(entry.bsDay)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)

            Text(entry.bsDayOfWeek)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.86, green: 0.08, blue: 0.24),
                    Color(red: 0.50, green: 0.00, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: NepaliDateEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: Nepali date
            VStack(spacing: 4) {
                Text(entry.bsMonthYear)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                Text(entry.bsDay)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)

                Text(entry.bsDayOfWeek)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 1)
                .padding(.vertical, 16)

            // Right: English date
            VStack(spacing: 4) {
                Text(entry.adMonthYear)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                Text(entry.adDay)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)

                Text(entry.adDayOfWeek)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.86, green: 0.08, blue: 0.24),
                    Color(red: 0.50, green: 0.00, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Widget Configuration

struct NepaliCalendarWidget: Widget {
    let kind = "NepaliCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            NepaliCalendarEntryView(entry: entry)
        }
        .configurationDisplayName("Nepali Calendar")
        .description("Keep track of Nepali date.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle (entry point)

@main
struct NepaliCalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        NepaliCalendarWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    NepaliCalendarWidget()
} timeline: {
    NepaliDateEntry(
        date: Date(),
        bsDay: "२४",
        bsMonthYear: "फागुन २०८२",
        bsDayOfWeek: "आइतबार",
        adDay: "8",
        adMonthYear: "March 2026",
        adDayOfWeek: "Sunday"
    )
}

#Preview("Medium", as: .systemMedium) {
    NepaliCalendarWidget()
} timeline: {
    NepaliDateEntry(
        date: Date(),
        bsDay: "२४",
        bsMonthYear: "फागुन २०८२",
        bsDayOfWeek: "आइतबार",
        adDay: "8",
        adMonthYear: "March 2026",
        adDayOfWeek: "Sunday"
    )
}
