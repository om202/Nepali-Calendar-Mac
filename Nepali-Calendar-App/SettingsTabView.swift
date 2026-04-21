//
//  SettingsTabView.swift
//  Nepali-Calendar-App
//
//  Consolidated settings tab: menu-bar display style, launch at login,
//  rate prompt (hides once tapped), about link, and cross-promo.
//  Layout follows macOS System Settings conventions: grouped Form,
//  titled sections, native Picker / Toggle, inset rows.
//

import SwiftUI
import StoreKit
import Aptabase

struct SettingsTabView: View {
    let showAbout: () -> Void

    @State private var settings = AppSettings.shared
    /// Tracks whether the user has ever engaged with rating (tapped the
    /// Settings row or confirmed the pre-prompt). Used only to hide the
    /// row once used — the real prompt-throttling lives in ReviewCoordinator.
    @AppStorage("hasRatedApp") private var hasRatedApp: Bool = false

    @Environment(\.requestReview) private var requestReview

    var body: some View {
        VStack(spacing: 0) {
            tabHeader

            Divider()

            Form {
                Section {
                    ForEach(MenuBarDisplayStyle.allCases.filter { $0.section == "नेपाली" }, id: \.self) { style in
                        menuBarStyleRow(style)
                    }
                } header: {
                    Text("Menu Bar — नेपाली")
                }

                Section {
                    ForEach(MenuBarDisplayStyle.allCases.filter { $0.section == "English" }, id: \.self) { style in
                        menuBarStyleRow(style)
                    }
                } header: {
                    Text("Menu Bar — English")
                }

                Section("General") {
                    launchAtLoginToggle
                }

                Section {
                    if !hasRatedApp {
                        navigationRow(
                            icon: "star",
                            tint: .yellow,
                            title: "Rate Nepali Calendar",
                            trailing: .chevron
                        ) {
                            hasRatedApp = true
                            ReviewCoordinator.shared.tapFromSettings(requestReview: { requestReview() })
                        }
                    }
                    navigationRow(
                        icon: "info.circle",
                        tint: .blue,
                        title: "About",
                        trailing: .chevron
                    ) {
                        Aptabase.shared.trackEvent("info_opened")
                        showAbout()
                    }
                    navigationRow(
                        icon: "arrow.down.circle",
                        tint: .green,
                        title: "Download RapidPhoto",
                        trailing: .externalLink
                    ) {
                        Aptabase.shared.trackEvent("download_rapidphoto_tapped")
                        if let url = URL(string: "https://apps.apple.com/us/app/rapidphoto-batch-crop-edit/id6758485661?mt=12") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Tab Header

    private var tabHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "gearshape")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Settings")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    // MARK: - Menu Bar Display Row

    private func menuBarStyleRow(_ style: MenuBarDisplayStyle) -> some View {
        let isSelected = settings.menuBarStyle == style
        return Button {
            settings.menuBarStyle = style
            Aptabase.shared.trackEvent("menu_bar_style_changed", with: ["style": style.rawValue])
        } label: {
            HStack(spacing: 8) {
                Text(style.label)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(nepaliCrimson)
                    .opacity(isSelected ? 1 : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(style.label). \(isSelected ? "Selected." : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Launch at Login

    private var launchAtLoginToggle: some View {
        Toggle(isOn: Binding(
            get: { settings.launchAtLogin },
            set: {
                settings.launchAtLogin = $0
                Aptabase.shared.trackEvent("launch_at_login_toggled", with: ["enabled": $0 ? "true" : "false"])
            }
        )) {
            Label {
                Text("Launch at Login")
            } icon: {
                Image(systemName: "power")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Navigation Row

    private enum RowTrailing {
        case chevron, externalLink, none
    }

    @ViewBuilder
    private func navigationRow(
        icon: String,
        tint: Color,
        title: String,
        trailing: RowTrailing,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                iconBadge(symbol: icon, tint: tint)

                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                switch trailing {
                case .chevron:
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                case .externalLink:
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                case .none:
                    EmptyView()
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Colored rounded-square badge containing a white SF Symbol — the
    /// standard macOS System Settings row-icon treatment.
    private func iconBadge(symbol: String, tint: Color) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(tint.gradient)
            .frame(width: 20, height: 20)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}

#Preview {
    SettingsTabView(showAbout: {})
        .frame(width: 380, height: 485)
}
