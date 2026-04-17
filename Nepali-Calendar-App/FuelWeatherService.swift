//
//  FuelWeatherService.swift
//  Nepali-Calendar-App
//
//  Provides two data streams:
//  1. Fuel prices — scraped from noc.org.np/petrol (Kathmandu prices), refreshes every 24h.
//  2. Kathmandu weather — live from Open-Meteo, refreshes every 30 minutes.
//

import Foundation
import Observation
import Aptabase

// MARK: - Weather Model

struct KathmanduWeather {
    let temperatureCelsius: Double
    let weatherCode: Int
    let fetchedAt: Date

    /// Maps WMO weather code → SF Symbol name.
    var symbolName: String {
        switch weatherCode {
        case 0, 1:        return "sun.max.fill"
        case 2:           return "cloud.sun.fill"
        case 3:           return "cloud.fill"
        case 45, 48:      return "cloud.fog.fill"
        case 51, 53, 55:  return "cloud.drizzle.fill"
        case 61, 63, 65:  return "cloud.rain.fill"
        case 71, 73, 75:  return "cloud.snow.fill"
        case 77:          return "snowflake"
        case 80, 81, 82:  return "cloud.heavyrain.fill"
        case 85, 86:      return "cloud.snow.fill"
        case 95, 96, 99:  return "cloud.bolt.rain.fill"
        default:          return "thermometer"
        }
    }

    var temperatureString: String { "\(Int(temperatureCelsius.rounded()))°C" }

    /// Maps WMO weather code → human-readable condition text.
    var conditionText: String {
        switch weatherCode {
        case 0:            return "खुला आकाश"
        case 1:            return "प्रायः खुला"
        case 2:            return "आंशिक बादल"
        case 3:            return "बादल"
        case 45, 48:       return "कुहिरो"
        case 51, 53, 55:   return "झिसमिसे"
        case 61, 63, 65:   return "वर्षा"
        case 71, 73, 75:   return "हिउँ"
        case 77:           return "हिउँ"
        case 80, 81, 82:   return "झरी"
        case 85, 86:       return "हिउँ झरी"
        case 95, 96, 99:   return "चट्याङ"
        default:           return "काठमाडौं"
        }
    }
}

// MARK: - Fuel Model

struct FuelPrices {
    let petrolPerLitre: Double   // NPR
    let dieselPerLitre: Double   // NPR
    let fetchedAt: Date
}

// MARK: - Service

@Observable
final class FuelWeatherService {

    static let shared = FuelWeatherService()

    // MARK: Observed state

    var weather: KathmanduWeather?
    var weatherError: Bool = false
    var isLoadingWeather = false

    var fuel: FuelPrices?
    var fuelError: Bool = false
    var isLoadingFuel = false

    /// True when cached fuel data exists but is older than the refresh interval.
    var isFuelStale: Bool {
        guard let f = fuel else { return false }
        return Date().timeIntervalSince(f.fetchedAt) >= fuelRefreshInterval
    }
    private var fuelBackoff = ErrorBackoff(key: "fws.fuel.errorDate")

    // MARK: Constants

    private let weatherRefreshInterval: TimeInterval = 30 * 60      // 30 min
    private let fuelRefreshInterval:    TimeInterval = 24 * 60 * 60 // 24 h

    // Cache keys
    private let weatherDateKey  = "fws.weather.date"
    private let weatherTempKey  = "fws.weather.temp"
    private let weatherCodeKey  = "fws.weather.code"
    private let fuelDateKey     = "fws.fuel.date"
    private let fuelPetrolKey   = "fws.fuel.petrol"
    private let fuelDieselKey   = "fws.fuel.diesel"

    private let weatherURL = URL(string:
        "https://api.open-meteo.com/v1/forecast" +
        "?latitude=27.7172&longitude=85.3240" +
        "&current=temperature_2m,weathercode" +
        "&timezone=Asia%2FKathmandu"
    )

    // NOC petrol page — ticker contains Kathmandu price for both Petrol and Diesel
    private let nocPetrolURL = URL(string: "https://noc.org.np/petrol")

    private init() {
        loadFromCache()
    }

    // MARK: - Public triggers

    func refreshWeatherIfNeeded() {
        if let w = weather, Date().timeIntervalSince(w.fetchedAt) < weatherRefreshInterval { return }
        Task { await fetchWeather() }
    }

    func refreshFuelIfNeeded() {
        if let f = fuel, Date().timeIntervalSince(f.fetchedAt) < fuelRefreshInterval { return }
        if fuelBackoff.isActive { return }
        Task { await fetchFuel() }
    }

    /// Clear the fuel error-date backoff so `refreshFuelIfNeeded()` will retry.
    func clearFuelErrorBackoff() {
        fuelBackoff.clear()
    }

