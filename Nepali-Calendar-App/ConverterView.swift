//
//  ConverterView.swift
//  Nepali-Calendar-App
//
//  Nepali Unit Converter — converts between traditional Nepali
//  measurement units and modern metric/imperial equivalents.
//  Categories: Land (भूमि), Gold (सुन), Grains (अनाज).
//  UI mirrors NewsView for consistency across tabs.
//

import SwiftUI
import Aptabase

// MARK: - Conversion Category

enum ConversionCategory: String, CaseIterable, Identifiable {
    case land   = "भूमि"
    case gold   = "सुन"
    case grains = "अनाज"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .land:   return "map"
        case .gold:   return "circle.circle"
        case .grains: return "leaf"
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
        NepaliUnit(code: "lal",   label: "लाल",        toBase: 0.116638),     // 1 Tola = 100 Lal
        NepaliUnit(code: "gram",  label: "Gram",       toBase: 1),
        NepaliUnit(code: "kg",    label: "Kilogram",   toBase: 1000),
        NepaliUnit(code: "oz",    label: "Troy Ounce", toBase: 31.1035),
    ]

    // MARK: Grains/Volume — base unit: liters
    // Muri, Pathi, Mana are volume measures traditionally used for grains
    static let grains: [NepaliUnit] = [
        NepaliUnit(code: "muri",   label: "मुरी",       toBase: 90.9192),      // 1 Muri = 20 Pathi
        NepaliUnit(code: "pathi",  label: "पाथी",       toBase: 4.54596),      // ≈ 4.546 liters
        NepaliUnit(code: "mana",   label: "माना",        toBase: 0.568245),     // 1 Pathi = 8 Mana
        NepaliUnit(code: "liter",  label: "Liter",      toBase: 1),
        NepaliUnit(code: "gallon", label: "Gallon (US)", toBase: 3.78541),
        NepaliUnit(code: "kg",     label: "Kg (rice≈)",  toBase: 0.8),          // Approximate: varies by grain
    ]

    static func units(for category: ConversionCategory) -> [NepaliUnit] {
        switch category {
        case .land:   return land
        case .gold:   return gold
        case .grains: return grains
        }
    }
}

// MARK: - Converter View

// Matches the crimson used throughout the app
private let converterCrimson = Color(red: 0.863, green: 0.078, blue: 0.235)

struct ConverterView: View {
    @State private var selectedCategory: ConversionCategory = .land
    @State private var inputValue: String = "1"
    @State private var selectedUnit: NepaliUnit = UnitRegistry.land[0]

    var body: some View {
        VStack(spacing: 0) {
            // Header — matches NewsView pattern
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Unit Converter")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()

            // Category picker
            HStack(spacing: 4) {
                ForEach(ConversionCategory.allCases) { cat in
                    categoryButton(cat)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Input section
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField("Value", text: $inputValue)
                        .textFieldStyle(.plain)
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                        .frame(maxWidth: .infinity)

                    // Unit picker
                    Menu {
                        ForEach(currentUnits) { unit in
                            Button(unit.label) {
                                selectedUnit = unit
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedUnit.label)
                                .font(.callout.weight(.semibold))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(converterCrimson)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(converterCrimson.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Results list
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
            .frame(height: 300)
        }
        .onAppear {
            Aptabase.shared.trackEvent("converter_tab_opened")
        }
        .onChange(of: selectedCategory) {
            // Reset to first unit of new category
            selectedUnit = currentUnits[0]
            Aptabase.shared.trackEvent("converter_category_changed", with: ["category": selectedCategory.rawValue])
        }
    }

    // MARK: - Category Button

    private func categoryButton(_ cat: ConversionCategory) -> some View {
        let isSelected = selectedCategory == cat
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = cat
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: cat.icon)
                    .font(.caption)
                Text(cat.rawValue)
                    .font(.callout.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? converterCrimson : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                isSelected ? converterCrimson.opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 7)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Result Row

    private func resultRow(_ result: ConversionResult) -> some View {
        HStack {
            Text(result.unitLabel)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text(result.formattedValue)
                .font(.callout.weight(.semibold).monospacedDigit())
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

        // Convert input → base unit → each target unit
        let baseValue = input * selectedUnit.toBase

        return currentUnits
            .filter { $0.code != selectedUnit.code }
            .compactMap { target in
                let converted = baseValue / target.toBase
                // Hide impractical values (too large or too tiny to be useful)
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

    var formattedValue: String {
        if value == 0 { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        if value >= 100 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        } else if value >= 1 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 4
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 6
        }
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

#Preview {
    ConverterView()
        .frame(width: 340)
}
