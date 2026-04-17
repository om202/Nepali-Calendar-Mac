//
//  CurrencyService.swift
//  Nepali-Calendar-App
//
//  Fetches live exchange rates relative to NPR from ExchangeRate-API
//  (open.er-api.com) — free, no API key required, updates daily.
//  Caches to UserDefaults; re-fetches only after 24 hours.
//

import Foundation
import Observation
import Aptabase

// MARK: - Model

struct CurrencyInfo: Identifiable {
    let code: String
    let flag: String
    let name: String
    let ratePerNPR: Double   // How many NPR for 1 unit of this currency
    var id: String { code }
}

struct CurrencyRates {
    let rates: [String: Double]  // code → NPR per 1 unit
    let fetchedAt: Date
}

// MARK: - Service

@Observable
final class CurrencyService {

    static let shared = CurrencyService()

    // Observed state
    var rates: CurrencyRates?
    var isLoading = false
    var errorMessage: String?

    /// True when cached data exists but is older than the refresh interval.
    var isStale: Bool {
        guard let r = rates else { return false }
        return Date().timeIntervalSince(r.fetchedAt) >= refreshInterval
    }

    private let cacheRatesKey  = "currencyCache.rates"
    private let cacheDateKey   = "currencyCache.date"
    private let errorDateKey   = "currencyCache.errorDate"
    private let refreshInterval: TimeInterval = 24 * 60 * 60  // 24 h

    private var errorDate: Date? = nil

    // ExchangeRate-API Open Access — no key needed
    private let sourceURL = URL(string: "https://open.er-api.com/v6/latest/USD")!

    /// Currencies relevant to Nepalis — ordered by importance.
    static let displayCurrencies: [(code: String, flag: String, name: String)] = [
        // Tier 1 — Global reserves & most used
        ("USD", "🇺🇸", "US Dollar"),
        ("EUR", "🇪🇺", "Euro"),
        ("GBP", "🇬🇧", "British Pound"),

        // Tier 2 — Gulf remittance (largest corridor for Nepali workers)
        ("AED", "🇦🇪", "UAE Dirham"),
        ("SAR", "🇸🇦", "Saudi Riyal"),
        ("QAR", "🇶🇦", "Qatari Riyal"),
        ("KWD", "🇰🇼", "Kuwaiti Dinar"),
        ("BHD", "🇧🇭", "Bahraini Dinar"),
        ("OMR", "🇴🇲", "Omani Rial"),

        // Tier 3 — Neighbor & major diaspora
        ("INR", "🇮🇳", "Indian Rupee"),
        ("AUD", "🇦🇺", "Australian Dollar"),
        ("JPY", "🇯🇵", "Japanese Yen"),
        ("KRW", "🇰🇷", "Korean Won"),
        ("MYR", "🇲🇾", "Malaysian Ringgit"),
        ("CAD", "🇨🇦", "Canadian Dollar"),

        // Tier 4 — Growing diaspora & regional
        ("SGD", "🇸🇬", "Singapore Dollar"),
        ("HKD", "🇭🇰", "Hong Kong Dollar"),
        ("NZD", "🇳🇿", "New Zealand Dollar"),
        ("CHF", "🇨🇭", "Swiss Franc"),
        ("ILS", "🇮🇱", "Israeli Shekel"),
        ("THB", "🇹🇭", "Thai Baht"),

        // Tier 5 — South Asia
        ("BDT", "🇧🇩", "Bangladeshi Taka"),
        ("PKR", "🇵🇰", "Pakistani Rupee"),
        ("LKR", "🇱🇰", "Sri Lankan Rupee"),

        // Tier 6 — Other significant world currencies
        ("CNY", "🇨🇳", "Chinese Yuan"),
        ("TWD", "🇹🇼", "Taiwan Dollar"),
        ("PHP", "🇵🇭", "Philippine Peso"),
        ("IDR", "🇮🇩", "Indonesian Rupiah"),
        ("VND", "🇻🇳", "Vietnamese Dong"),
        ("SEK", "🇸🇪", "Swedish Krona"),
        ("NOK", "🇳🇴", "Norwegian Krone"),
        ("DKK", "🇩🇰", "Danish Krone"),
        ("PLN", "🇵🇱", "Polish Zloty"),
        ("CZK", "🇨🇿", "Czech Koruna"),
        ("BRL", "🇧🇷", "Brazilian Real"),
        ("MXN", "🇲🇽", "Mexican Peso"),
        ("TRY", "🇹🇷", "Turkish Lira"),
        ("ZAR", "🇿🇦", "South African Rand"),
        ("EGP", "🇪🇬", "Egyptian Pound"),
        ("RUB", "🇷🇺", "Russian Ruble"),
    ]

