//
//  ConverterView.swift
//  Nepali-Calendar-App
//
//  Unified Converter panel. The tab exposes five categories —
//  Date (BS↔AD), Currency, Land, Gold, Grains — swapped via a
//  pill-style segmented picker. Each category renders its own content.
//  Layout, spacing, and typography follow macOS conventions.
//

import SwiftUI
import Aptabase

// MARK: - Conversion Category

enum ConversionCategory: String, CaseIterable, Identifiable {
    case date     = "मिति"
    case currency = "मुद्रा"
    case land     = "भूमि"
    case gold     = "सुन"
    case grains   = "अनाज"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .date:     return "calendar"
        case .currency: return "coloncurrencysign.circle"
        case .land:     return "map"
        case .gold:     return "circle.circle"
        case .grains:   return "leaf"
        }
    }
}

// MARK: - Unit Definitions

struct NepaliUnit: Identifiable, Hashable {
    let code: String      // Internal key
    let label: String     // Display label (Nepali or English)
    let toBase: Double    // Multiply input by this to get the base unit
    var id: String { code }
}

/// All units per category. First unit in each array is the base unit (toBase = 1).
struct UnitRegistry {

    // MARK: Land — base unit: square feet (sq.ft)
    static let land: [NepaliUnit] = [
        NepaliUnit(code: "ropani",  label: "रोपनी",      toBase: 5476),
        NepaliUnit(code: "aana",    label: "आना",        toBase: 342.25),
        NepaliUnit(code: "paisa",   label: "पैसा",       toBase: 85.5625),
        NepaliUnit(code: "dam",     label: "दाम",        toBase: 21.390625),
        NepaliUnit(code: "bigha",   label: "बिघा",       toBase: 72900),
        NepaliUnit(code: "kattha",  label: "कट्ठा",      toBase: 3645),
        NepaliUnit(code: "dhur",    label: "धुर",        toBase: 182.25),
        NepaliUnit(code: "sqft",    label: "Sq. Feet",   toBase: 1),
        NepaliUnit(code: "sqm",     label: "Sq. Meter",  toBase: 10.7639),
        NepaliUnit(code: "hectare", label: "Hectare",    toBase: 107639),
        NepaliUnit(code: "acre",    label: "Acre",       toBase: 43560),
    ]

    // MARK: Gold — base unit: grams
    static let gold: [NepaliUnit] = [
        NepaliUnit(code: "tola",  label: "तोला",       toBase: 11.6638),
        NepaliUnit(code: "lal",   label: "लाल",        toBase: 0.116638),
        NepaliUnit(code: "gram",  label: "Gram",       toBase: 1),
        NepaliUnit(code: "kg",    label: "Kilogram",   toBase: 1000),
        NepaliUnit(code: "oz",    label: "Troy Ounce", toBase: 31.1035),
    ]

    // MARK: Grains/Volume — base unit: liters
    static let grains: [NepaliUnit] = [
        NepaliUnit(code: "muri",   label: "मुरी",       toBase: 90.9192),
        NepaliUnit(code: "pathi",  label: "पाथी",       toBase: 4.54596),
        NepaliUnit(code: "mana",   label: "माना",        toBase: 0.568245),
        NepaliUnit(code: "liter",  label: "Liter",      toBase: 1),
        NepaliUnit(code: "gallon", label: "Gallon (US)", toBase: 3.78541),
        NepaliUnit(code: "kg",     label: "Kg (rice≈)",  toBase: 0.8),
    ]

    static func units(for category: ConversionCategory) -> [NepaliUnit] {
        switch category {
        case .land:     return land
        case .gold:     return gold
        case .grains:   return grains
        case .date:     return []
        case .currency: return []
        }
    }
}

// MARK: - Converter View

struct ConverterView: View {
    @State private var selectedCategory: ConversionCategory = .date
    @State private var inputValue: String = "1"
    @State private var selectedUnit: NepaliUnit = UnitRegistry.land[0]

    var body: some View {
        VStack(spacing: 0) {
            tabHeader

            Divider()

            categoryRow

            Divider()

            switch selectedCategory {
            case .date:
                DateConverterView()
            case .currency:
                CurrencyView(embedded: true)
            default:
                unitConversionContent
            }
        }
        .onAppear {
            Aptabase.shared.trackEvent("converter_tab_opened")
        }
        .onChange(of: selectedCategory) {
            if let first = currentUnits.first {
                selectedUnit = first
            }
            Aptabase.shared.trackEvent("converter_category_changed", with: ["category": selectedCategory.rawValue])
        }
    }

    // MARK: - Tab Header

    private var tabHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Converter")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    // MARK: - Category Row

    private var categoryRow: some View {
        HStack(spacing: 4) {
            ForEach(ConversionCategory.allCases) { cat in
                categoryChip(cat)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func categoryChip(_ cat: ConversionCategory) -> some View {
        let isSelected = selectedCategory == cat
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = cat
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: cat.icon)
                    .font(.title3)
                Text(cat.rawValue)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? nepaliCrimson : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                isSelected ? nepaliCrimson.opacity(0.12) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(cat.rawValue) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Unit Conversion Content

    private var unitConversionContent: some View {
        VStack(spacing: 0) {
            // Input block
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("ENTER VALUE")

                HStack(spacing: 8) {
                    TextField("0", text: $inputValue)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            .quaternary.opacity(0.5),
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )

                    Picker(selection: $selectedUnit) {
                        ForEach(currentUnits) { unit in
                            Text(unit.label).tag(unit)
                        }
                    } label: {
                        Text("Unit")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.regular)
                    .tint(nepaliCrimson)
                    .fixedSize()
                    .accessibilityLabel("Select unit. Currently \(selectedUnit.label).")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider()

            // Results
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel("CONVERSIONS")
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 0) {
                        ForEach(convertedResults) { result in
                            resultRow(result)
                            if result.id != convertedResults.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(.secondary)
    }

    // MARK: - Result Row

    private func resultRow(_ result: ConversionResult) -> some View {
        HStack {
            Text(result.unitLabel)
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(result.formattedValue)
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Conversion Logic

    private var currentUnits: [NepaliUnit] {
        UnitRegistry.units(for: selectedCategory)
    }

    private var inputDouble: Double {
        Double(inputValue) ?? 0
    }

    private var convertedResults: [ConversionResult] {
        let input = inputDouble
        guard input > 0 else {
            return currentUnits
                .filter { $0.code != selectedUnit.code }
                .map { ConversionResult(unitCode: $0.code, unitLabel: $0.label, value: 0) }
        }

        let baseValue = input * selectedUnit.toBase

        return currentUnits
            .filter { $0.code != selectedUnit.code }
            .compactMap { target in
                let converted = baseValue / target.toBase
                guard converted >= 0.0001 && converted <= 99_999_999 else { return nil }
                return ConversionResult(unitCode: target.code, unitLabel: target.label, value: converted)
            }
    }
}

// MARK: - Conversion Result Model

struct ConversionResult: Identifiable {
    let unitCode: String
    let unitLabel: String
    let value: Double
    var id: String { unitCode }

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.usesGroupingSeparator = true
        f.minimumFractionDigits = 2
        return f
    }()

    var formattedValue: String {
        if value == 0 { return "—" }
        let f = Self.formatter
        f.maximumFractionDigits = value >= 100 ? 2 : (value >= 1 ? 4 : 6)
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

#Preview {
    ConverterView()
        .frame(width: 380, height: 485)
}
