//
//  NepaliTyperHelpView.swift
//  Nepali-Calendar-App
//
//  Help/cheat-sheet shown as a sheet from NepaliTyperView. Content
//  mirrors the nepmedium NepaliHelpModal so both products share one
//  typing reference.
//

import SwiftUI

struct NepaliTyperHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                halantRule
                coreRule
                halfLetters
                vowelsTable
                retroflexTable
                extrasTable
                digitsTable
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 400, idealWidth: 440, minHeight: 420, idealHeight: 520)
    }

    // MARK: - Halant (first, most important)

    private var halantRule: some View {
        section("Halant (्) — the key shortcut") {
            Text("Type an apostrophe ' to add a halant (्), which joins two consonants into a half-letter or cluster.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text("Shortcut")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("'")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)))
                Text("→")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text("्")
                    .font(.system(size: 16, weight: .semibold))
            }

            examples([
                ("K A S ' T O", "कस्तो"),
                ("N ' M", "न्म"),
                ("C H H A N '", "छन्")
            ])
        }
    }

    // MARK: - Sections

    private var coreRule: some View {
        section("Core rule: full consonants by default") {
            Text("Every letter you type is a full character. You don't need to add “a” to finish a syllable.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            examples([
                ("T", "त"),
                ("T + A", "ता"),
                ("K + S", "कस")
            ])
        }
    }

    private var halfLetters: some View {
        section("Half-letters & clusters") {
            Text("Use the apostrophe ' to add a halant (्) and form half-letters or consonant clusters.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            examples([
                ("K A S ' T O", "कस्तो"),
                ("N ' M", "न्म"),
                ("C H H A N '", "छन्"),
                ("A A J A", "आज"),
                ("M A ~~", "मँ"),
                ("G Y A A N", "ज्ञान")
            ])
        }
    }

    private var vowelsTable: some View {
        section("Vowels") {
            mappingGrid([
                ("a / aa / A", "ा"), ("i", "ि"),
                ("ee / I", "ी"),     ("u", "ु"),
                ("oo / U", "ू"),     ("e", "े"),
                ("ai", "ै"),         ("o", "ो"),
                ("au", "ौ"),         ("R (Ri)", "ृ")
            ])
        }
    }

    private var retroflexTable: some View {
        section("Capitals / variants") {
            mappingGrid([
                ("t", "त"),   ("T", "ट"),
                ("d", "द"),   ("D", "ड"),
                ("n", "न"),   ("N", "ण"),
                ("sh", "श"),  ("S / Sh", "ष"),
                ("ng", "ङ"),  ("ny", "ञ")
            ])
        }
    }

    private var extrasTable: some View {
        section("Extras") {
            mappingGrid([
                ("'", "् (halant)"),           ("~", "ं (anusvara)"),
                ("~~", "ँ (chandrabindu)"),    (":", "ः (visarga)"),
                ("/ or .", "। (purnabiram)"),  ("ksh / x", "क्ष"),
                ("gy / gya", "ज्ञ"),            ("tr", "त्र"),
                ("shr", "श्र")
            ])
        }
    }

    private var digitsTable: some View {
        section("Numbers") {
            mappingGrid([
                ("0", "०"), ("1", "१"),
                ("2", "२"), ("3", "३"),
                ("4", "४"), ("5", "५"),
                ("6", "६"), ("7", "७"),
                ("8", "८"), ("9", "९")
            ])
        }
    }

    // MARK: - Builders

    @ViewBuilder
    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            content()
        }
    }

    private func examples(_ pairs: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(pairs, id: \.0) { roman, nepali in
                HStack(spacing: 8) {
                    Text(roman)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 130, alignment: .leading)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                    Text(nepali)
                        .font(.system(size: 14))
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private func mappingGrid(_ pairs: [(String, String)]) -> some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            ForEach(pairs.indices, id: \.self) { i in
                let (roman, nepali) = pairs[i]
                mappingRow(roman, nepali)
            }
        }
    }

    private func mappingRow(_ roman: String, _ nepali: String) -> some View {
        HStack(spacing: 8) {
            Text(roman)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(nepali)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NepaliTyperHelpView()
        .frame(width: 440, height: 520)
}