    // MARK: - Weather fetch

    @MainActor
    private func fetchWeather() async {
        guard let weatherURL else {
            weatherError = true
            Aptabase.shared.trackEvent("weather_error", with: ["reason": "url"])
            return
        }
        isLoadingWeather = true
        weatherError = false
        defer { isLoadingWeather = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: weatherURL)
            if let w = parseWeather(data) {
                weather = w
                saveWeather(w)
            } else {
                weatherError = true
                Aptabase.shared.trackEvent("weather_error", with: ["reason": "parse"])
            }
        } catch {
            weatherError = true
            Aptabase.shared.trackEvent("weather_error", with: ["reason": "network"])
        }
    }

    private func parseWeather(_ data: Data) -> KathmanduWeather? {
        guard
            let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let current = json["current"] as? [String: Any],
            let temp    = current["temperature_2m"] as? Double,
            let code    = current["weathercode"] as? Int
        else { return nil }
        return KathmanduWeather(temperatureCelsius: temp, weatherCode: code, fetchedAt: Date())
    }

    // MARK: - Fuel fetch (scrape NOC)

    @MainActor
    private func fetchFuel() async {
        guard let nocPetrolURL else {
            fuelError = true
            fuelBackoff.record()
            Aptabase.shared.trackEvent("fuel_price_error", with: ["reason": "url"])
            return
        }
        isLoadingFuel = true
        fuelError = false
        defer { isLoadingFuel = false }

        do {
            var req = URLRequest(url: nocPetrolURL)
            req.setValue("NepaliCalendarPro/1.0 (+mailto:support@noblestack.io)", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: req)
            if let html = String(data: data, encoding: .utf8), let f = parseFuel(html) {
                fuel = f
                saveFuel(f)
            } else {
                fuelError = true
                fuelBackoff.record()
                Aptabase.shared.trackEvent("fuel_price_error", with: ["reason": "parse"])
            }
        } catch {
            fuelError = true
            fuelBackoff.record()
            Aptabase.shared.trackEvent("fuel_price_error", with: ["reason": "network"])
        }
    }

    /// Extracts Kathmandu petrol and diesel prices from the NOC ticker.
    /// The ticker is a marquee with city blocks like:
    ///   (Kathmandu, Pokhara, Dipayal)  Petrol(MS):NRs 172.0/L • Diesel(HSD):NRs 152.0/L ...
    /// We find "Kathmandu" in the HTML and extract prices from the text that follows.
    private func parseFuel(_ html: String) -> FuelPrices? {
        // Find "Kathmandu" and take a window of text after it for price extraction
        guard let range = html.range(of: "Kathmandu") else { return nil }
        let after = String(html[range.upperBound...].prefix(500))

        guard
            let petrol = extractPrice(from: after, pattern: "Petrol\\(MS\\):NRs ([0-9.]+)"),
            let diesel = extractPrice(from: after, pattern: "Diesel\\(HSD\\):NRs ([0-9.]+)")
        else { return nil }

        return FuelPrices(petrolPerLitre: petrol, dieselPerLitre: diesel, fetchedAt: Date())
    }

    private func extractPrice(from text: String, pattern: String) -> Double? {
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
            let range = Range(match.range(at: 1), in: text)
        else { return nil }
        return Double(text[range])
    }

    // MARK: - Cache persistence

    private func saveWeather(_ w: KathmanduWeather) {
        let ud = UserDefaults.standard
        ud.set(w.temperatureCelsius, forKey: weatherTempKey)
        ud.set(w.weatherCode,        forKey: weatherCodeKey)
        ud.set(w.fetchedAt,          forKey: weatherDateKey)
    }

    private func saveFuel(_ f: FuelPrices) {
        let ud = UserDefaults.standard
        ud.set(f.petrolPerLitre, forKey: fuelPetrolKey)
        ud.set(f.dieselPerLitre, forKey: fuelDieselKey)
        ud.set(f.fetchedAt,     forKey: fuelDateKey)
    }

    private func loadFromCache() {
        let ud = UserDefaults.standard

        if let date = ud.object(forKey: weatherDateKey) as? Date,
           ud.double(forKey: weatherTempKey) != 0 {
            weather = KathmanduWeather(
                temperatureCelsius: ud.double(forKey: weatherTempKey),
                weatherCode:        ud.integer(forKey: weatherCodeKey),
                fetchedAt:          date
            )
        }

        if let date = ud.object(forKey: fuelDateKey) as? Date,
           ud.double(forKey: fuelPetrolKey) != 0 {
            fuel = FuelPrices(
                petrolPerLitre: ud.double(forKey: fuelPetrolKey),
                dieselPerLitre: ud.double(forKey: fuelDieselKey),
                fetchedAt:      date
            )
        }
    }
}
