//
//  NewsFeedService.swift
//  Nepali-Calendar-App
//
//  Fetches Nepal news from multiple free RSS feeds, filters to today (Nepal time),
//  sorted by latest. Refreshes on-demand when user opens News tab (5-min cooldown).
//  No external dependencies — uses Foundation's XMLParser.
//

import Foundation
import Observation

// MARK: - Model

struct NewsItem: Identifiable, Codable {
    let id: String
    let title: String
    let link: String
    let source: String
    let pubDate: Date?
}

// MARK: - Service

@Observable
final class NewsFeedService {

    // Published state
    private(set) var articles: [NewsItem] = []
    private(set) var isLoading = false
    private(set) var lastUpdated: Date? = nil
    private(set) var fetchError: String? = nil

    // Cooldown: skip fetch if data is fresher than this
    private let cooldown: TimeInterval = 5 * 60  // 5 minutes

    // Feeds: all free public RSS, no auth
    private let feeds: [(url: String, source: String)] = [
        ("https://kathmandupost.com/rss", "Kathmandu Post"),
        ("https://thehimalayantimes.com/feed/", "Himalayan Times"),
        ("https://www.onlinekhabar.com/feed", "Online Khabar"),
        ("https://setopati.com/rss", "Setopati"),
        ("https://english.ratopati.com/rss", "Ratopati"),
    ]

    // UserDefaults cache key
    private let cacheKey = "cachedNewsArticles"
    private let cacheAgeKey = "cachedNewsAge"

    init() {
        loadCache()
    }

    // MARK: - On-demand refresh (called when News tab appears)

    /// Fetches only if data is stale (older than 5 min) or empty.
    func refreshIfNeeded() {
        if let last = lastUpdated, Date().timeIntervalSince(last) < cooldown, !articles.isEmpty {
            return  // Data is fresh, skip
        }
        fetch()
    }

    // MARK: - Fetch

    func fetch() {
        guard !isLoading else { return }
        isLoading = true
        fetchError = nil

        Task {
            var allItems: [NewsItem] = []

            await withTaskGroup(of: [NewsItem].self) { group in
                for feed in self.feeds {
                    group.addTask {
                        await self.fetchFeed(url: feed.url, source: feed.source)
                    }
                }
                for await items in group {
                    allItems.append(contentsOf: items)
                }
            }

            // Filter to today (Nepal time), fall back to all if empty
            let todaysItems = self.filterToToday(allItems)
            let result = todaysItems.isEmpty ? allItems : todaysItems

            // Sort by latest first
            let sorted = result.sorted { ($0.pubDate ?? .distantPast) > ($1.pubDate ?? .distantPast) }

            await MainActor.run {
                self.articles = sorted
                self.isLoading = false
                self.lastUpdated = Date()
                self.saveCache(sorted)
                if sorted.isEmpty {
                    self.fetchError = "No news available right now."
                }
            }
        }
    }

    // MARK: - Filter to Nepal "today"

    private func filterToToday(_ items: [NewsItem]) -> [NewsItem] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = nepalTimeZone
        let today = cal.startOfDay(for: Date())
        return items.filter { item in
            guard let pub = item.pubDate else { return false }
            return pub >= today
        }
    }

    // MARK: - Per-feed fetch + parse

    private func fetchFeed(url: String, source: String) async -> [NewsItem] {
        guard let feedURL = URL(string: url) else { return [] }
        var request = URLRequest(url: feedURL)
        request.timeoutInterval = 10
        request.setValue("NepaliCalendarPro/1.0 (+mailto:support@noblestack.io)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return RSSParser.parse(data: data, source: source)
        } catch {
            return []
        }
    }

    // MARK: - Cache

    private func saveCache(_ items: [NewsItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheAgeKey)
        }
    }

    private func loadCache() {
        guard
            let data = UserDefaults.standard.data(forKey: cacheKey),
            let items = try? JSONDecoder().decode([NewsItem].self, from: data)
        else { return }
        // Only use cache if < 2 hours old
        if let cacheDate = UserDefaults.standard.object(forKey: cacheAgeKey) as? Date,
           Date().timeIntervalSince(cacheDate) < 7200 {
            articles = items
            lastUpdated = cacheDate
        }
    }

    // MARK: - Minutes ago helper

    var minutesAgoString: String {
        guard let last = lastUpdated else { return "Never" }
        let mins = Int(Date().timeIntervalSince(last) / 60)
        if mins < 1 { return "Just now" }
        if mins == 1 { return "1 min ago" }
        return "\(mins) mins ago"
    }
}

// MARK: - RSS XML Parser

private final class RSSParser: NSObject, XMLParserDelegate {

    private(set) var items: [NewsItem] = []
    private let source: String

    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var insideItem = false
    private var currentElement = ""
    private var charBuffer = ""

    private static let rfcFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()

    private static let rfcFormatterAlt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return f
    }()

    init(source: String) {
        self.source = source
    }

    static func parse(data: Data, source: String) -> [NewsItem] {
        let parser = RSSParser(source: source)
        let xml = XMLParser(data: data)
        xml.delegate = parser
        xml.parse()
        return parser.items
    }

    // MARK: XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" || elementName == "entry" {
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
        }
        charBuffer = ""
        // Atom <link rel="alternate" href="..."/>
        if elementName == "link", insideItem,
           let href = attributeDict["href"], !href.isEmpty {
            currentLink = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        charBuffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let text = charBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        if insideItem {
            switch elementName {
            case "title":
                currentTitle = text
            case "link":
                if currentLink.isEmpty { currentLink = text }
            case "pubDate", "published", "updated":
                if currentPubDate.isEmpty { currentPubDate = text }
            case "item", "entry":
                let cleanTitle = currentTitle
                    .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cleanTitle.isEmpty, !currentLink.isEmpty else { break }
                let pubDate = Self.rfcFormatter.date(from: currentPubDate)
                    ?? Self.rfcFormatterAlt.date(from: currentPubDate)
                let item = NewsItem(
                    id: currentLink,
                    title: cleanTitle,
                    link: currentLink,
                    source: source,
                    pubDate: pubDate
                )
                items.append(item)
                insideItem = false
            default:
                break
            }
        }
        charBuffer = ""
    }
}
