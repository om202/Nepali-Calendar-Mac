//
//  ReviewPromptSheet.swift
//  Nepali-Calendar-App
//
//  Happy-path pre-prompt overlay ("Enjoying Nepali Calendar?") shown before
//  Apple's SKStoreReviewController sheet. Yes routes to the store sheet;
//  Not really routes to feedback email; Later dismisses.
//

import SwiftUI

struct ReviewPromptSheet: View {
    let onYes: () -> Void
    let onNotReally: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(nepaliCrimson.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "heart.fill")
                    .font(.title)
                    .foregroundStyle(nepaliCrimson)
            }
            .padding(.top, 4)

            Text("Enjoying Nepali Calendar?")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Your feedback shapes what we build next.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                Button(action: onYes) {
                    Text("Yes, I love it")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(nepaliCrimson)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onNotReally) {
                    Text("Not really")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.secondary.opacity(0.12))
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onLater) {
                    Text("Ask me later")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.22), radius: 16, y: 6)
        .padding(20)
    }
}

#Preview {
    ReviewPromptSheet(onYes: {}, onNotReally: {}, onLater: {})
        .frame(width: 380, height: 400)
}
