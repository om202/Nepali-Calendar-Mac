//
//  SettingsTabView.swift
//  Nepali-Calendar-App
//
//  Consolidated settings tab: menu-bar display style, launch at login,
//  rate prompt (hides once tapped), about link, and cross-promo.
//

import SwiftUI
import StoreKit
import Aptabase

struct SettingsTabView: View {
    let showAbout: () -> Void

    @State private var settings = AppSettings.shared
    @State private var showNepaliSection = true
    @State private var showEnglishSection = false
    @AppStorage("hasRatedApp") private var hasRatedApp: Bool = false

    @Environment(\.requestReview) private var requestReview

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(spacing: 14) {
                    displayStylePicker
                    Divider()
                    launchAtLoginToggle
                    Divider()
                    if !hasRatedApp {
                        actionLinkRow(icon: "star", label: "Rate Nepali Calendar (Pro)") {
                            hasRatedApp = true
                            Aptabase.shared.trackEvent("rate_tapped", with: ["source": "settings"])
                            requestReview()
                        }
                        Divider()
                    }
                    actionLinkRow(icon: "info.circle", label: "About") {
                        Aptabase.shared.trackEvent("info_opened")
                        showAbout()
                    }
                    Divider()
                    actionLinkRow(icon: "arrow.down.circle", label: "Download RapidPhoto") {
                        Aptabase.shared.trackEvent("download_rapidphoto_tapped")
                        if let url = URL(string: "https://apps.apple.com/us/app/rapidphoto-batch-crop-edit/id6758485661?mt=12") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    private var displayStylePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Menu Bar Display")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            pickerSectionHeader(title: "नेपाली", isExpanded: $showNepaliSection)
            if showNepaliSection {
                VStack(spacing: 2) {
                    ForEach(Array(MenuBarDisplayStyle.allCases.filter { $0.section == "नेपाली" }), id: \.self) { style in
                        styleOptionRow(style: style)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

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
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
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
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                settings.menuBarStyle == style
                    ? nepaliCrimson.opacity(0.1)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
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
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text(label)
                    .font(.callout)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsTabView(showAbout: {})
        .frame(width: 380, height: 485)
}
