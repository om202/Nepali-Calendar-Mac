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
        .frame(width: 380, height: 615)
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
    @State private var dayOffset: Int = 0
    @State private var showCopied = false
    @AppStorage("home.calendarExpanded") private var calendarExpanded: Bool = false

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
                        Text(spacedTimeString(BikramSambat.formatNepalTime12hDigitsOnly(time)))
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .tracking(-1.5)
                            .foregroundStyle(.primary)

                        Text(BikramSambat.englishPeriod(time))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
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
            .padding(.vertical, 24)
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
                    dayStepButton(systemImage: "chevron.left", disabled: isAtDataStart) {
                        withAnimation(.easeInOut(duration: 0.15)) { dayOffset -= 1 }
                        Aptabase.shared.trackEvent("day_stepped", with: ["direction": "prev"])
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            // Invisible mirror keeps the title centered
                            copyDateButton
                                .hidden()
                                .accessibilityHidden(true)

                            Text(BikramSambat.formatNepali(viewedDate))
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.primary)

                            copyDateButton
                        }

                        Text(viewedDayOfWeekNepali)
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(viewedADDateString)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    dayStepButton(systemImage: "chevron.right", disabled: isAtDataEnd) {
                        withAnimation(.easeInOut(duration: 0.15)) { dayOffset += 1 }
                        Aptabase.shared.trackEvent("day_stepped", with: ["direction": "next"])
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Date")
            .accessibilityValue(BikramSambat.formatEnglish(viewedDate))

            Divider()

            // MARK: Full Calendar Disclosure
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    calendarExpanded.toggle()
                }
                Aptabase.shared.trackEvent("full_calendar_toggled", with: ["expanded": calendarExpanded ? "true" : "false"])
            } label: {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(nepaliCrimson.gradient)
                        .frame(width: 20, height: 20)
                        .overlay {
                            Image(systemName: "calendar")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                    Text("Full Nepali Patro")
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(calendarExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if calendarExpanded {
                Divider()

                // MARK: Month Grid
                MonthGridView(
                    viewedDate: viewedDate,
                    todayDate: bsDate,
                    onSelectDay: { selected in
                        jump(to: selected)
                        Aptabase.shared.trackEvent("grid_day_selected")
                    }
                )
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // MARK: Month Nav Footer
                monthNavFooter
            } else {
                Divider()

                // MARK: Nepali Typer
                NepaliTyperView()

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            bsDate = BikramSambat.currentNepaliDate()
            fuelWeather.refreshWeatherIfNeeded()
        }
        .onDisappear {
            dayOffset = 0
        }
    }

    // MARK: Time String — add gap on both sides of the colon

    /// Returns an `AttributedString` that widens the space around ":" without
    /// affecting other digit spacing (which is monospaced-tracked).
    private func spacedTimeString(_ raw: String) -> AttributedString {
        var s = AttributedString(raw)
        if let colon = s.range(of: ":") {
            s[colon].kern = 5
            s[colon].foregroundColor = .secondary
            if colon.lowerBound > s.startIndex {
                let prev = s.index(beforeCharacter: colon.lowerBound)
                s[prev..<colon.lowerBound].kern = 5
            }
        }
        return s
    }

    // MARK: Copy Date Button

    private var copyDateButton: some View {
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
                .font(.footnote)
                .foregroundStyle(showCopied ? Color.green : Color.secondary.opacity(0.6))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showCopied ? "Copied" : "Copy date")
        .accessibilityHint("Copies the viewed date in BS and AD formats to clipboard.")
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

    /// Month navigation footer: prev-month chevron, "आज" capsule, next-month chevron.
    private var monthNavFooter: some View {
        HStack(spacing: 6) {
            monthNavButton(systemImage: "chevron.left", disabled: isAtMonthStart) {
                jump(to: monthJump(by: -1))
                Aptabase.shared.trackEvent("month_stepped", with: ["direction": "prev"])
            }

            Button {
                withAnimation(.easeInOut(duration: 0.15)) { dayOffset = 0 }
                Aptabase.shared.trackEvent("today_tapped")
            } label: {
                let active = dayOffset != 0
                Text("आज")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(active ? Color.white : Color.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(active ? nepaliCrimson.opacity(0.85) : Color.secondary.opacity(0.12))
                    )
                    .overlay(
                        Capsule().strokeBorder(active ? Color.clear : Color.secondary.opacity(0.25), lineWidth: 0.5)
                    )
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)

            monthNavButton(systemImage: "chevron.right", disabled: isAtMonthEnd) {
                jump(to: monthJump(by: 1))
                Aptabase.shared.trackEvent("month_stepped", with: ["direction": "next"])
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
    }

    /// Jump viewed date to an arbitrary BS date by adjusting dayOffset.
    private func jump(to target: BSDate) {
        let offset = BikramSambat.daysBetween(bsDate, target)
        withAnimation(.easeInOut(duration: 0.15)) { dayOffset = offset }
    }

    /// Target BS date for a month-step (±1), preserving day-of-month when possible.
    private func monthJump(by delta: Int) -> BSDate {
        var y = viewedDate.year
        var m = viewedDate.month + delta
        if m < 1 { m = 12; y -= 1 }
        if m > 12 { m = 1; y += 1 }
        let dim = BikramSambat.daysInMonth(year: y, month: m)
        let d = min(viewedDate.day, dim)
        return BSDate(year: y, month: m, day: d)
    }

    /// True when the viewed month is the first month of available data.
    private var isAtMonthStart: Bool {
        viewedDate.year <= CalendarDataService.minYear && viewedDate.month == 1
    }

    /// True when the viewed month is the last month of available data.
    private var isAtMonthEnd: Bool {
        viewedDate.year >= CalendarDataService.maxYear && viewedDate.month == 12
    }

    @ViewBuilder
    private func dayStepButton(systemImage: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(Color.secondary.opacity(0.10))
                )
                .overlay(
                    Circle().strokeBorder(Color.secondary.opacity(0.22), lineWidth: 0.5)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.3 : 1)
    }

    @ViewBuilder
    private func monthNavButton(systemImage: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.3 : 1)
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
                .frame(width: 16, height: 16)
        }
        .onAppear { beating = true }
        .onDisappear { beating = false }
    }
}

