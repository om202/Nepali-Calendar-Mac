//
//  CurrencyView.swift
//  Nepali-Calendar-App
//
//  Displays live exchange rates of major world currencies against NPR.
//  Data sourced from ExchangeRate-API (free, no key).
//  UI mirrors NewsView for visual consistency across tabs.
//

import SwiftUI
import Aptabase

struct CurrencyView: View {
    private let service = CurrencyService.shared
    var embedded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if !embedded {
                // Header — matches NewsView pattern
                HStack(spacing: 6) {
                    Image(systemName: "coloncurrencysign.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Exchange Rates")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if rates != nil {
                        Text(service.updatedCaption())
                            .font(.subheadline)
                            .foregroundStyle(.quaternary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

                Divider()
            } else if rates != nil {
                HStack {
                    Spacer()
                    Text(service.updatedCaption())
                        .font(.subheadline)
                        .foregroundStyle(.quaternary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }

            // Content
            if service.isLoading && service.displayRates.isEmpty {
                loadingView
            } else if service.displayRates.isEmpty {
                emptyStateView
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
                currencyList

                Divider()
                attributionFooter
            }
        }
        .onAppear {
            service.refreshIfNeeded()
            Aptabase.shared.trackEvent("currency_tab_opened")
        }
    }

    // MARK: - Attribution

    private var attributionFooter: some View {
        Button {
            if let url = URL(string: "https://www.exchangerate-api.com") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                Text("Rates by ExchangeRate-API")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Exchange rate data by ExchangeRate-API. Opens website.")
    }

    // MARK: - Helpers

    private var rates: CurrencyRates? { service.rates }

    // MARK: - Currency List

    private var currencyList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 0) {
                ForEach(service.displayRates) { currency in
                    CurrencyRowView(currency: currency)
                    if currency.code != service.displayRates.last?.code {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Loading State

    private var loadingView: some View {
        VStack(spacing: 14) {
            ForEach(0..<6, id: \.self) { _ in
                CurrencySkeletonRow()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "coloncurrencysign.circle")
                .font(.title.weight(.thin))
                .foregroundStyle(.quaternary)
            Text("Exchange rates unavailable")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                service.refresh()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Currency Row

struct CurrencyRowView: View {
    let currency: CurrencyInfo
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Flag
            Text(currency.flag)
                .font(.title3)

            // Code + Name
            VStack(alignment: .leading, spacing: 2) {
                Text(currency.code)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(currency.name)
                    .font(.subheadline)
                    .foregroundStyle(.quaternary)
                    .lineLimit(1)
            }

            Spacer()

            // NPR Rate
            Text(CurrencyService.formatRate(currency.ratePerNPR))
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Skeleton Row (loading placeholder)

struct CurrencySkeletonRow: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 10) {
            // Flag placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(animating ? 0.06 : 0.09))
                .frame(width: 24, height: 24)

            // Text placeholders
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(animating ? 0.06 : 0.09))
                    .frame(width: 40, height: 8)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(animating ? 0.04 : 0.07))
                    .frame(width: 90, height: 7)
            }

            Spacer()

            // Rate placeholder
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.primary.opacity(animating ? 0.06 : 0.09))
                .frame(width: 70, height: 10)
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
    CurrencyView()
        .frame(width: 340)
}
