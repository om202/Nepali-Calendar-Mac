//
//  NepaliTyperState.swift
//  Nepali-Calendar-App
//
//  Shared, in-memory composing state for NepaliTyperView. Kept as a
//  singleton so the menu-bar popover and the floating full editor stay
//  in sync — text typed in one surface appears in the other.
//

import Foundation

@Observable
final class NepaliTyperState {
    static let shared = NepaliTyperState()

    /// The Roman characters the user has typed so far.
    /// Mirrored into Devanagari on every read via NepaliTyperEngine.
    var romanBuffer: String = ""

    private init() {}
}
