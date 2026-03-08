//
//  ContentView.swift
//  Nepali-Calendar-App
//
//  Popover UI shown when clicking the menu bar item.
//  Displays Nepal time, today's date in BS and AD, and settings.
//

import SwiftUI
import Combine
import StoreKit

// Nepali flag crimson (#DC143C)
private let nepaliCrimson = Color(red: 0.863, green: 0.078, blue: 0.235)

// MARK: - Menu Bar Popover

struct MenuBarPopoverView: View {
    @State private var bsDate = BikramSambat.currentNepaliDate()
    @State private var timeComponents = BikramSambat.currentNepalTimeComponents()
    @State private var nepalDate = Date()
    @State private var showSettings = false
    @State private var showNepaliSection = false
    @State private var showEnglishSection = false

    @State private var settings = AppSettings.shared
    @Environment(\.requestReview) private var requestReview
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header — Nepal Time
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Nepal Time")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(BikramSambat.formatNepalTime(timeComponents))
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    Text(BikramSambat.englishPeriod(timeComponents))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.7))
                }

                Text(BikramSambat.formatNepalTime12hEnglish(timeComponents))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
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

            Divider()

            // MARK: BS Date (Primary)
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Bikram Sambat")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text(BikramSambat.formatNepali(bsDate))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(BikramSambat.dayOfWeekNepali(bsDate))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(BikramSambat.formatEnglish(bsDate) + " BS")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

            Divider()

            // MARK: AD Date (Secondary)
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Gregorian")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text(formattedADDate)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)

                Text(BikramSambat.dayOfWeekEnglish(bsDate))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

            Divider()

            // MARK: Settings toggle arrow
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSettings.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            // MARK: Settings (collapsible)
            if showSettings {
                settingsSection
            }

            // MARK: Footer
            HStack {
                Text("NPT (UTC+5:45)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.quaternary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
                .buttonStyle(.bordered)
                .controlSize(.small)
                .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 320)
        .onDisappear {
            showSettings = false
        }
        .onReceive(timer) { _ in
            bsDate = BikramSambat.currentNepaliDate()
            timeComponents = BikramSambat.currentNepalTimeComponents()
            nepalDate = Date()
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
                requestReview()
            }
            actionLinkRow(
                icon: "arrow.down.circle",
                label: "Download RapidPhoto"
            ) {
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
                .font(.system(size: 11, weight: .semibold))
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
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
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
        } label: {
            HStack {
                Text(style.label)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                if settings.menuBarStyle == style {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
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
            set: { settings.launchAtLogin = $0 }
        )) {
            HStack(spacing: 6) {
                Image(systemName: "power")
                    .font(.system(size: 11))
                Text("Launch at Login")
                    .font(.system(size: 12))
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }

    private func actionLinkRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    /// Reusable formatter — DateFormatter is expensive to allocate.
    private static let adDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        f.timeZone = nepalTimeZone
        return f
    }()

    /// Formatted Gregorian date for Nepal's current date.
    private var formattedADDate: String {
        Self.adDateFormatter.string(from: nepalDate)
    }
}

#Preview {
    MenuBarPopoverView()
}
