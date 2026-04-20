// ChordTokenizer.swift
// ChordTransposerEngine

import Foundation

/// Protocol for tokenizing a string into chord and text tokens.
public protocol ChordParsing: Sendable {
    func tokenize(_ input: String) -> [ParsedToken]
}

/// Default chord tokenizer using a multi-stage pipeline.
public struct ChordTokenizer: ChordParsing, Sendable {
    private let configuration: ParserConfiguration

    public init(configuration: ParserConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Public API

    public func tokenize(_ input: String) -> [ParsedToken] {
        // Check for bracketed notation first: [Am]lyrics[G]more
        if configuration.recognizeBracketedChords && input.contains("[") {
            return tokenizeBracketed(input)
        }

        return tokenizeWhitespaceSeparated(input)
    }

    /// Parse a single chord string. Returns nil if not valid.
    public func parseChord(_ string: String) -> Chord? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return parseChordSymbol(trimmed)
    }

    // MARK: - Bracketed Notation

    private func tokenizeBracketed(_ input: String) -> [ParsedToken] {
        var tokens: [ParsedToken] = []
        var current = input.startIndex
        var column = 0

        while current < input.endIndex {
            if input[current] == "[" {
                // Find closing bracket
                if let closeBracket = input[input.index(after: current)...].firstIndex(of: "]") {
                    let chordStr = String(input[input.index(after: current)..<closeBracket])
                    if let chord = parseChordSymbol(chordStr) {
                        tokens.append(.chord(chord, column: column))
                    } else {
                        // Not a chord — keep as text including brackets
                        tokens.append(.text("[" + chordStr + "]"))
                    }
                    current = input.index(after: closeBracket)
                    column += chordStr.count + 2
                } else {
                    // No closing bracket — treat rest as text
                    tokens.append(.text(String(input[current...])))
                    break
                }
            } else {
                // Collect text until next bracket or end
                var textEnd = input.index(after: current)
                while textEnd < input.endIndex && input[textEnd] != "[" {
                    textEnd = input.index(after: textEnd)
                }
                let text = String(input[current..<textEnd])
                tokens.append(.text(text))
                column += text.count
                current = textEnd
            }
        }

        return tokens
    }

    // MARK: - Whitespace-Separated Tokenization

    private func tokenizeWhitespaceSeparated(_ input: String) -> [ParsedToken] {
        guard !input.isEmpty else { return [] }

        // Split into segments preserving whitespace position
        let segments = splitPreservingWhitespace(input)

        // First pass: attempt to parse each non-whitespace segment as a chord
        struct Candidate {
            let text: String
            let column: Int
            let isWhitespace: Bool
            var chord: Chord?
        }

        var candidates: [Candidate] = []
        for seg in segments {
            if seg.isWhitespace {
                candidates.append(Candidate(text: seg.text, column: seg.column, isWhitespace: true, chord: nil))
            } else {
                let chord = parseChordSymbol(seg.text)
                candidates.append(Candidate(text: seg.text, column: seg.column, isWhitespace: false, chord: chord))
            }
        }

        // Second pass: contextual disambiguation
        let nonWS = candidates.filter { !$0.isWhitespace }
        let chordCount = nonWS.filter { $0.chord != nil }.count
        let totalNonWS = nonWS.count

        let chordRatio = totalNonWS > 0 ? Double(chordCount) / Double(totalNonWS) : 0

        // Build final tokens
        var tokens: [ParsedToken] = []

        for candidate in candidates {
            if candidate.isWhitespace {
                tokens.append(.text(candidate.text))
            } else if let chord = candidate.chord {
                // Disambiguate single-letter chords
                if chord.originalText.count == 1 && Note.isNoteLetter(chord.originalText.first!) {
                    if configuration.allowSingleLetterChords && chordRatio >= 0.5 {
                        tokens.append(.chord(chord, column: candidate.column))
                    } else {
                        tokens.append(.text(candidate.text))
                    }
                } else {
                    tokens.append(.chord(chord, column: candidate.column))
                }
            } else {
                tokens.append(.text(candidate.text))
            }
        }

        return tokens
    }

    // MARK: - Segment Splitting

    private struct Segment {
        let text: String
        let column: Int
        let isWhitespace: Bool
    }

    private func splitPreservingWhitespace(_ input: String) -> [Segment] {
        var segments: [Segment] = []
        var current = input.startIndex
        var column = 0

        while current < input.endIndex {
            let ch = input[current]
            if ch.isWhitespace {
                var end = input.index(after: current)
                while end < input.endIndex && input[end].isWhitespace {
                    end = input.index(after: end)
                }
                let text = String(input[current..<end])
                segments.append(Segment(text: text, column: column, isWhitespace: true))
                column += text.count
                current = end
            } else {
                var end = input.index(after: current)
                while end < input.endIndex && !input[end].isWhitespace {
                    end = input.index(after: end)
                }
                let text = String(input[current..<end])
                segments.append(Segment(text: text, column: column, isWhitespace: false))
                column += text.count
                current = end
            }
        }

        return segments
    }