    private init() {
        loadFromCache()
    }

    // MARK: - Public

    /// Refresh if cache is older than 24 h (or empty).
    func refreshIfNeeded() {
        if let r = rates, Date().timeIntervalSince(r.fetchedAt) < refreshInterval { return }
        // Skip if last error was within 24h
        if let errDate = errorDate, Date().timeIntervalSince(errDate) < refreshInterval { return }
        Task { await fetch() }
    }

    /// Force a fresh network fetch regardless of cache age.
    func refresh() {
        Task { await fetch() }
    }

    /// Clear the error-date backoff so `refreshIfNeeded()` will retry.
    func clearErrorBackoff() {
        errorDate = nil
        UserDefaults.standard.removeObject(forKey: errorDateKey)
    }

    /// Returns display-ready currency info list.
    var displayRates: [CurrencyInfo] {
        guard let r = rates else { return [] }
        return Self.displayCurrencies.compactMap { currency in
            guard let nprRate = r.rates[currency.code] else { return nil }
            return CurrencyInfo(
                code: currency.code,
                flag: currency.flag,
                name: currency.name,
                ratePerNPR: nprRate
            )
        }
    }

    /// Returns NPR rate for a single currency code. Reusable for main UI (USD/EUR).
    func rate(for code: String) -> Double? {
        rates?.rates[code]
    }

    // MARK: - Network

    @MainActor
    private func fetch() async {
        isLoading = true
        errorMessage = nil

        var request = URLRequest(url: sourceURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("NepaliCalendarPro/1.0 (+mailto:support@noblestack.io)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let parsed = parseJSON(data) {
                rates = parsed
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
        let now = Date()
        errorDate = now
        UserDefaults.standard.set(now, forKey: errorDateKey)
        Aptabase.shared.trackEvent("currency_error", with: ["reason": reason])
    }

    // MARK: - JSON Parsing

    /// Parses the ExchangeRate-API response and converts all rates to NPR-based.
    /// API returns rates relative to USD; we compute: NPR_per_1_unit = nprRate / currencyRate.
    private func parseJSON(_ data: Data) -> CurrencyRates? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let result = json["result"] as? String, result == "success",
            let rawRates = json["rates"] as? [String: Double],
            let nprRate = rawRates["NPR"], nprRate > 0
        else { return nil }

        // Convert from USD-based to NPR-based: how many NPR for 1 unit of each currency
        var nprRates: [String: Double] = [:]
        for (code, usdRate) in rawRates where usdRate > 0 {
            nprRates[code] = nprRate / usdRate
        }

        return CurrencyRates(rates: nprRates, fetchedAt: Date())
    }

    // MARK: - Cache

    private func saveToCache(_ r: CurrencyRates) {
        let ud = UserDefaults.standard
        // Store as JSON data
        if let data = try? JSONSerialization.data(withJSONObject: r.rates) {
            ud.set(data, forKey: cacheRatesKey)
        }
        ud.set(r.fetchedAt, forKey: cacheDateKey)
    }

    private func loadFromCache() {
        let ud = UserDefaults.standard
        guard
            let date = ud.object(forKey: cacheDateKey) as? Date,
            let data = ud.data(forKey: cacheRatesKey),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Double]
        else { return }

        rates = CurrencyRates(rates: dict, fetchedAt: date)

        if let errDate = ud.object(forKey: errorDateKey) as? Date {
            errorDate = errDate
        }
    }
}

// MARK: - Formatting Helpers

extension CurrencyService {

    /// Format NPR rate: "रू 147.00" for most, "रू 0.10" for weak currencies.
    static func formatRate(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "रू \(formatted)"
    }

    /// "Updated X min/hr ago" caption.
    func updatedCaption() -> String {
        guard let date = rates?.fetchedAt else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60        { return "भर्खर अपडेट" }
        if interval < 3600      { return "\(Int(interval / 60)) मिनेट अघि" }
        if interval < 86400     { return "\(Int(interval / 3600)) घण्टा अघि" }
        return "१ दिन अघि"
    }
}
