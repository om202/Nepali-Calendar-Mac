//
//  ErrorBackoff.swift
//  Nepali-Calendar-App
//
//  Shared 24-hour error backoff used by CurrencyService, MetalPriceService,
//  and FuelWeatherService to avoid hammering a flaky upstream endpoint.
//  Persists the last-error timestamp in UserDefaults.
//

import Foundation

struct ErrorBackoff {
    private let key: String
    private let interval: TimeInterval

    private(set) var errorDate: Date?

    init(key: String, interval: TimeInterval = 24 * 60 * 60) {
        self.key = key
        self.interval = interval
        self.errorDate = UserDefaults.standard.object(forKey: key) as? Date
    }

    /// True when a recent error is still within the backoff window —
    /// callers should skip any retry fetch until the window expires.
    var isActive: Bool {
        guard let d = errorDate else { return false }
        return Date().timeIntervalSince(d) < interval
    }

    mutating func record() {
        let now = Date()
        errorDate = now
        UserDefaults.standard.set(now, forKey: key)
    }

    mutating func clear() {
        errorDate = nil
        UserDefaults.standard.removeObject(forKey: key)
    }
}
