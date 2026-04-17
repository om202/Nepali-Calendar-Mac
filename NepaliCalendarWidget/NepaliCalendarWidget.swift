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

    // AD (English) date parts — always Nepal Time
    let adDay: String          // e.g. "8"
    let adMonthYear: String    // e.g. "March 2026"
    let adDayOfWeek: String    // e.g. "Sunday"
}

// MARK: - Timeline Provider

struct NepaliCalendarProvider: TimelineProvider {

    func placeholder(in context: Context) -> NepaliDateEntry {
        makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (NepaliDateEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NepaliDateEntry>) -> Void) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = nepalTimeZone

        let startOfToday = calendar.startOfDay(for: Date())

        // Pre-generate the next 4 days so the visible date flips at Nepal midnight
        // even if macOS defers a fresh timeline request (sleep, low power, etc.).
        var entries: [NepaliDateEntry] = []
        for offset in 0..<4 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else {
                continue
            }
            entries.append(makeEntry(for: day))
        }

        // Ask for a refresh a day before we run out of entries.
        let refreshAfter = calendar.date(byAdding: .day, value: 3, to: startOfToday)
            ?? Date().addingTimeInterval(3 * 86_400)

        completion(Timeline(entries: entries, policy: .after(refreshAfter)))
    }

    private func makeEntry(for date: Date) -> NepaliDateEntry {
        let bsDate = BikramSambat.bsDate(from: date)

        // BS parts
        let bsDay = toNepaliNumeral(bsDate.day)
        let bsMonthName = bsMonthNamesNepali[bsDate.month - 1]
        let bsMonthYear = "\(bsMonthName) \(toNepaliNumeral(bsDate.year))"
        let bsDayOfWeek = BikramSambat.dayOfWeekNepali(bsDate)

        // AD parts — always interpret `date` in Nepal timezone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = nepalTimeZone
        let adDay = "\(calendar.component(.day, from: date))"
        let monthFormatter = DateFormatter()
        monthFormatter.timeZone = nepalTimeZone
        monthFormatter.dateFormat = "MMMM yyyy"
        let adMonthYear = monthFormatter.string(from: date)
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

// MARK: - Deep link

private let widgetOpenURL = URL(string: "nepalicalendar://today")

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.bsDayOfWeek), \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) {
            crimsonGradient
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
                .fill(.white.opacity(0.28))
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(entry.bsDayOfWeek), \(entry.bsDay) \(entry.bsMonthYear). " +
            "\(entry.adDayOfWeek), \(entry.adDay) \(entry.adMonthYear)."
        )
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) {
            crimsonGradient
        }
    }
}

// MARK: - Shared gradient

private let crimsonGradient = LinearGradient(
    colors: [
        Color(red: 0.86, green: 0.08, blue: 0.24),
        Color(red: 0.50, green: 0.00, blue: 0.10)
    ],
    startPoint: .top,
    endPoint: .bottom
)

// MARK: - Widget Configuration

struct NepaliCalendarWidget: Widget {
    let kind = "NepaliCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            NepaliCalendarEntryView(entry: entry)
        }
        .configurationDisplayName("Nepali Calendar")
        .description("Today's date in Bikram Sambat.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct NepaliCalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        NepaliCalendarWidget()
        ILoveNepalWidget()
    }
}

// MARK: - I Love Nepal Widget

struct ILoveNepalWidgetView: View {
    let entry: NepaliDateEntry

    var body: some View {
        VStack(alignment: .center, spacing: 4) {

            Spacer(minLength: 0)

            // I Love
            HStack(spacing: 8) {
                Text("I Love")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill")
                    .foregroundStyle(nepaliCrimson)
                    .font(.system(size: 22))
            }

            // Nepal
            HStack(spacing: 8) {
                Text("Nepal")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Image("NepaliFlag")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 22)
            }

            Spacer(minLength: 6)

            // Date and time info at the bottom.
            // `Text(_, style: .time)` auto-updates without needing timeline reloads.
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)

                Text(entry.date, style: .time)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .environment(\.timeZone, nepalTimeZone)
            }
            .padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Nepal. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.14),
                    Color(red: 0.08, green: 0.08, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct ILoveNepalWidget: Widget {
    let kind = "ILoveNepalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveNepalWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Nepal")
        .description("A small tribute to Nepal, with today's BS date.")
        .supportedFamilies([.systemSmall])
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

#Preview("I Love Nepal", as: .systemSmall) {
    ILoveNepalWidget()
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
