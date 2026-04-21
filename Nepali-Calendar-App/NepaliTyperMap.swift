//
//  NepaliTyperMap.swift
//  Nepali-Calendar-App
//
//  Case-SENSITIVE Nepali Romanized → Devanagari mapping tables.
//  Retroflex consonants use capital letters (T→ट, D→ड, N→ण).
//  Ported from the nepalikeyboard IME project.
//

import Foundation

enum NepaliTyperMap {

    // MARK: - Dictionary Overrides
    // Super-fast lookup for common words that users type loosely without strict casing.
    static let wordDictionary: [String: String] = [
        "nepali": "नेपाली",
        "nepal": "नेपाल",
        "ram": "राम",
        "prabhat": "प्रभात",
        "vidya": "विद्या",
        "shanti": "शान्ति",
        "krishi": "कृषि",
        "buddha": "बुद्ध",
        "shree": "श्री",
        "gyan": "ज्ञान",
        "mero": "मेरो",
        "timro": "तिम्रो",
        "hamro": "हाम्रो",
        "tapai": "तपाईं",
        "tapaai": "तपाईं",
        "hajur": "हजुर",
        "namaste": "नमस्ते",
        "sathi": "साथी",
        "shukriya": "शुक्रिया",
        "kathmandu": "काठमाडौं",
        "pokhara": "पोखरा",
        "nepalma": "नेपालमा",
        "ho": "हो",
        "chha": "छ",
        "chhan": "छन्"
    ]

    // MARK: - Independent Vowels (word-initial or after another vowel)
    static let vowels: [String: String] = [
        "a":    "अ",
        "aa":   "आ",
        "A":    "आ",
        "i":    "इ",
        "I":    "ई",
        "ii":   "ई",
        "ee":   "ई",
        "u":    "उ",
        "U":    "ऊ",
        "uu":   "ऊ",
        "oo":   "ऊ",
        "e":    "ए",
        "ai":   "ऐ",
        "o":    "ओ",
        "au":   "औ",
        "R":    "ऋ",     // standalone ऋ
        "RR":   "ॠ",
    ]

    // MARK: - Dependent Vowel Signs / Maatraa (after a consonant)
    static let vowelSigns: [String: String] = [
        "a":    "ा",     // matches nepmedium: typing "na" → "ना"
        "aa":   "ा",
        "A":    "ा",
        "i":    "ि",
        "I":    "ी",
        "ii":   "ी",
        "ee":   "ी",
        "u":    "ु",
        "U":    "ू",
        "uu":   "ू",
        "oo":   "ू",
        "e":    "े",
        "ai":   "ै",
        "o":    "ो",
        "au":   "ौ",
        "R":    "ृ",     // vowel sign for ऋ
        "RR":   "ॄ",
    ]

    // MARK: - Consonants
    static let consonants: [String: String] = [

        // --- Velar ---
        "k":    "क",
        "kh":   "ख",
        "g":    "ग",
        "gh":   "घ",
        "ng":   "ङ",

        // --- Palatal ---
        "ch":   "च",
        "chh":  "छ",
        "cch":  "छ",
        "j":    "ज",
        "jh":   "झ",
        "ny":   "ञ",
        "Y":    "ञ",

        // --- Retroflex (Capital letters) ---
        "T":    "ट",
        "Th":   "ठ",
        "TH":   "ठ",
        "D":    "ड",
        "Dh":   "ढ",
        "DH":   "ढ",
        "N":    "ण",

        // --- Dental ---
        "t":    "त",
        "th":   "थ",
        "d":    "द",
        "dh":   "ध",
        "n":    "न",

        // --- Labial ---
        "p":    "प",
        "ph":   "फ",
        "f":    "फ",
        "b":    "ब",
        "bh":   "भ",
        "m":    "म",

        // --- Semi-vowels ---
        "y":    "य",
        "r":    "र",
        "l":    "ल",
        "w":    "व",
        "v":    "व",

        // --- Sibilants ---
        "sh":   "श",
        "S":    "ष",
        "Sh":   "ष",
        "ssh":  "ष",
        "s":    "स",

        // --- Glottal ---
        "h":    "ह",

        // --- Shortcuts & Extras ---
        "c":    "क",
        "q":    "क",
        "x":    "क्ष",
        "z":    "ज",
        "gy":   "ज्ञ",
        "gny":  "ज्ञ",
    ]

    // MARK: - Special Conjuncts
    static let conjuncts: [String: String] = [
        "ksh":  "क्ष",
        "ksn":  "क्ष",
        "gya":  "ज्ञ",
        "dny":  "ज्ञ",
        "shr":  "श्र",
        "tr":   "त्र",
    ]

    // MARK: - Halant (Virama)
    static let halant = "्"

    // MARK: - Special Marks
    static let anusvara     = "ं"
    static let chandrabindu = "ँ"
    static let visarga      = "ः"

    // MARK: - Devanagari Digits
    static let digits: [Character: String] = [
        "0": "०", "1": "१", "2": "२", "3": "३", "4": "४",
        "5": "५", "6": "६", "7": "७", "8": "८", "9": "९",
    ]

    // MARK: - Punctuation
    static let purnabiram   = "।"
    static let deerghaBiram = "॥"
}
