//
//  InfoView.swift
//  Nepali-Calendar-App
//
//  About page with app & company information.
//

import SwiftUI
import Aptabase

// MARK: - Info Pane (InfoView with a back button; shown inline in popover)

struct InfoPaneView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onDone) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                        Text("Calendar")
                    }
                    .foregroundStyle(nepaliCrimson)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to Calendar")

                Spacer()

                Text("About")
                    .font(.headline)

                Spacer()

                // Invisible spacer to keep title centered
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                    Text("Calendar")
                }
                .hidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            InfoView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Info / About View

struct InfoView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: App Icon + Name
                VStack(spacing: 8) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

                    Text("Nepali Calendar (Pro)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("Version \(version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 14)

                Divider()
                    .padding(.horizontal, 24)

                // MARK: Contact
                VStack(spacing: 8) {
                    Text("If you have any queries, want to report bugs,\nor have any concerns with the app,\nfeel free to reach out to us at")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Aptabase.shared.trackEvent("contact_email_tapped")
                        if let url = URL(string: "mailto:info@noblestack.io") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "envelope.fill")
                                .font(.subheadline)
                            Text("info@noblestack.io")
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

                Divider()
                    .padding(.horizontal, 24)

                // MARK: New Projects
                VStack(spacing: 8) {
                    Text("We are open to new projects!")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("We specialize in AI-powered solutions,\nmodern web & mobile app development,\nand end-to-end business automation.\nHave an idea? Let's build it together.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Button {
                        Aptabase.shared.trackEvent("sales_email_tapped")
                        if let url = URL(string: "mailto:sales@noblestack.io") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "paperplane.fill")
                                .font(.subheadline)
                            Text("sales@noblestack.io")
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

                Divider()
                    .padding(.horizontal, 24)

                // MARK: Built By
                VStack(spacing: 8) {
                    Text("Built by")
                        .font(.subheadline)
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
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                Spacer(minLength: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: .infinity)
    }
}
