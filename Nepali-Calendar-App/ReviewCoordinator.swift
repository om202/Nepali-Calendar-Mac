//
//  ReviewCoordinator.swift
//  Nepali-Calendar-App
//
//  Decides *when* to ask for an App Store review. Strategy: inside a rolling
//  369-day cycle, push hard for a rating in the first 7 days — pre-prompt
//  fires on the 2nd popover open of the day and can reappear every day until
//  one of three stop conditions hits:
//    1. `requestReview()` has been invoked 3 times (matches Apple's 3/365
//       quota — no point asking beyond that).
//    2. The user tapped "Not really" (declined; we honor that for the cycle).
//    3. The 7-day active window has elapsed.
//  Pre-prompts by themselves do NOT count against the cap — only real
//  requestReview() calls do, so a string of "Ask me later" taps doesn't
//  burn our budget. Guideline 5.6.1 requires SKStoreReviewController as the
//  primary path; we route every "Yes" through it, and the happy-path
//  pre-prompt routes unhappy users to feedback email instead of the store.
//

import Foundation
import SwiftUI
import AppKit
import Aptabase

@Observable
final class ReviewCoordinator {
    static let shared = ReviewCoordinator()

    // MARK: - Tuning

    /// Days after cycle start during which the pre-prompt can fire.
    private let activeWindowDays = 7
    /// Cap on real `requestReview()` invocations per cycle — matches Apple's
    /// 3/365 quota. Pre-prompts alone don't count toward this.
    private let apiCallMax       = 3
    /// Trigger threshold — Nth popover open within a single day.
    private let minOpensSameDay  = 2
    /// Full cycle length. When this elapses, counters reset and a new
    /// 7-day active window opens.
    private let cycleLengthDays  = 369
    /// Bump this if the algorithm changes in a way that warrants resetting
    /// the cycle for existing users (so they re-enter the active window).
    private let algoVersion      = "v2"

    // MARK: - Persistence keys

    private enum K {
        /// Anchor for the current cycle. Reset to `now` each time a cycle rolls.
        static let cycleStartDate = "review.cycleStartDate"
        static let openDayKey     = "review.openDayKey"     // "yyyy-MM-dd"
        static let openCountToday = "review.openCountToday" // Int
        /// How many times we've actually called requestReview() this cycle.
        /// Pre-prompts don't tick this — only "Yes" and Settings-tap do.
        static let apiCallCount   = "review.apiCallCount"   // Int, 0...apiCallMax
        static let lastShowDate   = "review.lastShowDate"   // Date (per cycle)
        /// User tapped "Not really" on the pre-prompt — silence prompts for
        /// the rest of this cycle, but don't burn API budget.
        static let userDeclined   = "review.userDeclined"   // Bool (per cycle)
        /// Which algorithm version last wrote this state — used to force a
        /// cycle reset when upgrading users to a new strategy.
        static let algoVersion    = "review.algoVersion"
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
        migrateIfNeeded()
        if defaults.object(forKey: K.cycleStartDate) == nil {
            defaults.set(Date(), forKey: K.cycleStartDate)
        }
    }

    /// Reset the cycle for users upgrading from an older algorithm version
    /// so they re-enter the active window. Without this, anyone whose
    /// `cycleStartDate` is already older than the new active window would
    /// silently get zero prompts until the 369-day cycle rolls.
    private func migrateIfNeeded() {
        let current = defaults.string(forKey: K.algoVersion)
        guard current != algoVersion else { return }
        defaults.set(Date(), forKey: K.cycleStartDate)
        defaults.set(0, forKey: K.apiCallCount)
        defaults.removeObject(forKey: K.lastShowDate)
        defaults.removeObject(forKey: K.userDeclined)
        defaults.set(algoVersion, forKey: K.algoVersion)
    }

    // MARK: - Session signals

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
            "opens":        String(count),
            "apiCallCount": String(defaults.integer(forKey: K.apiCallCount)),
            "cycleAgeDays": String(cycleAgeDays)
        ])
        pendingPrompt = true
    }

    // MARK: - Guard evaluation

    func shouldPrompt() -> Bool {
        rollCycleIfNeeded()
        if cycleAgeDays >= activeWindowDays { return false }
        if defaults.integer(forKey: K.apiCallCount) >= apiCallMax { return false }
        if defaults.bool(forKey: K.userDeclined) { return false }
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
        defaults.set(0, forKey: K.apiCallCount)
        defaults.removeObject(forKey: K.lastShowDate)
        defaults.removeObject(forKey: K.userDeclined)
        Aptabase.shared.trackEvent("review_cycle_reset")
    }

    // MARK: - Pre-prompt responses

    /// User said they're enjoying the app → open the standalone review
    /// window (which calls requestReview internally). Ticks the API-call
    /// cap and marks engagement; remaining calls still fire on future days
    /// in case Apple's system suppressed the sheet.
    ///
    /// The window open is deferred one runloop tick so the menu-bar popover
    /// (a transient panel) can finish dismissing before we change activation
    /// policy and bring up a new window — doing both synchronously races and
    /// the new window ends up not appearing.
    func userSaidYes() {
        pendingPrompt = false
        recordAPICall()
        markEngaged()
        Aptabase.shared.trackEvent("review_preprompt_yes")
        DispatchQueue.main.async {
            ReviewRequestWindow.show()
        }
    }

    /// Explicit "no" → set the declined flag so we stop pre-prompting this
    /// cycle, and open a feedback email. Does NOT tick the API cap — the
    /// user never reached requestReview(), and if they change their mind
    /// later via the Settings row we still have budget.
    func userSaidNotReally() {
        pendingPrompt = false
        markPromptShown()
        markDeclined()
        markEngaged()
        Aptabase.shared.trackEvent("review_preprompt_no")

        let subject = "Nepali Calendar Feedback"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Feedback"
        if let url = URL(string: "mailto:info@noblestack.io?subject=\(subject)") {
            NSWorkspace.shared.open(url)
        }
    }

    /// "Ask me later" or tapping outside → only updates lastShowDate so the
    /// 1/day throttle kicks in. Does NOT tick the API cap or mark engagement,
    /// so we can re-prompt tomorrow (up to the 7-day window).
    func userSaidLater() {
        pendingPrompt = false
        markPromptShown()
        Aptabase.shared.trackEvent("review_preprompt_later")
    }

    // MARK: - Settings direct path

    /// Invoked from the Settings row — user deliberately navigated here, so
    /// skip the pre-prompt and go straight to the review window. Ticks the
    /// API cap. Deferred for the same popover-dismissal reason as `userSaidYes`.
    func tapFromSettings() {
        recordAPICall()
        markEngaged()
        Aptabase.shared.trackEvent("rate_tapped", with: ["source": "settings"])
        DispatchQueue.main.async {
            ReviewRequestWindow.show()
        }
    }

    // MARK: - Helpers

    /// Mark that we presented the pre-prompt today (so we don't re-show it
    /// within the same Kathmandu day). No budget consumed.
    private func markPromptShown() {
        defaults.set(Date(), forKey: K.lastShowDate)
    }

    /// Record that we actually invoked `requestReview()` — this is the
    /// counter that caps out at 3 per cycle (mirrors Apple's 3/365 quota).
    private func recordAPICall() {
        let n = defaults.integer(forKey: K.apiCallCount) + 1
        defaults.set(n, forKey: K.apiCallCount)
        defaults.set(Date(), forKey: K.lastShowDate)
    }

    private func markDeclined() {
        defaults.set(true, forKey: K.userDeclined)
    }

    private func markEngaged() {
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
