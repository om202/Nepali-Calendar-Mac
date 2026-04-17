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

        // Round down to the start of the current minute in Nepal time.
        // Text(date, style: .time) renders the time of entry.date statically,
        // so we advance entry.date each minute to drive the widgets' clocks.
        let now = Date()
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let currentMinute = calendar.date(from: parts) ?? now

        var entries: [NepaliDateEntry] = []
        for offset in 0..<60 {
            guard let tick = calendar.date(byAdding: .minute, value: offset, to: currentMinute) else {
                continue
            }
            entries.append(makeEntry(for: tick))
        }

        let refreshAfter = calendar.date(byAdding: .minute, value: 50, to: currentMinute)
            ?? now.addingTimeInterval(50 * 60)

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

// MARK: - Nepali Calendar (Dark) Widget

private let darkGradient = LinearGradient(
    colors: [
        Color(red: 0.12, green: 0.12, blue: 0.14),
        Color(red: 0.08, green: 0.08, blue: 0.10)
    ],
    startPoint: .top,
    endPoint: .bottom
)

struct NepaliCalendarDarkEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NepaliDateEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetDarkView(entry: entry)
        default:
            SmallWidgetDarkView(entry: entry)
        }
    }
}

struct SmallWidgetDarkView: View {
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
        .containerBackground(for: .widget) { darkGradient }
    }
}

struct MediumWidgetDarkView: View {
    let entry: NepaliDateEntry

    var body: some View {
        HStack(spacing: 0) {
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

            Rectangle()
                .fill(.white.opacity(0.28))
                .frame(width: 1)
                .padding(.vertical, 16)

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
        .containerBackground(for: .widget) { darkGradient }
    }
}

struct NepaliCalendarDarkWidget: Widget {
    let kind = "NepaliCalendarDarkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            NepaliCalendarDarkEntryView(entry: entry)
        }
        .configurationDisplayName("Nepali Calendar (Dark)")
        .description("Today's date in Bikram Sambat, dark theme.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct NepaliCalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        NepaliCalendarWidget()
        NepaliCalendarDarkWidget()
        ILoveNepalWidget()
        ILoveKathmanduWidget()
        ILovePokharaWidget()
        ILoveLalitpurWidget()
        ILoveBiratnagarWidget()
        ILoveBirgunjWidget()
        ILoveBharatpurWidget()
        ILoveButwalWidget()
        ILoveDharanWidget()
        ILoveJanakpurWidget()
        ILoveHetaudaWidget()
        ILoveNepalgunjWidget()
        ILoveKalaiyaWidget()
        ILoveRajbirajWidget()
        ILoveBhaktapurWidget()
        ILoveGorkhaWidget()
        ILoveTansenWidget()
        ILoveIlamWidget()
        ILoveNamcheWidget()
        ILoveBandipurWidget()
        ILoveJomsomWidget()
        ILoveGaurWidget()
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
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)

