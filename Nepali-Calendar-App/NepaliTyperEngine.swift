//
//  NepaliTyperEngine.swift
//  Nepali-Calendar-App
//
//  Offline Romanized → Devanagari transliteration engine.
//  Uses a greedy longest-match algorithm with proper consonant
//  cluster handling, vowel sign selection, and edge cases.
//  Ported from the nepalikeyboard IME project.
//

import Foundation

final class NepaliTyperEngine {

    static let shared = NepaliTyperEngine()

    /// Transliterate a full text buffer word-by-word, preserving whitespace
    /// so spaces and newlines survive intact.
    func transliterateText(_ input: String) -> String {
        if input.isEmpty { return "" }
        var result = ""
        var token = ""
        for ch in input {
            if ch.isWhitespace {
                if !token.isEmpty {
                    result += transliterate(token)
                    token = ""
                }
                result.append(ch)
            } else {
                token.append(ch)
            }
        }
        if !token.isEmpty { result += transliterate(token) }
        return result
    }

    // Pre-sorted token lists (longest first) for greedy matching
    private let sortedConjuncts: [(key: String, value: String)]
    private let sortedConsonants: [(key: String, value: String)]
    private let sortedVowels: [(key: String, value: String)]

    private init() {
        // Sort all maps by key length descending for greedy matching
        sortedConjuncts = NepaliTyperMap.conjuncts.sorted { $0.key.count > $1.key.count }
        sortedConsonants = NepaliTyperMap.consonants.sorted { $0.key.count > $1.key.count }
        sortedVowels = NepaliTyperMap.vowels.sorted { $0.key.count > $1.key.count }
    }

    /// Converts a Roman string to Devanagari using greedy longest-match.
    ///
    /// Algorithm:
    /// 1. Scan left-to-right, try longest token first at each position
    /// 2. Track whether previous token was a consonant
    /// 3. If consonant follows consonant → insert halant (consonant cluster)
    /// 4. If vowel follows consonant → use maatraa (dependent vowel sign)
    /// 5. If vowel is standalone → use independent vowel form
    func transliterate(_ input: String) -> String {
        if input.isEmpty { return "" }

        // 1. Exact dictionary override
        // Lowercase the input strictly for dictionary matching (e.g. "Ram" -> "ram" -> "राम")
        if let override = NepaliTyperMap.wordDictionary[input.lowercased()] {
            return override
        }

        // 2. Strict Phonetic Fallback
        // Use exact input for case-sensitive rules (e.g. t vs T)
        let text = input

        var result = ""
        var index = text.startIndex
        var lastWasConsonant = false

        while index < text.endIndex {
            let remaining = String(text[index...])

            // Try to match a token
            if let match = findLongestMatch(remaining) {

                if match.isConsonant {
                    // Consonant (or conjunct): if previous was also consonant, add halant
                    if lastWasConsonant {
                        result += NepaliTyperMap.halant
                    }
                    result += match.devanagari
                    lastWasConsonant = true

                } else {
                    // Vowel: use maatraa if after consonant, independent form otherwise
                    if lastWasConsonant {
                        if let sign = NepaliTyperMap.vowelSigns[match.roman] {
                            result += sign
                        } else {
                            result += match.devanagari
                        }
                    } else {
                        result += match.devanagari
                    }
                    lastWasConsonant = false
                }

                index = text.index(index, offsetBy: match.roman.count)

            } else {
                // No token match — handle special characters
                let char = text[index]

                if char == "~" {
                    let nextIndex = text.index(after: index)
                    if nextIndex < text.endIndex && text[nextIndex] == "~" {
                        result += NepaliTyperMap.chandrabindu
                        index = text.index(after: nextIndex)
                    } else {
                        result += NepaliTyperMap.anusvara
                        index = nextIndex
                    }
                    lastWasConsonant = false

                } else if char == ":" {
                    result += NepaliTyperMap.visarga
                    index = text.index(after: index)
                    lastWasConsonant = false

                } else if char == "/" {
                    // Purnabiram without automatically adding halant
                    result += NepaliTyperMap.purnabiram
                    lastWasConsonant = false
                    index = text.index(after: index)

                } else if char == "\\" || char == "_" {
                    // Explicit halant
                    if lastWasConsonant {
                        result += NepaliTyperMap.halant
                    }
                    lastWasConsonant = false
                    index = text.index(after: index)

                } else if char == "." {
                    result += "."
                    lastWasConsonant = false
                    index = text.index(after: index)

                } else {
                    // Space or other unmapped character
                    // DO NOT automatically add halant in natural typing! 
                    lastWasConsonant = false
                    result += String(char)
                    index = text.index(after: index)
                }
            }
        }

        return result
    }

    // MARK: - Private

    private struct MatchResult {
        let roman: String
        let devanagari: String
        let isConsonant: Bool
    }

    /// Finds the longest matching token at the start of `text`.
    /// Priority: conjuncts → consonants → vowels (all sorted longest-first).
    private func findLongestMatch(_ text: String) -> MatchResult? {

        // 1. Conjuncts (longest first)
        for (roman, devanagari) in sortedConjuncts {
            if text.hasPrefix(roman) {
                return MatchResult(roman: roman, devanagari: devanagari, isConsonant: true)
            }
        }

        // 2. Consonants (longest first)
        for (roman, devanagari) in sortedConsonants {
            if text.hasPrefix(roman) {
                return MatchResult(roman: roman, devanagari: devanagari, isConsonant: true)
            }
        }

        // 3. Vowels (longest first)
        for (roman, devanagari) in sortedVowels {
            if text.hasPrefix(roman) {
                return MatchResult(roman: roman, devanagari: devanagari, isConsonant: false)
            }
        }

        return nil
    }
}
