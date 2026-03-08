//
//  ContentView.swift
//  Nepali-Calendar-App
//
//  Popover UI shown when clicking the menu bar item.
//  Displays Nepal time, today's date in BS and AD, settings, and Nepal news.
//

import SwiftUI
import Combine
import StoreKit
import Aptabase

// Nepali flag crimson — vivid for dark mode visibility (#E8334A)
private let nepaliCrimson = Color(red: 0.91, green: 0.20, blue: 0.29)

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
            if selectedTab == 0 {
                CalendarTabView()
            } else if selectedTab == 1 {
                NewsView()
            } else if selectedTab == 2 {
                CurrencyView()
            } else {
                ConverterView()
            }

            Divider()

            // Custom tab bar
            HStack(spacing: 0) {
                tabButton(title: "Calendar", icon: "calendar", tag: 0)
                tabButton(title: "News", icon: "newspaper", tag: 1, showDot: hasNewNews)
                tabButton(title: "Currency", icon: "coloncurrencysign.circle", tag: 2)
                tabButton(title: "Converter", icon: "arrow.triangle.2.circlepath", tag: 3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.background)
        }
        .frame(width: 340)
        .background(Color(.windowBackgroundColor))
    }

    @ViewBuilder
    private func tabButton(title: String, icon: String, tag: Int, showDot: Bool = false) -> some View {
        let isSelected = selectedTab == tag
        let highlight = showDot && !isSelected
        Button {
            if selectedTab != tag {
                selectedTab = tag
                if tag == 1 {
                    let now = Date()
                    lastNewsOpenDate = now
                    UserDefaults.standard.set(now, forKey: "lastNewsOpenDate")
                    Aptabase.shared.trackEvent("news_tab_opened")
                }
            }
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.body)
                    if highlight {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .offset(x: 3, y: -2)
                    }
                }
                Text(title)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? nepaliCrimson : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                isSelected ? nepaliCrimson.opacity(0.12) : Color.clear,
                in: RoundedRectangle(cornerRadius: 7)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calendar Tab

struct CalendarTabView: View {
    @State private var bsDate = BikramSambat.currentNepaliDate()
    @State private var timeComponents = BikramSambat.currentNepalTimeComponents()
    @State private var nepalDate = Date()
    @State private var showSettings = false
    @State private var showNepaliSection = false
    @State private var showEnglishSection = false
    @State private var todayInfo: DayData?
    @State private var dayOffset: Int = 0

