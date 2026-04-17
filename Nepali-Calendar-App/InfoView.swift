//
//  InfoView.swift
//  Nepali-Calendar-App
//
//  About page with app & company information.
//

import SwiftUI
import Aptabase

// MARK: - Info / About View

struct InfoView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: App Icon + Name
                VStack(spacing: 10) {
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
                .padding(.top, 20)

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
                        .font(.caption)
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

                Spacer(minLength: 12)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 420)
    }
}
