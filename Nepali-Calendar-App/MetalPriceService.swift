//
//  MetalPriceService.swift
//  Nepali-Calendar-App
//
//  Fetches live gold & silver prices in NPR per tola from fenegosida.org —
//  the official Federation of Nepal Gold and Silver Dealers' Association.
//  These are the standard domestic prices that Nepalis reference daily.
//  Caches to UserDefaults; re-fetches only after 24 hours.
//

import Foundation
import Observation
import Aptabase

// MARK: - Model

struct MetalPrices {
    let goldPerTola: Double   // NPR per tola (Hallmark / 24K)
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

    private let cacheGoldKey    = "metalCache.gold"
    private let cacheSilverKey  = "metalCache.silver"
    private let cacheDateKey    = "metalCache.date"
    private let refreshInterval: TimeInterval = 24 * 60 * 60  // 24 h

    private var backoff = ErrorBackoff(key: "metalCache.errorDate")

    // FENEGOSIDA official website — prices on homepage
    private let sourceURL = URL(string: "https://fenegosida.org/")

    private init() {
        loadFromCache()
    }

    // MARK: - Public

    /// Refresh if cache is older than 24 h (or empty).
    func refreshIfNeeded() {
        if let p = prices, Date().timeIntervalSince(p.fetchedAt) < refreshInterval { return }
        if backoff.isActive { return }
        Task { await fetch() }
    }

    /// Force a fresh network fetch regardless of cache age.
    func refresh() {
        Task { await fetch() }
    }

    /// Clear the error-date backoff so `refreshIfNeeded()` will retry.
    func clearErrorBackoff() {
        backoff.clear()
    }

    // MARK: - Network

    @MainActor
    private func fetch() async {
        guard let sourceURL else {
            handleError(reason: "url")
            return
        }
        isLoading = true
        errorMessage = nil

        var request = URLRequest(url: sourceURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("NepaliCalendarPro/1.0 (+mailto:support@noblestack.io)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let html = String(data: data, encoding: .utf8), let parsed = parseHTML(html) {
                prices = parsed
                saveToCache(parsed)
            } else {
                handleError(reason: "parse")
            }
        } catch {
            handleError(reason: "network")
        }

        isLoading = false
    }

    private func handleError(reason: String) {
        errorMessage = reason == "parse" ? "Parse error" : "Network error"
        backoff.record()
        Aptabase.shared.trackEvent("metal_price_error", with: ["reason": reason])
    }

    // MARK: - HTML Parsing

    /// Extracts gold and silver per-tola prices from the `rate-content` div.
    ///
    /// The page has two sections: grams (uses "Nrs") and tola (uses "रु").
    /// We extract the `rate-content` div, find the tola section by looking
    /// for "रु", then pull numbers from `<b>` tags after FINE GOLD and SILVER.
    private func parseHTML(_ html: String) -> MetalPrices? {
        // Step 1: Extract rate-content div
        guard let rateBlock = extractBlock(from: html, start: "class=\"rate-content\"", end: "<!--") else {
            return nil
        }

        // Step 2: Find the tola section — it's the part containing "रु"
        // Split by "header-rate" to separate grams and tola blocks
        let sections = rateBlock.components(separatedBy: "header-rate")
        // Find the section that contains "रु" (tola section)
        guard let tolaSection = sections.first(where: { $0.contains("रु") }) else {
            return nil
        }

        // Step 3: Extract prices from <b> tags after each marker
        let gold = extractBoldPrice(from: tolaSection, marker: "FINE GOLD")
        let silver = extractBoldPrice(from: tolaSection, marker: "SILVER")

        guard let g = gold, let s = silver, g > 0, s > 0 else { return nil }

        // Sanity checks — reject clearly wrong values
        // Gold per tola: ~100K–500K NPR; Silver per tola: ~1K–20K NPR
        guard g >= 100_000, g <= 500_000 else { return nil }
        guard s >= 1_000, s <= 20_000 else { return nil }
        guard g > s else { return nil }  // Gold must always be more expensive

        return MetalPrices(goldPerTola: g, silverPerTola: s, fetchedAt: Date())
    }

    /// Extract a substring between start and end markers.
    private func extractBlock(from html: String, start: String, end: String) -> String? {
        guard let startRange = html.range(of: start) else { return nil }
        let after = html[startRange.upperBound...]
        guard let endRange = after.range(of: end) else { return String(after) }
        return String(after[..<endRange.lowerBound])
    }

    /// Find marker, then extract the number inside the next `<b>...</b>` tag.
    private func extractBoldPrice(from text: String, marker: String) -> Double? {
        guard let markerRange = text.range(of: marker) else { return nil }
        let after = String(text[markerRange.upperBound...].prefix(300))

        let pattern = "<b>\\s*([0-9,]+)\\s*</b>"
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: after, range: NSRange(after.startIndex..., in: after)),
            let range = Range(match.range(at: 1), in: after)
        else { return nil }

        let numStr = after[range].replacingOccurrences(of: ",", with: "")
        return Double(numStr)
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

    /// Formatted NPR string e.g. "रू 3,16,900"
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