    @State private var settings = AppSettings.shared
    private let calendarData = CalendarDataService.shared
    private let metalService = MetalPriceService.shared
    private let fuelWeather = FuelWeatherService.shared
    private let currencyService = CurrencyService.shared
    @Environment(\.requestReview) private var requestReview
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

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

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(BikramSambat.formatNepalTime12hDigitsOnly(timeComponents))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(BikramSambat.englishPeriod(timeComponents))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                }

                // Today's festival/holiday (inline with time)
                if let info = viewedDayInfo, !info.f.isEmpty {
                    todayInfoSection(info)
                } else {
                    HeartbeatView()
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        nepaliCrimson.opacity(0.08),
                        nepaliCrimson.opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Nepal Time")
            .accessibilityValue(BikramSambat.formatNepalTime12hEnglish(timeComponents))
            .overlay(alignment: .topTrailing) {
                Button {
                    Aptabase.shared.trackEvent("app_quit")
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
                .accessibilityLabel("Quit Nepali Calendar")
                .padding(8)
            }

            Divider()

            // MARK: Date Section with Day Stepper
            VStack(spacing: 8) {
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { dayOffset -= 1 }
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
            .padding(.vertical, 16)
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

            Divider()

            // MARK: Market Info
            metalPriceSection
            fuelSection
            currencySection


            Divider()

            // MARK: Date Converter (collapsible)
            DateConverterView()

            // MARK: Settings toggle arrow
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSettings.toggle()
                }
                if !showSettings {
                    Aptabase.shared.trackEvent("settings_opened")
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Settings")
                        .font(.body.weight(.medium))
                    Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showSettings ? "Hide Settings" : "Show Settings")
            // MARK: Settings (collapsible)
            if showSettings {
                settingsSection
            }

            Divider()

            // MARK: Footer
            HStack {
                Text("यदि हजुरलाई यो App मन पर्यो भने, कृपया Rate गरिदिनुहोस्")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Rate") {
                    Aptabase.shared.trackEvent("rate_us_tapped")
                    requestReview()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .onAppear {
            Aptabase.shared.trackEvent("popover_opened")
            loadCalendarData()
            metalService.refreshIfNeeded()
            fuelWeather.refreshWeatherIfNeeded()
            fuelWeather.refreshFuelIfNeeded()
            CurrencyService.shared.refreshIfNeeded()
        }
        .onDisappear {
            showSettings = false
            dayOffset = 0
        }
        .onReceive(timer) { _ in
            bsDate = BikramSambat.currentNepaliDate()
            timeComponents = BikramSambat.currentNepalTimeComponents()
            nepalDate = Date()
            loadCalendarData()
        }
    }

    // MARK: Settings Section

    private var settingsSection: some View {
        VStack(spacing: 6) {
            displayStylePicker
            Divider()
            launchAtLoginToggle
            Divider()
            actionLinkRow(
                icon: "star",
                label: "Rate Nepali Calendar"
            ) {
                Aptabase.shared.trackEvent("rate_app_tapped")
                requestReview()
            }
            actionLinkRow(
                icon: "arrow.down.circle",
                label: "Download RapidPhoto"
            ) {
                Aptabase.shared.trackEvent("download_rapidphoto_tapped")
                if let url = URL(string: "https://apps.apple.com/us/app/rapidphoto-batch-crop-edit/id6758485661?mt=12") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var displayStylePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Menu Bar Display")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 8)

            // नेपाली section
            pickerSectionHeader(title: "नेपाली", isExpanded: $showNepaliSection)
            if showNepaliSection {
                VStack(spacing: 2) {
                    ForEach(Array(MenuBarDisplayStyle.allCases.filter { $0.section == "नेपाली" }), id: \.self) { style in
                        styleOptionRow(style: style)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // English section
            pickerSectionHeader(title: "English", isExpanded: $showEnglishSection)
            if showEnglishSection {
                VStack(spacing: 2) {
                    ForEach(Array(MenuBarDisplayStyle.allCases.filter { $0.section == "English" }), id: \.self) { style in
                        styleOptionRow(style: style)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func pickerSectionHeader(title: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private func styleOptionRow(style: MenuBarDisplayStyle) -> some View {
        Button {
            settings.menuBarStyle = style
            Aptabase.shared.trackEvent("menu_bar_style_changed", with: ["style": style.rawValue])
        } label: {
            HStack {
                Text(style.label)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                if settings.menuBarStyle == style {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(nepaliCrimson)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                settings.menuBarStyle == style
                    ? nepaliCrimson.opacity(0.1)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 4)
            )
        }
        .buttonStyle(.plain)
    }

    private var launchAtLoginToggle: some View {
        Toggle(isOn: Binding(
            get: { settings.launchAtLogin },
            set: {
                settings.launchAtLogin = $0
                Aptabase.shared.trackEvent("launch_at_login_toggled", with: ["enabled": $0 ? "true" : "false"])
            }
        )) {
            HStack(spacing: 6) {
                Image(systemName: "power")
                    .font(.subheadline)
                Text("Launch at Login")
                    .font(.callout)
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }

    private func actionLinkRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 14)
                Text(label)
                    .font(.callout)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: Metal Price Section

    private var metalPriceSection: some View {
        let stale = metalService.isStale
        let dimmed = Color.secondary.opacity(0.3)

        return VStack(spacing: 0) {
            Group {
                if let prices = metalService.prices {
                    HStack(spacing: 6) {
                        Text("Gold")
                            .foregroundStyle(stale ? dimmed : Color.secondary)
                        Text(MetalPriceService.formatNPR(prices.goldPerTola))
                            .foregroundStyle(stale ? dimmed : Color.primary)
                        Text("/तोला")
                            .font(.caption2)
                            .foregroundStyle(stale ? dimmed : Color.secondary)

                        Text("·")
                            .foregroundStyle(.quaternary)

                        Text("Silver")
                            .foregroundStyle(stale ? dimmed : Color.secondary)
                        Text(MetalPriceService.formatNPR(prices.silverPerTola))
                            .foregroundStyle(stale ? dimmed : Color.primary)
                        Text("/तोला")
                            .font(.caption2)
                            .foregroundStyle(stale ? dimmed : Color.secondary)

                        if stale {
                            Text("(stale)")
                                .foregroundStyle(dimmed)
                        }
                    }
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                } else if metalService.isLoading {
                    Text("· · ·")
                        .font(.callout)
                        .foregroundStyle(.quaternary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    // MARK: Fuel Section

    private var fuelSection: some View {
        Group {
            if let f = fuelWeather.fuel {
                HStack(spacing: 6) {
                    Text("Petrol")
                        .foregroundStyle(Color.secondary)
                    Text("रू \(Int(f.petrolPerLitre))")
                        .foregroundStyle(Color.primary)
                    Text("/लि")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)

                    Text("·")
                        .foregroundStyle(.quaternary)

                    Text("Diesel")
                        .foregroundStyle(Color.secondary)
                    Text("रू \(Int(f.dieselPerLitre))")
                        .foregroundStyle(Color.primary)
                    Text("/लि")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
                .font(.callout.weight(.semibold))
                .monospacedDigit()
            } else if fuelWeather.isLoadingFuel {
                Text("· · ·")
                    .font(.callout)
                    .foregroundStyle(.quaternary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }


    // MARK: Currency Section (USD/EUR on main tab)

    private var currencySection: some View {
        let stale = currencyService.isStale
        let dimmed = Color.secondary.opacity(0.3)

        return Group {
            if let usd = currencyService.rate(for: "USD"),
               let eur = currencyService.rate(for: "EUR") {
                HStack(spacing: 6) {
                    Text("USD")
                        .foregroundStyle(stale ? dimmed : Color.secondary)
                    Text(CurrencyService.formatRate(usd))
                        .foregroundStyle(stale ? dimmed : Color.primary)

                    Text("·")
                        .foregroundStyle(.quaternary)

                    Text("EUR")
                        .foregroundStyle(stale ? dimmed : Color.secondary)
                    Text(CurrencyService.formatRate(eur))
                        .foregroundStyle(stale ? dimmed : Color.primary)

                    if stale {
                        Text("(stale)")
                            .foregroundStyle(dimmed)
                    }
                }
                .font(.callout.weight(.semibold))
                .monospacedDigit()
            } else if currencyService.isLoading {
                Text("· · ·")
                    .font(.callout)
                    .foregroundStyle(.quaternary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
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

    // MARK: Helpers

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
    }
}

#Preview {
    MenuBarPopoverView()
        .frame(width: 340)
}
