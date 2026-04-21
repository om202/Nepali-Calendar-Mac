//
//  DateConverterView.swift
//  Nepali-Calendar-App
//
//  Interactive BS ↔ AD date converter. Shown inside the Converter
//  tab when the "मिति" category is selected. Spacing, labels, and
//  controls follow macOS conventions.
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
    @State private var mode: ConversionMode = .bsToAD

    @State private var bsYear: Int
    @State private var bsMonth: Int
    @State private var bsDay: Int

    @State private var adYear: Int
    @State private var adMonth: Int
    @State private var adDay: Int

    init() {
        let today = BikramSambat.currentNepaliDate()
        _bsYear = State(initialValue: today.year)
        _bsMonth = State(initialValue: today.month)
        _bsDay = State(initialValue: today.day)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = nepalTimeZone
        let now = Date()
        _adYear = State(initialValue: cal.component(.year, from: now))
        _adMonth = State(initialValue: cal.component(.month, from: now))
        _adDay = State(initialValue: cal.component(.day, from: now))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                modePicker

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel(mode == .bsToAD ? "BIKRAM SAMBAT" : "GREGORIAN")
                    if mode == .bsToAD {
                        bsInputFields
                    } else {
                        adInputFields
                    }
                }

                resultSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            ForEach(ConversionMode.allCases, id: \.self) { m in
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: mode) {
            Aptabase.shared.trackEvent("date_converter_mode_changed", with: ["mode": mode.rawValue])
        }
    }

    // MARK: - BS Input Fields

    private var bsInputFields: some View {
        HStack(spacing: 6) {
            Picker("Year", selection: $bsYear) {
                ForEach(2000...2090, id: \.self) { y in
                    Text(String(y)).tag(y)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Picker("Month", selection: $bsMonth) {
                ForEach(1...12, id: \.self) { m in
                    Text(bsMonthNamesEnglish[m - 1]).tag(m)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .onChange(of: bsMonth) { clampBSDay() }
            .onChange(of: bsYear) { clampBSDay() }

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

    // MARK: - AD Input Fields

    private var adInputFields: some View {
        HStack(spacing: 6) {
            Picker("Year", selection: $adYear) {
                ForEach(1944...2033, id: \.self) { y in
                    Text(String(y)).tag(y)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Picker("Month", selection: $adMonth) {
                ForEach(1...12, id: \.self) { m in
                    Text(adMonthName(m)).tag(m)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .onChange(of: adMonth) { clampADDay() }
            .onChange(of: adYear) { clampADDay() }

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

    // MARK: - Result

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(mode == .bsToAD ? "GREGORIAN" : "BIKRAM SAMBAT")

            VStack(alignment: .leading, spacing: 4) {
                if mode == .bsToAD {
                    let adDate = BikramSambat.bsToAD(year: bsYear, month: bsMonth, day: bsDay)
                    Text(Self.resultFormatter.string(from: adDate))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(BikramSambat.formatNepali(BSDate(year: bsYear, month: bsMonth, day: bsDay)) + " BS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    let bs = BikramSambat.adToBS(year: adYear, month: adMonth, day: adDay)
                    Text(BikramSambat.formatNepali(bs))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(BikramSambat.formatEnglish(bs) + " BS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                nepaliCrimson.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
        }
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private static let resultFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private var bsMaxDay: Int {
        BikramSambat.daysInMonth(year: bsYear, month: bsMonth)
    }

    private var adMaxDay: Int {
        let leap = BikramSambat.isLeapYear(adYear)
        let days = [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        return days[adMonth - 1]
    }

    private func clampBSDay() {
        let max = bsMaxDay
        if bsDay > max { bsDay = max }
    }

    private func clampADDay() {
        let max = adMaxDay
        if adDay > max { adDay = max }
    }

    private func adMonthName(_ month: Int) -> String {
        let names = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        return names[month - 1]
    }
}
