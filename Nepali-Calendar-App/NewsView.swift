//
//  NewsView.swift
//  Nepali-Calendar-App
//
//  News tab: shows today's Nepal headlines from multiple RSS sources.
//  Refreshes on-demand when tab appears, with 5-min cooldown.
//

import SwiftUI
import Aptabase

// Matches the crimson used throughout the app
private let newsCrimson = Color(red: 0.863, green: 0.078, blue: 0.235)

// MARK: - News Tab View

struct NewsView: View {

    @State private var service = NewsFeedService()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "newspaper")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Nepal News")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                // Last updated footer
                if let _ = service.lastUpdated {
                    Text(service.minutesAgoString)
                        .font(.subheadline)
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()

            // Content
            if service.isLoading && service.articles.isEmpty {
                loadingView
            } else if let error = service.fetchError, service.articles.isEmpty {
                emptyStateView(message: error)
            } else if service.articles.isEmpty {
                emptyStateView(message: "No news available for today.")
            } else {
                // "Updating…" bar when refreshing with cached data
                if service.isLoading {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Updating…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.03))
                }
                articleList
            }
        }
        .onAppear {
            service.refreshIfNeeded()
        }
        .onChange(of: service.articles.count) {
            if !service.isLoading && !service.articles.isEmpty {
                Aptabase.shared.trackEvent("news_feed_loaded", with: ["article_count": "\(service.articles.count)"])
            }
        }
    }

    // MARK: - Article List

    private var articleList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 0) {
                ForEach(service.articles) { item in
                    NewsRowView(item: item)
                    if item.id != service.articles.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .frame(height: 420)
    }

    // MARK: - Loading State

    private var loadingView: some View {
        VStack(spacing: 14) {
            ForEach(0..<5, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "newspaper")
                .font(.title.weight(.thin))
                .foregroundStyle(.quaternary)
            Text(message)
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - News Row

struct NewsRowView: View {
    let item: NewsItem
    @State private var isHovered = false

    var body: some View {
        Button {
            if let url = URL(string: item.link) {
                Aptabase.shared.trackEvent("news_article_opened", with: [
                    "source": item.source,
                    "title": String(item.title.prefix(100))
                ])
                NSWorkspace.shared.open(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                // Source badge
                Text(item.source.uppercased())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(newsCrimson.opacity(0.8))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(newsCrimson.opacity(0.08), in: RoundedRectangle(cornerRadius: 3))

                // Headline
                Text(item.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                // Time ago (if available)
                if let pub = item.pubDate {
                    Text(timeAgo(pub))
                        .font(.subheadline)
                        .foregroundStyle(.quaternary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .accessibilityLabel(item.title)
        .accessibilityHint("Opens article in browser")
    }

    private func timeAgo(_ date: Date) -> String {
        let mins = Int(Date().timeIntervalSince(date) / 60)
        if mins < 1 { return "Just now" }
        if mins < 60 { return "\(mins)m ago" }
        let hrs = mins / 60
        if hrs < 24 { return "\(hrs)h ago" }
        return "\(hrs / 24)d ago"
    }
}

// MARK: - Skeleton Row (loading placeholder)

struct SkeletonRow: View {
    @State private var animating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(animating ? 0.06 : 0.09))
                .frame(width: 80, height: 8)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(animating ? 0.06 : 0.09))
                .frame(maxWidth: .infinity)
                .frame(height: 10)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(animating ? 0.04 : 0.07))
                .frame(maxWidth: 200)
                .frame(height: 10)
        }
        .padding(.vertical, 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }
}

#Preview {
    NewsView()
        .frame(width: 340)
}
