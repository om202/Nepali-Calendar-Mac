//
//  ContentView.swift
//  Nepali-Calendar-App
//
//  Popover UI shown when clicking the menu bar item.
//  Home is intentionally minimal: Nepal time, today's festival, and the
//  viewed BS/AD date. Market data, converter, settings, and about live in
//  their own tabs.
//

import SwiftUI
import StoreKit
import Aptabase

// MARK: - Root Popover (Tab Container)

struct MenuBarPopoverView: View {
    @State private var selectedTab = 0
    @State private var lastNewsOpenDate: Date = UserDefaults.standard.object(forKey: "lastNewsOpenDate") as? Date ?? .distantPast

    /// True when the News tab hasn't been viewed in 5+ minutes.
    private var hasNewNews: Bool {
        Date().timeIntervalSince(lastNewsOpenDate) >= 300
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab content
            Group {
                switch selectedTab {
                case 0: CalendarTabView()
                case 1: NewsView()
                case 2: CurrencyView()
                case 3: ConverterView()
                case 4: WidgetsView()
                case 5: SettingsTabView(showAbout: { selectedTab = 6 })
                case 6: InfoPaneView(onDone: { selectedTab = 5 })
                default: CalendarTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Custom tab bar
            HStack(spacing: 0) {
                tabButton(title: "Calendar", icon: "calendar", tag: 0)
                tabButton(title: "Widgets", icon: "rectangle.3.group", tag: 4)
                tabButton(title: "News", icon: "newspaper", tag: 1, showDot: hasNewNews)
                tabButton(title: "Converter", icon: "arrow.triangle.2.circlepath", tag: 3)
                tabButton(title: "Settings", icon: "gearshape", tag: 5)
                quitButton
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .frame(width: 380, height: 545)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            Aptabase.shared.trackEvent("popover_opened")
        }
        .onDisappear {
            Aptabase.shared.flush()
        }
    }

    private var quitButton: some View {
        Button {
            let alert = NSAlert()
            alert.messageText = "Quit Nepali Calendar?"
            alert.informativeText = "Are you sure you want to quit?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Quit")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn {
                Aptabase.shared.trackEvent("quit_button_tapped")
                Aptabase.shared.flush()
                // Give the fire-and-forget flush Task time to POST before we die.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NSApplication.shared.terminate(nil)
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "power")
                    .font(.title2)
                Text("Quit")
                    .font(.system(size: 10))
            }
            .foregroundStyle(Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("q")
        .accessibilityLabel("Quit Nepali Calendar (Pro)")
    }

    @ViewBuilder
    private func tabButton(title: String, icon: String, tag: Int, showDot: Bool = false) -> some View {
        let isSelected = selectedTab == tag
        let highlight = showDot && !isSelected
        Button {
            if selectedTab != tag {
                selectedTab = tag
                if tag == 0 {
                    Aptabase.shared.trackEvent("calendar_tab_opened")
                } else if tag == 1 {
                    let now = Date()
                    lastNewsOpenDate = now
                    UserDefaults.standard.set(now, forKey: "lastNewsOpenDate")
                    Aptabase.shared.trackEvent("news_tab_opened")
                } else if tag == 4 {
                    Aptabase.shared.trackEvent("widgets_tab_opened")
                } else if tag == 5 {
                    Aptabase.shared.trackEvent("settings_opened")
                }
            }
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.title2)
                    if highlight {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .offset(x: 3, y: -2)
                    }
                }
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundStyle(isSelected ? nepaliCrimson : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calendar Tab

struct CalendarTabView: View {
    @State private var bsDate = BikramSambat.currentNepaliDate()
    @State private var todayInfo: DayData?
    @State private var dayOffset: Int = 0
    @State private var showCopied = false

    private let calendarData = CalendarDataService.shared
    private let fuelWeather = FuelWeatherService.shared

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header — Nepal Time
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    if let w = fuelWeather.weather {
                        Text("Kathmandu,")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: w.symbolName)
                            .symbolRenderingMode(.hierarchical)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(w.temperatureString) \(w.conditionText)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Kathmandu, Nepal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                TimelineView(.everyMinute) { _ in
                    let time = BikramSambat.currentNepalTimeComponents()
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(BikramSambat.formatNepalTime12hDigitsOnly(time))
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)

                        Text(BikramSambat.englishPeriod(time))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                }

                if let info = viewedDayInfo, !info.f.isEmpty {
                    todayInfoSection(info)
                } else {
                    HeartbeatView()
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                ZStack(alignment: .leading) {
                    LinearGradient(
                        colors: [
                            nepaliCrimson.opacity(0.10),
                            nepaliCrimson.opacity(0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    AnimatedGIFView(resourceName: "nepal_flag_wave")
                        .frame(width: 110, height: 110)
                        .opacity(0.75)
                        .offset(x: -10, y: -12)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    VStack(spacing: 0) {
                        Spacer()
                        UnevenRoundedRectangle(
                            topLeadingRadius: 2,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 2
                        )
                        .fill(LinearGradient(
                            colors: [
                                Color(white: 0.55),
                                Color(white: 0.92),
                                Color(white: 0.60)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: 3, height: 138)
                    }
                    .frame(maxHeight: .infinity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            )
            .clipped()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Nepal Time")
            .accessibilityValue(BikramSambat.formatNepalTime12hEnglish(BikramSambat.currentNepalTimeComponents()))

            Divider()

            // MARK: Date Section with Day Stepper
            VStack(spacing: 8) {
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { dayOffset -= 1 }
                        Aptabase.shared.trackEvent("day_stepped", with: ["direction": "prev"])
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isAtDataStart)

                    Spacer()

                    VStack(spacing: 4) {
                        Text(BikramSambat.formatNepali(viewedDate))
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(viewedDayOfWeekNepali)
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("(\(viewedADDateString))")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { dayOffset += 1 }
                        Aptabase.shared.trackEvent("day_stepped", with: ["direction": "next"])
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isAtDataEnd)
                }
                .padding(.horizontal, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Date")
            .accessibilityValue(BikramSambat.formatEnglish(viewedDate))
            .overlay(alignment: .topTrailing) {
                if dayOffset != 0 {
                    Button("आज") {
                        withAnimation(.easeInOut(duration: 0.15)) { dayOffset = 0 }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.subheadline)
                    .padding(8)
                    .transition(.opacity)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    let bs = BikramSambat.formatNepali(viewedDate)
                    let bsEng = BikramSambat.formatEnglish(viewedDate)
                    let dayNP = viewedDayOfWeekNepali
                    let dayEN = BikramSambat.dayOfWeekEnglish(viewedDate)
                    let ad = viewedADDateString
                    let text = "\(bs)\n\(bsEng)\n\(dayNP) (\(dayEN))\n\(ad)"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    withAnimation { showCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showCopied = false }
                    }
                    Aptabase.shared.trackEvent("date_copied")
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption2)
                        .foregroundStyle(showCopied ? Color.green : Color.secondary.opacity(0.5))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(8)
            }

            Spacer(minLength: 0)
        }
        .onAppear {
            bsDate = BikramSambat.currentNepaliDate()
            loadCalendarData()
            fuelWeather.refreshWeatherIfNeeded()
        }
        .onDisappear {
            dayOffset = 0
        }
    }

    // MARK: Today Info Section

    @ViewBuilder
    private func todayInfoSection(_ info: DayData) -> some View {
        if !info.f.isEmpty {
            Text(info.f)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .truncationMode(.tail)
                .padding(.top, 2)
                .padding(.horizontal, 16)
        }
    }

    // MARK: Data Loading

    private func loadCalendarData() {
        todayInfo = calendarData.todayInfo()
    }

    // MARK: Viewed Date Computation

    /// The BS date shifted by dayOffset from today.
    private var viewedDate: BSDate {
        stepBSDate(bsDate, by: dayOffset)
    }

    /// True when the viewed date has reached the start of calendar data.
    private var isAtDataStart: Bool {
        let d = viewedDate
        return d.year <= CalendarDataService.minYear && d.month == 1 && d.day == 1
    }

    /// True when the viewed date has reached the end of calendar data.
    private var isAtDataEnd: Bool {
        let d = viewedDate
        guard d.year >= CalendarDataService.maxYear, d.month == 12 else { return false }
        let maxDay = BikramSambat.daysInMonth(year: d.year, month: 12)
        return d.day >= maxDay
    }

    /// DayData for the currently viewed date.
    private var viewedDayInfo: DayData? {
        calendarData.dayInfo(for: viewedDate)
    }

    /// Day of week in Nepali for the viewed date.
    private var viewedDayOfWeekNepali: String {
        BikramSambat.dayOfWeekNepali(viewedDate)
    }

    /// Formatted AD date string for the viewed date.
    private var viewedADDateString: String {
        let adDate = BikramSambat.bsToAD(year: viewedDate.year, month: viewedDate.month, day: viewedDate.day)
        return Self.adDateFormatter.string(from: adDate)
    }

    /// Step a BSDate forward or backward by N days.
    private func stepBSDate(_ date: BSDate, by offset: Int) -> BSDate {
        if offset == 0 { return date }

        var y = date.year
        var m = date.month
        var d = date.day

        if offset > 0 {
            for _ in 0..<offset {
                d += 1
                let dim = BikramSambat.daysInMonth(year: y, month: m)
                if d > dim {
                    d = 1
                    m += 1
                    if m > 12 { m = 1; y += 1 }
                }
            }
        } else {
            for _ in 0..<(-offset) {
                d -= 1
                if d < 1 {
                    m -= 1
                    if m < 1 { m = 12; y -= 1 }
                    d = BikramSambat.daysInMonth(year: y, month: m)
                }
            }
        }

        return BSDate(year: y, month: m, day: d)
    }

    /// Reusable formatter — DateFormatter is expensive to allocate.
    private static let adDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        f.timeZone = nepalTimeZone
        return f
    }()
}

// MARK: - Heartbeat View

private struct HeartbeatView: View {
    @State private var beating = false

    var body: some View {
        HStack(spacing: 4) {
            Text("I Love")
                .font(.callout)
                .foregroundStyle(.secondary)
            Image(systemName: "heart.fill")
                .font(.callout)
                .foregroundStyle(nepaliCrimson)
                .scaleEffect(beating ? 1.3 : 1.0)
                .animation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true),
                    value: beating
                )
            Text("Nepal")
                .font(.callout)
                .foregroundStyle(.secondary)
            Image("NepaliFlag")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)
        }
        .onAppear { beating = true }
        .onDisappear { beating = false }
    }
}

#Preview {
    MenuBarPopoverView()
        .frame(width: 380)
}
