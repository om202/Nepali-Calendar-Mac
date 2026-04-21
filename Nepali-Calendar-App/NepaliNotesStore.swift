//
//  NepaliNotesStore.swift
//  Nepali-Calendar-App
//
//  Persistent storage for Devanagari notes typed via NepaliTyperView.
//  Backed by UserDefaults; newest-first ordering.
//

import Foundation

struct NepaliNote: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
}

@Observable
final class NepaliNotesStore {
    static let shared = NepaliNotesStore()

    private let storageKey = "nepaliTyper.notes.v1"
    private(set) var notes: [NepaliNote] = []

    private init() { load() }

    /// Insert a new note at the top. No-op for empty/whitespace-only text.
    @discardableResult
    func add(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        notes.insert(NepaliNote(id: UUID(), text: trimmed, createdAt: Date()), at: 0)
        save()
        return true
    }

    func delete(_ id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        notes.removeAll()
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([NepaliNote].self, from: data) {
            notes = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
