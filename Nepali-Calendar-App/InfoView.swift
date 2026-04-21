//
//  InfoView.swift
//  Nepali-Calendar-App
//
//  About page with app & company information. Presented as a pushed
//  pane inside the popover (InfoPaneView wraps it with a back bar).
//  Layout follows the same spacing / typography tokens as the tabs.
//

import SwiftUI
import Aptabase

// MARK: - Info Pane (back bar + InfoView)

struct InfoPaneView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            backBar

            Divider()

            InfoView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Back bar — matches the tab-header metrics

    private var backBar: some View {
        HStack {
            Button(action: onDone) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                    Text("Settings")
                }
                .foregroundStyle(nepaliCrimson)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to Settings")

            Spacer()

            Text("About")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            // Invisible spacer to keep the title centered
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                Text("Settings")
            }
            .hidden()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }
}

// MARK: - Info / About View

struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                appIdentity

                divider

                contactSection

                divider

                newProjectsSection

                divider

                builtBySection

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - App identity

    private var appIdentity: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

            Text("Nepali Calendar (Pro)")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Version \(version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Contact

    private var contactSection: some View {
        VStack(spacing: 10) {
            Text("If you have any queries, want to report bugs,\nor have any concerns with the app,\nfeel free to reach out to us at")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            linkButton(
                label: "info@noblestack.io",
                icon: "envelope.fill",
                tracking: "contact_email_tapped"
            ) {
                if let url = URL(string: "mailto:info@noblestack.io") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    // MARK: - New projects

    private var newProjectsSection: some View {
        VStack(spacing: 10) {
            Text("We are open to new projects!")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)

            Text("We specialize in AI-powered solutions,\nmodern web & mobile app development,\nand end-to-end business automation.\nHave an idea? Let's build it together.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            linkButton(
                label: "sales@noblestack.io",
                icon: "paperplane.fill",
                tracking: "sales_email_tapped"
            ) {
                if let url = URL(string: "mailto:sales@noblestack.io") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    // MARK: - Built by

    private var builtBySection: some View {
        VStack(spacing: 8) {
            Text("BUILT BY")
                .font(.caption2.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)

            Button {
                Aptabase.shared.trackEvent("noblestack_website_tapped")
                if let url = URL(string: "https://www.noblestack.io/") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Noble Stack")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(nepaliCrimson)
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(nepaliCrimson.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            Text("An AI-first software company based in\nKathmandu, Nepal 🇳🇵")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Reusable pieces

    private var divider: some View {
        Divider()
            .padding(.horizontal, 24)
    }

    private func linkButton(
        label: String,
        icon: String,
        tracking: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Aptabase.shared.trackEvent(tracking)
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(label)
                    .font(.callout.weight(.medium))
            }
            .foregroundStyle(nepaliCrimson)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