                Text(entry.date, style: .time)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
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

// MARK: - Shared background for I Love City widgets

private var iLoveCityBackground: some View {
    LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.12, blue: 0.14),
            Color(red: 0.08, green: 0.08, blue: 0.10)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - I Love Kathmandu

struct ILoveKathmanduWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Kathmandu").font(.system(size: 18, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 14)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Kathmandu. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveKathmanduWidget: Widget {
    let kind = "ILoveKathmanduWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveKathmanduWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Kathmandu")
        .description("A small tribute to Kathmandu, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Pokhara

struct ILovePokharaWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Pokhara").font(.system(size: 22, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 18)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Pokhara. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILovePokharaWidget: Widget {
    let kind = "ILovePokharaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILovePokharaWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Pokhara")
        .description("A small tribute to Pokhara, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Lalitpur

struct ILoveLalitpurWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Lalitpur").font(.system(size: 20, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 16)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Lalitpur. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveLalitpurWidget: Widget {
    let kind = "ILoveLalitpurWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveLalitpurWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Lalitpur")
        .description("A small tribute to Lalitpur, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Biratnagar

struct ILoveBiratnagarWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Biratnagar").font(.system(size: 16, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 12)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Biratnagar. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveBiratnagarWidget: Widget {
    let kind = "ILoveBiratnagarWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveBiratnagarWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Biratnagar")
        .description("A small tribute to Biratnagar, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Birgunj

struct ILoveBirgunjWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Birgunj").font(.system(size: 22, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 18)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Birgunj. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveBirgunjWidget: Widget {
    let kind = "ILoveBirgunjWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveBirgunjWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Birgunj")
        .description("A small tribute to Birgunj, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Bharatpur

struct ILoveBharatpurWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Bharatpur").font(.system(size: 18, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 14)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Bharatpur. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveBharatpurWidget: Widget {
    let kind = "ILoveBharatpurWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveBharatpurWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Bharatpur")
        .description("A small tribute to Bharatpur, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Butwal

struct ILoveButwalWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Butwal").font(.system(size: 24, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 20)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Butwal. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveButwalWidget: Widget {
    let kind = "ILoveButwalWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveButwalWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Butwal")
        .description("A small tribute to Butwal, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Dharan

struct ILoveDharanWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Dharan").font(.system(size: 24, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 20)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Dharan. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveDharanWidget: Widget {
    let kind = "ILoveDharanWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveDharanWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Dharan")
        .description("A small tribute to Dharan, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Janakpur

struct ILoveJanakpurWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Janakpur").font(.system(size: 20, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 16)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Janakpur. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveJanakpurWidget: Widget {
    let kind = "ILoveJanakpurWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveJanakpurWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Janakpur")
        .description("A small tribute to Janakpur, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Hetauda

struct ILoveHetaudaWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Hetauda").font(.system(size: 22, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 18)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Hetauda. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveHetaudaWidget: Widget {
    let kind = "ILoveHetaudaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveHetaudaWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Hetauda")
        .description("A small tribute to Hetauda, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Nepalgunj

struct ILoveNepalgunjWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Nepalgunj").font(.system(size: 18, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 14)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Nepalgunj. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveNepalgunjWidget: Widget {
    let kind = "ILoveNepalgunjWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveNepalgunjWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Nepalgunj")
        .description("A small tribute to Nepalgunj, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Kalaiya

struct ILoveKalaiyaWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Kalaiya").font(.system(size: 22, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 18)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Kalaiya. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveKalaiyaWidget: Widget {
    let kind = "ILoveKalaiyaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveKalaiyaWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Kalaiya")
        .description("A small tribute to Kalaiya, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Rajbiraj

struct ILoveRajbirajWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Rajbiraj").font(.system(size: 20, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 16)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Rajbiraj. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveRajbirajWidget: Widget {
    let kind = "ILoveRajbirajWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveRajbirajWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Rajbiraj")
        .description("A small tribute to Rajbiraj, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Bhaktapur

struct ILoveBhaktapurWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Bhaktapur").font(.system(size: 18, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 14)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Bhaktapur. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveBhaktapurWidget: Widget {
    let kind = "ILoveBhaktapurWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveBhaktapurWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Bhaktapur")
        .description("A small tribute to Bhaktapur, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Gorkha

struct ILoveGorkhaWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Gorkha").font(.system(size: 24, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 20)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Gorkha. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveGorkhaWidget: Widget {
    let kind = "ILoveGorkhaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveGorkhaWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Gorkha")
        .description("A small tribute to Gorkha, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Tansen

struct ILoveTansenWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Tansen").font(.system(size: 24, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 20)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Tansen. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveTansenWidget: Widget {
    let kind = "ILoveTansenWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveTansenWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Tansen")
        .description("A small tribute to Tansen, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Ilam

struct ILoveIlamWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Ilam").font(.system(size: 26, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 22)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Ilam. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveIlamWidget: Widget {
    let kind = "ILoveIlamWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveIlamWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Ilam")
        .description("A small tribute to Ilam, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Namche

struct ILoveNamcheWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Namche").font(.system(size: 24, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 20)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Namche. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveNamcheWidget: Widget {
    let kind = "ILoveNamcheWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveNamcheWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Namche")
        .description("A small tribute to Namche, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Bandipur

struct ILoveBandipurWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Bandipur").font(.system(size: 20, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 16)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Bandipur. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveBandipurWidget: Widget {
    let kind = "ILoveBandipurWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveBandipurWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Bandipur")
        .description("A small tribute to Bandipur, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Jomsom

struct ILoveJomsomWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Jomsom").font(.system(size: 24, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 20)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Jomsom. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveJomsomWidget: Widget {
    let kind = "ILoveJomsomWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveJomsomWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Jomsom")
        .description("A small tribute to Jomsom, with today's BS date.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - I Love Gaur

struct ILoveGaurWidgetView: View {
    let entry: NepaliDateEntry
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("I Love").font(.system(size: 26, weight: .bold, design: .rounded))
                Image(systemName: "heart.fill").foregroundStyle(nepaliCrimson).font(.system(size: 22))
            }
            HStack(spacing: 8) {
                Text("Gaur").font(.system(size: 26, weight: .bold, design: .rounded))
                Image("NepaliFlag").renderingMode(.original).resizable().scaledToFit().frame(height: 22)
            }
            Spacer(minLength: 6)
            VStack(spacing: 2) {
                Text("\(entry.bsDay) \(entry.bsMonthYear)").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white)
                Text(entry.date, style: .time).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(.white.opacity(0.8)).environment(\.timeZone, nepalTimeZone)
            }.padding(.bottom, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("I love Gaur. \(entry.bsDay) \(entry.bsMonthYear)")
        .widgetURL(widgetOpenURL)
        .containerBackground(for: .widget) { iLoveCityBackground }
    }
}