    // MARK: - Core Chord Parser

    /// Attempt to parse a string as a chord symbol.
    /// Returns nil if the string doesn't match chord grammar.
    internal func parseChordSymbol(_ input: String) -> Chord? {
        let chars = Array(input)
        guard !chars.isEmpty else { return nil }

        // Stage 1: Parse root note
        guard let first = chars.first, Note.isNoteLetter(first) else { return nil }

        var idx = 1
        var rootString = String(first)

        // Consume accidentals for root
        while idx < chars.count {
            let ch = chars[idx]
            if ch == "#" || ch == "♯" {
                rootString.append(ch)
                idx += 1
            } else if ch == "b" || ch == "♭" {
                rootString.append(ch)
                idx += 1
            } else {
                break
            }
        }

        guard let rootNote = Note(string: rootString) else { return nil }
        let rootSpelling = NoteSpelling(note: rootNote, originalText: rootString)

        // If we consumed the entire string, it's a bare root chord (e.g., "C", "Bb")
        if idx == chars.count {
            return Chord(
                root: rootSpelling,
                quality: .major,
                extensions: [],
                bass: nil,
                originalText: input,
                suffixText: ""
            )
        }

        // Stage 2: Parse quality and extensions
        let remaining = String(chars[idx...])
        guard let (quality, extensions, suffixText, bass) = parseQualityAndExtensions(remaining) else {
            return nil
        }

        let bassSpelling: NoteSpelling?
        if let bass = bass {
            guard let bassNote = Note(string: bass) else { return nil }
            bassSpelling = NoteSpelling(note: bassNote, originalText: bass)
        } else {
            bassSpelling = nil
        }

        return Chord(
            root: rootSpelling,
            quality: quality,
            extensions: extensions,
            bass: bassSpelling,
            originalText: input,
            suffixText: suffixText
        )
    }

    // MARK: - Quality & Extension Parser

    /// Parse the portion after the root note.
    /// Returns (quality, extensions, suffixText, bassNoteString?).
    private func parseQualityAndExtensions(
        _ input: String
    ) -> (ChordQuality, [ChordExtension], String, String?)? {
        var remaining = input
        var quality: ChordQuality = .major
        var extensions: [ChordExtension] = []

        // Split on slash for bass note (take the LAST slash to handle edge cases)
        var bassString: String? = nil
        var suffixPart = input

        if let slashIdx = remaining.lastIndex(of: "/") {
            let afterSlash = String(remaining[remaining.index(after: slashIdx)...])
            // Verify the part after slash is a valid note
            if Note(string: afterSlash) != nil {
                bassString = afterSlash
                remaining = String(remaining[..<slashIdx])
                suffixPart = String(remaining)
            }
        }

        // Parse quality
        let (parsedQuality, qualityConsumed) = parseQuality(remaining)
        quality = parsedQuality

        if qualityConsumed > 0 {
            remaining = String(remaining.dropFirst(qualityConsumed))
        }

        // Parse extensions
        let (parsedExtensions, extensionsValid) = parseExtensions(remaining, quality: &quality)
        guard extensionsValid else { return nil }
        extensions = parsedExtensions

        return (quality, extensions, suffixPart, bassString)
    }

    /// Parse quality prefix from string, return quality and characters consumed.
    private func parseQuality(_ input: String) -> (ChordQuality, Int) {
        // Order matters — check longer patterns first
        let qualityPatterns: [(String, ChordQuality, Int)] = [
            ("minor", .minor, 5),
            ("min", .minor, 3),
            ("mi", .minor, 2),
            ("maj", .major, 3),  // explicit major (for maj7 etc.)
            ("Maj", .major, 3),
            ("major", .major, 5),
            ("dim", .diminished, 3),
            ("aug", .augmented, 3),
            ("sus4", .suspendedFourth, 4),
            ("sus2", .suspendedSecond, 4),
            ("sus", .suspendedFourth, 3), // bare "sus" defaults to sus4
            ("m", .minor, 1),
            ("M", .major, 1),     // explicit major
            ("°", .diminished, 1),
            ("o", .diminished, 1),
            ("ø", .halfDiminished, 1),
            ("+", .augmented, 1),
        ]

        for (pattern, quality, consumed) in qualityPatterns {
            if input.hasPrefix(pattern) {
                // For single 'm': make sure next char isn't 'a' (maj) or 'i' (min)
                if pattern == "m" && input.count > 1 {
                    let nextChar = input[input.index(after: input.startIndex)]
                    if nextChar == "a" || nextChar == "i" {
                        continue // skip — will be caught by "maj", "min", "mi"
                    }
                }
                // Don't consume "maj"/"Maj" when followed by a digit (e.g., "maj7").
                // "maj7" is a single extension token meaning major seventh, not
                // a quality prefix "maj" + extension "7".
                if (pattern == "maj" || pattern == "Maj") && input.count > consumed {
                    let afterPattern = input[input.index(input.startIndex, offsetBy: consumed)]
                    if afterPattern.isNumber {
                        return (.major, 0)
                    }
                }
                // Don't consume "M" as quality when followed by a digit (e.g., "M7").
                // "M7" is a single extension meaning major seventh.
                if pattern == "M" && input.count > consumed {
                    let afterPattern = input[input.index(input.startIndex, offsetBy: consumed)]
                    if afterPattern.isNumber {
                        return (.major, 0)
                    }
                }
                return (quality, consumed)
            }
        }

        return (.major, 0)
    }

