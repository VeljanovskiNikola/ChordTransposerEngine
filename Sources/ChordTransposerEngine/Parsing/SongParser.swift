// SongParser.swift
// ChordTransposerEngine

import Foundation

/// Parses raw song text into a structured `Song`.
public struct SongParser: Sendable {
    private let tokenizer: ChordParsing
    private let classifier: LineClassifying
    private let configuration: ParserConfiguration

    public init(
        tokenizer: ChordParsing? = nil,
        classifier: LineClassifying? = nil,
        configuration: ParserConfiguration = .default
    ) {
        self.tokenizer = tokenizer ?? ChordTokenizer(configuration: configuration)
        self.classifier = classifier ?? LineClassifier(configuration: configuration)
        self.configuration = configuration
    }

    /// Parse raw song text into a structured `Song`.
    public func parse(text: String) -> Song {
        let rawLines = text.components(separatedBy: "\n")
        var parsedLines: [ParsedLine] = []
        var allChords: [Chord] = []
        var uniqueChordTexts = Set<String>()
        var uniqueChords: [Chord] = []
        var detectedCapo: Int? = nil

        for rawLine in rawLines {
            let tokens = tokenizer.tokenize(rawLine)
            let classified = classifier.classify(line: rawLine, tokens: tokens)
            parsedLines.append(classified)

            // Collect chords from this line
            switch classified {
            case .chordLine(let tokens), .mixed(let tokens):
                for token in tokens {
                    if case .chord(let chord, _) = token {
                        allChords.append(chord)
                        if !uniqueChordTexts.contains(chord.originalText) {
                            uniqueChordTexts.insert(chord.originalText)
                            uniqueChords.append(chord)
                        }
                    }
                }
            case .directive(let text):
                // Try to extract capo
                if let capo = extractCapo(from: text) {
                    detectedCapo = capo
                }
            default:
                break
            }
        }

        let metadata = SongMetadata(
            key: nil, // Key detection is done separately via KeyDetector
            capo: detectedCapo,
            uniqueChords: uniqueChords
        )

        return Song(lines: parsedLines, metadata: metadata)
    }

    /// Parse a single line.
    public func parseLine(_ line: String) -> ParsedLine {
        let tokens = tokenizer.tokenize(line)
        return classifier.classify(line: line, tokens: tokens)
    }

    // MARK: - Metadata Extraction

    private func extractCapo(from directive: String) -> Int? {
        let lower = directive.lowercased()
        guard lower.hasPrefix("capo") else { return nil }

        // Extract number from "Capo 3", "Capo: 3", "Capo on 3rd fret"
        let digits = directive.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
        if let number = Int(String(digits)), number >= 0 && number <= 12 {
            return number
        }
        return nil
    }
}
