//
//  ContentView.swift
//  Nepali-Calendar-App
//
//  Popover UI shown when clicking the menu bar item.
//  Displays Nepal time, today's date in BS and AD, and settings.
//

import SwiftUI
import Combine

// Nepali flag crimson (#DC143C)
private let nepaliCrimson = Color(red: 0.863, green: 0.078, blue: 0.235)

// MARK: - Menu Bar Popover

struct MenuBarPopoverView: View {
    @State private var bsDate = BikramSambat.currentNepaliDate()
    @State private var timeComponents = BikramSambat.currentNepalTimeComponents()
    @State private var nepalDate = Date()
    @State private var showSettings = false

    @State private var settings = AppSettings.shared
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
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
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

            Divider()

            // MARK: BS Date (Primary)
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Bikram Sambat")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
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
            .padding(.vertical, 16)

            Divider()

            // MARK: AD Date (Secondary)
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Gregorian")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }

                Text(formattedADDate)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)

                Text(BikramSambat.dayOfWeekEnglish(bsDate))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)

            Divider()

            // MARK: Settings toggle arrow
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSettings.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 11, weight: .medium))
                    Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
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
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 280)
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
        VStack(spacing: 8) {
            displayStylePicker
            Divider()
            launchAtLoginToggle
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var displayStylePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Menu Bar Display")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 2) {
                // Nepali section
                Text("नेपाली")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)

                ForEach(Array(MenuBarDisplayStyle.allCases.filter { $0.section == "नेपाली" }), id: \.self) { style in
                    styleOptionRow(style: style)
                }

                Divider()
                    .padding(.vertical, 2)

                // English section
                Text("English")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)

                ForEach(Array(MenuBarDisplayStyle.allCases.filter { $0.section == "English" }), id: \.self) { style in
                    styleOptionRow(style: style)
                }
            }
        }
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
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
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
        .controlSize(.mini)
    }

    // MARK: Helpers

    /// Formatted Gregorian date for Nepal's current date.
    private var formattedADDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        formatter.timeZone = nepalTimeZone
        return formatter.string(from: nepalDate)
    }
}

#Preview {
    MenuBarPopoverView()
}
