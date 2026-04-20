// LineClassifier.swift
// ChordTransposerEngine

import Foundation

/// Protocol for classifying a line into a ParsedLine case.
public protocol LineClassifying: Sendable {
    func classify(line: String, tokens: [ParsedToken]) -> ParsedLine
}

/// Default line classifier using heuristic rules.
public struct LineClassifier: LineClassifying, Sendable {
    private let configuration: ParserConfiguration

    public init(configuration: ParserConfiguration = .default) {
        self.configuration = configuration
    }

    public func classify(line: String, tokens: [ParsedToken]) -> ParsedLine {
        // R1: Empty or whitespace-only
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .empty
        }

        // R2: Directive patterns
        if isDirective(trimmed) {
            return .directive(trimmed)
        }

        // Count chord vs text tokens (ignoring whitespace-only text tokens)
        let chordCount = tokens.filter { token in
            if case .chord = token { return true }
            return false
        }.count

        let substantiveTextTokens = tokens.filter { token in
            if case .text(let t) = token {
                return !t.trimmingCharacters(in: .whitespaces).isEmpty
            }
            return false
        }
        let textCount = substantiveTextTokens.count
        let totalSubstantive = chordCount + textCount

        // R3: No chord tokens → lyric line
        if chordCount == 0 {
            return .lyricLine(line)
        }

        // Check if this was bracketed notation (mixed by definition)
        let hasBracketedChords = line.contains("[") && tokens.contains(where: {
            if case .chord = $0 { return true }
            return false
        })
        if hasBracketedChords {
            return .mixed(tokens)
        }

        // R4: Compute chord ratio
        let chordRatio = totalSubstantive > 0
            ? Double(chordCount) / Double(totalSubstantive)
            : 0

        // R5: High chord ratio → chord line
        if chordRatio >= configuration.chordLineThreshold {
            return .chordLine(tokens)
        }

        // R6: Has both chords and lyrics → mixed
        if chordCount > 0 && textCount > 0 {
            return .mixed(tokens)
        }

        // Fallback: if there are only chords (ratio < threshold somehow), still chord line
        if textCount == 0 && chordCount > 0 {
            return .chordLine(tokens)
        }

        return .lyricLine(line)
    }

    // MARK: - Directive Detection

    private static let directivePatterns: [String] = [
        "verse", "chorus", "bridge", "intro", "outro",
        "pre-chorus", "prechorus", "pre chorus",
        "interlude", "solo", "instrumental", "hook",
        "tag", "coda", "ending", "refrain", "break"
    ]

    private func isDirective(_ line: String) -> Bool {
        let lower = line.lowercased().trimmingCharacters(in: .whitespaces)

        // Bracketed section headers: [Verse 1], [Chorus], etc.
        if lower.hasPrefix("[") && lower.hasSuffix("]") {
            let inner = String(lower.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
            for pattern in Self.directivePatterns {
                if inner.hasPrefix(pattern) { return true }
            }
            // Also catch generic numbered sections: [1], [2], etc.
            if inner.allSatisfy({ $0.isNumber || $0.isWhitespace }) && !inner.isEmpty {
                return true
            }
        }

        // "Verse 1:", "Chorus:", etc. (with optional number and colon)
        for pattern in Self.directivePatterns {
            if lower.hasPrefix(pattern) {
                let after = lower.dropFirst(pattern.count).trimmingCharacters(in: .whitespaces)
                if after.isEmpty
                    || after.hasPrefix(":")
                    || after.first?.isNumber == true
                    || (after.first?.isNumber == true && after.dropFirst().trimmingCharacters(in: .whitespaces).hasPrefix(":")) {
                    return true
                }
            }
        }

        // Capo directives: "Capo 3", "capo on 5th fret"
        if lower.hasPrefix("capo") { return true }

        // Key declarations: "Key: Am", "Key of G"
        if lower.hasPrefix("key:") || lower.hasPrefix("key of") { return true }

        // Tempo: "Tempo: 120", "BPM: 95"
        if lower.hasPrefix("tempo") || lower.hasPrefix("bpm") { return true }

        // Comment lines
        if lower.hasPrefix("//") || lower.hasPrefix("#") { return true }

        return false
    }
}
