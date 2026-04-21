//
//  ReviewCoordinator.swift
//  Nepali-Calendar-App
//
//  Decides *when* to ask for an App Store review. Strategy: inside a rolling
//  369-day cycle, try to spend all three Apple-allowed prompts in the first
//  4 days of the cycle, at most one per day, triggered when the user opens
//  the menu-bar popover for the third time that day. Once the cycle ends
//  (369 days after it started) the counters reset automatically and we get
//  another shot next year — this lines up with Apple's own 3/365 window.
//  A happy-path pre-prompt ("Enjoying X?") routes unhappy users to email
//  instead of the store — allowed by review guideline 5.6.1 as long as
//  nothing is gated.
//

import Foundation
import SwiftUI
import AppKit
import Aptabase

@Observable
final class ReviewCoordinator {
    static let shared = ReviewCoordinator()

    // MARK: - Tuning

    /// Days after cycle start during which the prompt can fire.
    private let activeWindowDays = 4
    /// Total prompts allowed inside a single cycle (matches Apple's 3/365).
    private let maxShows         = 3
    /// Trigger threshold — Nth popover open within a single day.
    private let minOpensSameDay  = 3
    /// Full cycle length. When this elapses, counters reset and a new
    /// 4-day active window opens.
    private let cycleLengthDays  = 369

    // MARK: - Persistence keys

    private enum K {
        /// Anchor for the current cycle. Reset to `now` each time a cycle rolls.
        static let cycleStartDate = "review.cycleStartDate"
        static let openDayKey     = "review.openDayKey"     // "yyyy-MM-dd"
        static let openCountToday = "review.openCountToday" // Int
        static let shownCount     = "review.shownCount"     // Int, 0...maxShows (per cycle)
        static let lastShowDate   = "review.lastShowDate"   // Date (per cycle)
        static let winCount       = "review.winCount"       // lifetime metric
        /// Preserved from the pre-coordinator era — hides the Settings row
        /// once the user has engaged with rating (not reset between cycles
        /// because there's no point showing it to someone who already acted).
        static let tappedRateFlag = "hasRatedApp"
    }

    // MARK: - Observable UI state

    /// When true, the popover should overlay the happy-path sheet.
    var pendingPrompt: Bool = false

    // MARK: - Private

    private let defaults = UserDefaults.standard

    private init() {
        if defaults.object(forKey: K.cycleStartDate) == nil {
            defaults.set(Date(), forKey: K.cycleStartDate)
        }
    }

    // MARK: - Session signals

    /// Kept as a metric hook; no longer participates in trigger logic.
    func recordLaunch() {}

    /// Lifetime counter for positive actions — metric only.
    func recordWin(_ label: String) {
        let n = defaults.integer(forKey: K.winCount) + 1
        defaults.set(n, forKey: K.winCount)
    }

    /// Called from `MenuBarPopoverView.onAppear`. Rolls the cycle if due,
    /// tracks opens-per-day, and on the Nth same-day open triggers the
    /// pre-prompt if all guards pass.
    func recordPopoverOpen() {
        rollCycleIfNeeded()

        let today = Self.dayKey(Date())
        let storedDay = defaults.string(forKey: K.openDayKey)
        var count = (storedDay == today) ? defaults.integer(forKey: K.openCountToday) : 0
        count += 1
        defaults.set(today, forKey: K.openDayKey)
        defaults.set(count, forKey: K.openCountToday)

        guard count >= minOpensSameDay, shouldPrompt() else { return }
        Aptabase.shared.trackEvent("review_preprompt_triggered", with: [
            "opens":          String(count),
            "shownCount":     String(defaults.integer(forKey: K.shownCount)),
            "cycleAgeDays":   String(cycleAgeDays)
        ])
        pendingPrompt = true
    }

    // MARK: - Guard evaluation

    func shouldPrompt() -> Bool {
        rollCycleIfNeeded()
        if cycleAgeDays > activeWindowDays { return false }
        if defaults.integer(forKey: K.shownCount) >= maxShows { return false }
        if shownToday { return false }
        return true
    }

    private var cycleAgeDays: Int {
        let start = defaults.object(forKey: K.cycleStartDate) as? Date ?? Date()
        return Int(Date().timeIntervalSince(start) / 86_400)
    }

    private var shownToday: Bool {
        guard let last = defaults.object(forKey: K.lastShowDate) as? Date else { return false }
        return Self.dayKey(last) == Self.dayKey(Date())
    }

    /// If the current cycle has aged past `cycleLengthDays`, start a new one.
    /// Clears per-cycle counters so the user becomes eligible again.
    private func rollCycleIfNeeded() {
        let start = defaults.object(forKey: K.cycleStartDate) as? Date ?? Date()
        guard Date().timeIntervalSince(start) >= TimeInterval(cycleLengthDays * 86_400) else { return }
        defaults.set(Date(), forKey: K.cycleStartDate)
        defaults.set(0, forKey: K.shownCount)
        defaults.removeObject(forKey: K.lastShowDate)
        Aptabase.shared.trackEvent("review_cycle_reset")
    }

    // MARK: - Pre-prompt responses

    /// User said they're enjoying the app → hand off to Apple's sheet.
    /// Counts as one show; remaining shows still fire on future days in
    /// case Apple's system suppressed the sheet.
    func userSaidYes(requestReview: @escaping () -> Void) {
        pendingPrompt = false
        markShown()
        Aptabase.shared.trackEvent("review_preprompt_yes")
        requestReview()
    }

    /// Explicit "no" → consume all remaining shows in the cycle and open a
    /// feedback email. The user will not be asked again until the next cycle.
    func userSaidNotReally() {
        pendingPrompt = false
        consumeRemainingShows()
        Aptabase.shared.trackEvent("review_preprompt_no")

        let subject = "Nepali Calendar Feedback"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Feedback"
        if let url = URL(string: "mailto:info@noblestack.io?subject=\(subject)") {
            NSWorkspace.shared.open(url)
        }
    }

    /// "Ask me later" or tapping outside → counts as one show, try again
    /// tomorrow (if still within the 4-day window and under the show cap).
    func userSaidLater() {
        pendingPrompt = false
        markShown()
        Aptabase.shared.trackEvent("review_preprompt_later")
    }

    // MARK: - Settings direct path

    /// Invoked from the Settings row — user deliberately navigated here, so
    /// skip the pre-prompt and consume the remaining shows for this cycle.
    func tapFromSettings(requestReview: @escaping () -> Void) {
        consumeRemainingShows()
        Aptabase.shared.trackEvent("rate_tapped", with: ["source": "settings"])
        requestReview()
    }

    var userHasEngagedWithRating: Bool {
        defaults.bool(forKey: K.tappedRateFlag)
    }

    // MARK: - Helpers

    private func markShown() {
        let n = defaults.integer(forKey: K.shownCount) + 1
        defaults.set(n, forKey: K.shownCount)
        defaults.set(Date(), forKey: K.lastShowDate)
        defaults.set(true, forKey: K.tappedRateFlag)
    }

    private func consumeRemainingShows() {
        defaults.set(maxShows, forKey: K.shownCount)
        defaults.set(Date(), forKey: K.lastShowDate)
        defaults.set(true, forKey: K.tappedRateFlag)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Asia/Kathmandu")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func dayKey(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }
}
