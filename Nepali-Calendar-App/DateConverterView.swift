//
//  DateConverterView.swift
//  Nepali-Calendar-App
//
//  Interactive BS ↔ AD date converter with dropdown pickers.
//

import SwiftUI
import Aptabase

// MARK: - Conversion Mode

private enum ConversionMode: String, CaseIterable {
    case bsToAD = "BS → AD"
    case adToBS = "AD → BS"
}

// MARK: - Date Converter View

struct DateConverterView: View {
    @State private var showConverter = false

    // Conversion mode
    @State private var mode: ConversionMode = .bsToAD

    // BS input (defaults to today)
    @State private var bsYear: Int
    @State private var bsMonth: Int
    @State private var bsDay: Int

    // AD input (defaults to today)
    @State private var adYear: Int
    @State private var adMonth: Int
    @State private var adDay: Int

    init() {
        let today = BikramSambat.currentNepaliDate()
        _bsYear = State(initialValue: today.year)
        _bsMonth = State(initialValue: today.month)
        _bsDay = State(initialValue: today.day)

        // AD defaults from Nepal timezone
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = nepalTimeZone
        let now = Date()
        _adYear = State(initialValue: cal.component(.year, from: now))
        _adMonth = State(initialValue: cal.component(.month, from: now))
        _adDay = State(initialValue: cal.component(.day, from: now))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toggle button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showConverter.toggle()
                }
                if showConverter {
                    Aptabase.shared.trackEvent("date_converter_opened")
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Date Converter")
                        .font(.body.weight(.medium))
                    Image(systemName: showConverter ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showConverter ? "Hide Date Converter" : "Show Date Converter")

            // Converter content
            if showConverter {
                converterContent
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onDisappear {
            showConverter = false
        }
    }

    // MARK: - Converter Content

    private var converterContent: some View {
        VStack(spacing: 12) {
            // Mode toggle
            Picker("Mode", selection: $mode) {
                ForEach(ConversionMode.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: mode) {
                Aptabase.shared.trackEvent("date_conversion_performed", with: ["mode": mode.rawValue])
            }

            // Input pickers
            if mode == .bsToAD {
                bsInputSection
            } else {
                adInputSection
            }

            Divider()

            // Result
            resultSection
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - BS Input

    private var bsInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BIKRAM SAMBAT DATE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            HStack(spacing: 6) {
                // Year
                Picker("Year", selection: $bsYear) {
                    ForEach(2000...2090, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)

                // Month
                Picker("Month", selection: $bsMonth) {
                    ForEach(1...12, id: \.self) { m in
                        Text(bsMonthNamesEnglish[m - 1]).tag(m)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .onChange(of: bsMonth) { clampBSDay() }
                .onChange(of: bsYear) { clampBSDay() }

                // Day
                Picker("Day", selection: $bsDay) {
                    ForEach(1...bsMaxDay, id: \.self) { d in
                        Text(String(d)).tag(d)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: - AD Input

    private var adInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GREGORIAN DATE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            HStack(spacing: 6) {
                // Year
                Picker("Year", selection: $adYear) {
                    ForEach(1944...2033, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)

                // Month
                Picker("Month", selection: $adMonth) {
                    ForEach(1...12, id: \.self) { m in
                        Text(adMonthName(m)).tag(m)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .onChange(of: adMonth) { clampADDay() }
                .onChange(of: adYear) { clampADDay() }

                // Day
                Picker("Day", selection: $adDay) {
                    ForEach(1...adMaxDay, id: \.self) { d in
                        Text(String(d)).tag(d)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(spacing: 6) {
            if mode == .bsToAD {
                let adDate = BikramSambat.bsToAD(year: bsYear, month: bsMonth, day: bsDay)
                let formatted = Self.resultFormatter.string(from: adDate)

                Text("GREGORIAN (AD)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Text(formatted)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                // Show Nepali script of the input
                Text(BikramSambat.formatNepali(BSDate(year: bsYear, month: bsMonth, day: bsDay)) + " BS")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            } else {
                let bs = BikramSambat.adToBS(year: adYear, month: adMonth, day: adDay)

                Text("BIKRAM SAMBAT (BS)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Text(BikramSambat.formatNepali(bs))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(BikramSambat.formatEnglish(bs) + " BS")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(nepaliCrimson.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private static let resultFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    /// Maximum days for the selected BS month/year.
    private var bsMaxDay: Int {
        BikramSambat.daysInMonth(year: bsYear, month: bsMonth)
    }

    /// Maximum days for the selected AD month/year.
    private var adMaxDay: Int {
        let leap = BikramSambat.isLeapYear(adYear)
        let days = [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        return days[adMonth - 1]
    }

    /// Clamp BS day if it exceeds the month's max.
    private func clampBSDay() {
        let max = bsMaxDay
        if bsDay > max { bsDay = max }
    }

    /// Clamp AD day if it exceeds the month's max.
    private func clampADDay() {
        let max = adMaxDay
        if adDay > max { adDay = max }
    }

    /// English month names for Gregorian calendar.
    private func adMonthName(_ month: Int) -> String {
        let names = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        return names[month - 1]
    }
}
