//
//  NetworkMonitor.swift
//  Nepali-Calendar-App
//
//  Monitors network connectivity using NWPathMonitor.
//  When internet is restored and any service's data is stale,
//  clears the error-date backoff and re-triggers a fetch.
//

import Foundation
import Network

final class NetworkMonitor {

    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
    private var wasConnected = true   // assume connected until proven otherwise

    private init() {}

    /// Begin monitoring. Call once at app launch.
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            guard let self else { return }

            // We only care about the transition: disconnected → connected
            if isConnected && !self.wasConnected {
                // Small delay to let the network stabilise
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.retryStaleServices()
                }
            }
            self.wasConnected = isConnected
        }
        monitor.start(queue: queue)
    }

    /// Re-fetch any service whose data is stale.
    @MainActor
    private func retryStaleServices() {
        let metal    = MetalPriceService.shared
        let currency = CurrencyService.shared
        let fuelWx   = FuelWeatherService.shared

        if metal.isStale || metal.prices == nil {
            metal.clearErrorBackoff()
            metal.refreshIfNeeded()
        }

        if currency.isStale || currency.rates == nil {
            currency.clearErrorBackoff()
            currency.refreshIfNeeded()
        }

        // Fuel has an error backoff; weather does not
        if fuelWx.isFuelStale || fuelWx.fuel == nil {
            fuelWx.clearFuelErrorBackoff()
            fuelWx.refreshFuelIfNeeded()
        }

        if fuelWx.weather == nil {
            fuelWx.refreshWeatherIfNeeded()
        }
    }
}
