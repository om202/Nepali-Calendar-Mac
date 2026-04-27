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
import Aptabase

struct SettingsTabView: View {
    let showAbout: () -> Void

    @State private var settings = AppSettings.shared
    /// Tracks whether the user has ever engaged with rating (tapped the
    /// Settings row or confirmed the pre-prompt). Used only to hide the
    /// row once used — the real prompt-throttling lives in ReviewCoordinator.
    @AppStorage("hasRatedApp") private var hasRatedApp: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            tabHeader

            Divider()

            Form {
                Section("Download our other app") {
                    rapidPhotoRow
                }

                Section("General") {
                    launchAtLoginToggle
                    aboutRow
                }

                Section("Menu Bar Display") {
                    ForEach(MenuBarDisplayStyle.allCases.filter { $0.section == "नेपाली" }, id: \.self) { style in
                        menuBarStyleRow(style)
                    }
                    ForEach(MenuBarDisplayStyle.allCases.filter { $0.section == "English" }, id: \.self) { style in
                        menuBarStyleRow(style)
                    }
                }

                if !hasRatedApp {
                    Section {
                        navigationRow(
                            icon: "star",
                            tint: .yellow,
                            title: "Rate Nepali Calendar",
                            trailing: .chevron
                        ) {
                            ReviewCoordinator.shared.tapFromSettings()
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

    // MARK: - About Row

    private var aboutRow: some View {
        Button {
            Aptabase.shared.trackEvent("info_opened")
            showAbout()
        } label: {
            HStack(spacing: 10) {
                Label {
                    Text("About")
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .font(.body)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - RapidPhoto Row

    private var rapidPhotoRow: some View {
        Button {
            Aptabase.shared.trackEvent("download_rapidphoto_tapped")
            if let url = URL(string: "https://apps.apple.com/us/app/rapidphoto-batch-crop-edit/id6758485661?mt=12") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image("RapidPhotoLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Download RapidPhoto")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Made for photographers in hurry. Bulk edit multiple photos at once.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(rapidPhotoRowBackground)
    }

    /// Subtle grayish light-blue background that adapts to light / dark
    /// appearance — used to make the cross-promo row stand apart from
    /// the regular settings rows.
    private var rapidPhotoRowBackground: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [
                .darkAqua,
                .vibrantDark,
                .accessibilityHighContrastDarkAqua,
                .accessibilityHighContrastVibrantDark,
            ]) != nil
            return isDark
                ? NSColor(srgbRed: 0.20, green: 0.26, blue: 0.33, alpha: 1.0)
                : NSColor(srgbRed: 0.86, green: 0.91, blue: 0.97, alpha: 1.0)
        })
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