// MARK: - Month Grid View

/// Compact BS month grid shown on the Calendar tab. Displays dates only —
/// no events, tithis, or festival text. Tapping a day selects it in the
/// parent view by updating the shared `dayOffset`.
private struct MonthGridView: View {
    let viewedDate: BSDate
    let todayDate: BSDate
    let onSelectDay: (BSDate) -> Void

    private let calendarData = CalendarDataService.shared

    private static let cornerRadius: CGFloat = 8
    private var borderColor: Color { Color.secondary.opacity(0.25) }

    var body: some View {
        let year = viewedDate.year
        let month = viewedDate.month
        let daysInMonth = BikramSambat.daysInMonth(year: year, month: month)
        let startWeekday = Self.startingWeekday(year: year, month: month)
        let totalCells = startWeekday + daysInMonth
        let rowCount = Int(ceil(Double(totalCells) / 7.0))
        let monthInfo = calendarData.loadMonth(year: year, month: month)

        VStack(spacing: 0) {
            // Weekday header
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayNamesNepaliShort[i])
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(i == 6 ? nepaliCrimson.opacity(0.65) : Color.secondary.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .overlay(alignment: .trailing) {
                            if i < 6 {
                                Rectangle().fill(borderColor).frame(width: 0.5)
                            }
                        }
                }
            }
            .background(Color.secondary.opacity(0.06))
            .overlay(alignment: .bottom) {
                Rectangle().fill(borderColor).frame(height: 0.5)
            }

            // Date rows
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let cellIndex = row * 7 + col
                        let day = cellIndex - startWeekday + 1
                        Group {
                            if day >= 1 && day <= daysInMonth {
                                let info = monthInfo?.days.indices.contains(day - 1) == true
                                    ? monthInfo?.days[day - 1] : nil
                                dayCell(
                                    day: day,
                                    weekday: col,
                                    isHoliday: info?.h ?? false,
                                    isToday: day == todayDate.day && month == todayDate.month && year == todayDate.year,
                                    isSelected: day == viewedDate.day
                                )
                            } else {
                                Color.clear
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(alignment: .trailing) {
                            if col < 6 {
                                Rectangle().fill(borderColor).frame(width: 0.5)
                            }
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    if row < rowCount - 1 {
                        Rectangle().fill(borderColor).frame(height: 0.5)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .strokeBorder(borderColor, lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private func dayCell(day: Int, weekday: Int, isHoliday: Bool, isToday: Bool, isSelected: Bool) -> some View {
        let isSaturday = weekday == 6
        let isRed = isHoliday || isSaturday
        let target = BSDate(year: viewedDate.year, month: viewedDate.month, day: day)

        Button {
            onSelectDay(target)
        } label: {
            ZStack {
                if isToday {
                    nepaliCrimson.opacity(0.40)
                } else if isSelected {
                    nepaliCrimson.opacity(0.10)
                }
                Text(toNepaliNumeral(day))
                    .font(.system(size: 16, weight: isToday ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(
                        isToday
                            ? Color.white
                            : (isRed ? nepaliCrimson.opacity(0.75) : Color.secondary)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day) \(bsMonthNamesEnglish[viewedDate.month - 1]) \(viewedDate.year)")
    }

    /// Weekday index (0=Sun..6=Sat) for the first day of the given BS month.
    private static func startingWeekday(year: Int, month: Int) -> Int {
        let first = BikramSambat.bsToAD(year: year, month: month, day: 1)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.component(.weekday, from: first) - 1
    }
}

#Preview {
    MenuBarPopoverView()
        .frame(width: 380)
}
