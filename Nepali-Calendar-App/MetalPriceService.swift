//
//  MetalPriceService.swift
//  Nepali-Calendar-App
//
//  Fetches live gold & silver prices in NPR from goldprice.org.
//  Converts troy-oz prices to NPR per tola (Nepali standard unit).
//  Caches to UserDefaults; re-fetches only after 24 hours.
//

import Foundation
import Observation
import Aptabase

// MARK: - Model

struct MetalPrices {
    let goldPerTola: Double   // NPR per tola (24K)
    let silverPerTola: Double // NPR per tola
    let fetchedAt: Date
}

// MARK: - Service

@Observable
final class MetalPriceService {

    static let shared = MetalPriceService()

    // Observed state
    var prices: MetalPrices?
    var isLoading = false
    var errorMessage: String?

    /// True when cached data exists but is older than the refresh interval.
    var isStale: Bool {
        guard let p = prices else { return false }
        return Date().timeIntervalSince(p.fetchedAt) >= refreshInterval
    }

    // 1 tola = 11.6638g, 1 troy oz = 31.1035g
    private let troYOzToTola = 11.6638 / 31.1035   // ≈ 0.37499

    private let cacheGoldKey    = "metalCache.gold"
    private let cacheSilverKey  = "metalCache.silver"
    private let cacheDateKey    = "metalCache.date"
    private let refreshInterval: TimeInterval = 24 * 60 * 60  // 24 h

    private init() {
        loadFromCache()
    }

    // MARK: - Public

    /// Refresh if cache is older than 24 h (or empty).
    func refreshIfNeeded() {
        if let p = prices, Date().timeIntervalSince(p.fetchedAt) < refreshInterval { return }
        Task { await fetch() }
    }

    /// Force a fresh network fetch regardless of cache age.
    func refresh() {
        Task { await fetch() }
    }

    // MARK: - Network

    @MainActor
    private func fetch() async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://data-asg.goldprice.org/dbXRates/NPR") else {
            isLoading = false; return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        // goldprice.org requires a browser-like User-Agent; returns 403 otherwise
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("https://goldprice.org", forHTTPHeaderField: "Referer")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let parsed = parse(data) {
                prices = parsed
                saveToCache(parsed)
            } else {
                errorMessage = "Parse error"
                Aptabase.shared.trackEvent("metal_price_error", with: ["reason": "parse"])
            }
        } catch {
            errorMessage = "Network error"
            Aptabase.shared.trackEvent("metal_price_error", with: ["reason": "network"])
        }

        isLoading = false
    }

    // MARK: - Parsing

    private func parse(_ data: Data) -> MetalPrices? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let items = json["items"] as? [[String: Any]],
            let item = items.first,
            let xau = item["xauPrice"] as? Double,
            let xag = item["xagPrice"] as? Double
        else { return nil }

        return MetalPrices(
            goldPerTola:   xau * troYOzToTola,
            silverPerTola: xag * troYOzToTola,
            fetchedAt:     Date()
        )
    }

    // MARK: - Cache

    private func saveToCache(_ p: MetalPrices) {
        let ud = UserDefaults.standard
        ud.set(p.goldPerTola,   forKey: cacheGoldKey)
        ud.set(p.silverPerTola, forKey: cacheSilverKey)
        ud.set(p.fetchedAt,     forKey: cacheDateKey)
    }

    private func loadFromCache() {
        let ud = UserDefaults.standard
        guard
            let date = ud.object(forKey: cacheDateKey) as? Date,
            ud.double(forKey: cacheGoldKey) > 0
        else { return }

        prices = MetalPrices(
            goldPerTola:   ud.double(forKey: cacheGoldKey),
            silverPerTola: ud.double(forKey: cacheSilverKey),
            fetchedAt:     date
        )
    }
}

// MARK: - Formatting Helpers

extension MetalPriceService {

    /// Formatted NPR string e.g. "रू 1,67,340"
    static func formatNPR(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSize = 3
        // Nepali grouping: last 3, then 2s — approximate with standard grouping
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "रू \(formatted)"
    }

    /// "Updated X min/hr ago" caption.
    func updatedCaption() -> String {
        guard let date = prices?.fetchedAt else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60        { return "भर्खर अपडेट" }
        if interval < 3600      { return "\(Int(interval / 60)) मिनेट अघि" }
        if interval < 86400     { return "\(Int(interval / 3600)) घण्टा अघि" }
        return "१ दिन अघि"
    }
}