    /// Parse extension tokens from the remaining string after quality.
    /// Modifies quality if needed (e.g., "7" on a major chord → dominant).
    private func parseExtensions(
        _ input: String,
        quality: inout ChordQuality
    ) -> ([ChordExtension], Bool) {
        guard !input.isEmpty else { return ([], true) }

        var remaining = input
        var extensions: [ChordExtension] = []

        // Remove outer parentheses if present: "(add9)" → "add9"
        if remaining.hasPrefix("(") && remaining.hasSuffix(")") {
            remaining = String(remaining.dropFirst().dropLast())
        }

        var iterations = 0
        let maxIterations = 20 // safety valve

        while !remaining.isEmpty && iterations < maxIterations {
            iterations += 1

            // Skip parentheses
            if remaining.hasPrefix("(") {
                remaining = String(remaining.dropFirst())
                continue
            }
            if remaining.hasPrefix(")") {
                remaining = String(remaining.dropFirst())
                continue
            }

            // Try to match an extension pattern
            if let (ext, consumed) = matchExtension(remaining, quality: &quality) {
                if let ext = ext {
                    extensions.append(ext)
                }
                remaining = String(remaining.dropFirst(consumed))
            } else {
                // Unrecognized trailing characters → not a valid chord
                return ([], false)
            }
        }

        return (extensions, true)
    }

    /// Match a single extension at the start of the string.
    /// Returns the extension (or nil if it modifies quality only) and characters consumed.
    /// Returns nil if no pattern matches.
    private func matchExtension(
        _ input: String,
        quality: inout ChordQuality
    ) -> (ChordExtension?, Int)? {
        // Longer patterns first
        let patterns: [(String, ChordExtension?, (inout ChordQuality) -> Void, Int)] = [
            // Major seventh variants
            ("maj7", .majorSeventh, { _ in }, 4),
            ("Maj7", .majorSeventh, { _ in }, 4),
            ("M7", .majorSeventh, { _ in }, 2),
            ("Δ7", .majorSeventh, { _ in }, 2),
            ("Δ", .majorSeventh, { _ in }, 1),

            // Compound extensions
            ("add13", .add13, { _ in }, 5),
            ("add11", .add11, { _ in }, 5),
            ("add9", .add9, { _ in }, 4),
            ("add4", .add4, { _ in }, 4),
            ("add2", .add2, { _ in }, 4),

            // Alterations (must come before plain numbers)
            ("b13", .flatThirteenth, { _ in }, 3),
            ("#11", .sharpEleventh, { _ in }, 3),
            ("♯11", .sharpEleventh, { _ in }, 3),
            ("b9", .flatNinth, { _ in }, 2),
            ("#9", .sharpNinth, { _ in }, 2),
            ("♯9", .sharpNinth, { _ in }, 2),
            ("♭9", .flatNinth, { _ in }, 2),
            ("b5", .flatFifth, { _ in }, 2),
            ("#5", .sharpFifth, { _ in }, 2),
            ("♯5", .sharpFifth, { _ in }, 2),
            ("♭5", .flatFifth, { _ in }, 2),
            ("♭13", .flatThirteenth, { _ in }, 3),

            // Plain tensions
            ("13", .thirteenth, { q in if q == .major { q = .dominant } }, 2),
            ("11", .eleventh, { q in if q == .major { q = .dominant } }, 2),
            ("69", .sixth, { _ in }, 2),  // 6/9 chord
            ("6/9", .sixth, { _ in }, 3),

            // Suspension extensions (for 7sus4, etc.)
            ("sus4", .sus4, { _ in }, 4),
            ("sus2", .sus2, { _ in }, 4),
            ("sus", .sus4, { _ in }, 3),

            ("9", .ninth, { q in if q == .major { q = .dominant } }, 1),
            ("7", .seventh, { q in if q == .major { q = .dominant } }, 1),
            ("6", .sixth, { _ in }, 1),
            ("5", nil, { q in q = .power }, 1),
        ]

        for (pattern, ext, qualityMod, consumed) in patterns {
            if input.hasPrefix(pattern) {
                qualityMod(&quality)
                // Special case: "69" also adds ninth
                if pattern == "69" || pattern == "6/9" {
                    return (.add9, consumed)
                }
                return (ext, consumed)
            }
        }

        return nil
    }
}