struct ILoveGaurWidget: Widget {
    let kind = "ILoveGaurWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NepaliCalendarProvider()) { entry in
            ILoveGaurWidgetView(entry: entry)
        }
        .configurationDisplayName("I Love Gaur")
        .description("A small tribute to Gaur, with today's BS date.")
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

#Preview("Small Dark", as: .systemSmall) {
    NepaliCalendarDarkWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("Medium Dark", as: .systemMedium) {
    NepaliCalendarDarkWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
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

#Preview("I Love Kathmandu", as: .systemSmall) {
    ILoveKathmanduWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Pokhara", as: .systemSmall) {
    ILovePokharaWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Lalitpur", as: .systemSmall) {
    ILoveLalitpurWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Biratnagar", as: .systemSmall) {
    ILoveBiratnagarWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Birgunj", as: .systemSmall) {
    ILoveBirgunjWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Bharatpur", as: .systemSmall) {
    ILoveBharatpurWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Butwal", as: .systemSmall) {
    ILoveButwalWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Dharan", as: .systemSmall) {
    ILoveDharanWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Janakpur", as: .systemSmall) {
    ILoveJanakpurWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Hetauda", as: .systemSmall) {
    ILoveHetaudaWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Nepalgunj", as: .systemSmall) {
    ILoveNepalgunjWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Kalaiya", as: .systemSmall) {
    ILoveKalaiyaWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Rajbiraj", as: .systemSmall) {
    ILoveRajbirajWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Bhaktapur", as: .systemSmall) {
    ILoveBhaktapurWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Gorkha", as: .systemSmall) {
    ILoveGorkhaWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Tansen", as: .systemSmall) {
    ILoveTansenWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Ilam", as: .systemSmall) {
    ILoveIlamWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Namche", as: .systemSmall) {
    ILoveNamcheWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Bandipur", as: .systemSmall) {
    ILoveBandipurWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Jomsom", as: .systemSmall) {
    ILoveJomsomWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}

#Preview("I Love Gaur", as: .systemSmall) {
    ILoveGaurWidget()
} timeline: {
    NepaliDateEntry(date: Date(), bsDay: "२४", bsMonthYear: "फागुन २०८२", bsDayOfWeek: "आइतबार", adDay: "8", adMonthYear: "March 2026", adDayOfWeek: "Sunday")
}
