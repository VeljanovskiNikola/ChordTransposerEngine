// TranspositionEngine.swift
// ChordTransposerEngine

/// Protocol for transposing a Song.
public protocol Transposing: Sendable {
    func transpose(
        _ song: Song,
        by semitones: Int,
        preference: EnharmonicPreference,
        key: DetectedKey?
    ) -> TranspositionResult
}

/// Default transposition engine.
public struct TranspositionEngine: Transposing, Sendable {
    public init() {}

    public func transpose(
        _ song: Song,
        by semitones: Int,
        preference: EnharmonicPreference,
        key: DetectedKey?
    ) -> TranspositionResult {
        // Shortcut: 0 semitones returns the song unchanged
        guard semitones != 0 else {
            return TranspositionResult(
                song: song,
                semitones: 0,
                preference: preference,
                originalKey: key,
                transposedKey: key
            )
        }

        let transposedLines = song.lines.map { line in
            transposeLine(line, by: semitones, preference: preference, key: key)
        }

        // Transpose unique chords for metadata
        let transposedUniqueChords = song.metadata.uniqueChords.map {
            $0.transposed(by: semitones, preference: preference, key: key)
        }

        // Transpose detected key
        let transposedKey: DetectedKey?
        if let originalKey = key {
            transposedKey = DetectedKey(
                root: originalKey.root.transposed(by: semitones),
                mode: originalKey.mode,
                confidence: originalKey.confidence
            )
        } else {
            transposedKey = nil
        }

        let newMetadata = SongMetadata(
            key: transposedKey,
            capo: song.metadata.capo,
            uniqueChords: transposedUniqueChords
        )

        let newSong = Song(lines: transposedLines, metadata: newMetadata)

        return TranspositionResult(
            song: newSong,
            semitones: semitones,
            preference: preference,
            originalKey: key,
            transposedKey: transposedKey
        )
    }

    // MARK: - Line Transposition

    private func transposeLine(
        _ line: ParsedLine,
        by semitones: Int,
        preference: EnharmonicPreference,
        key: DetectedKey?
    ) -> ParsedLine {
        switch line {
        case .chordLine(let tokens):
            return .chordLine(transposeTokens(tokens, by: semitones, preference: preference, key: key))
        case .mixed(let tokens):
            return .mixed(transposeTokens(tokens, by: semitones, preference: preference, key: key))
        case .lyricLine, .empty, .directive:
            return line
        }
    }

    private func transposeTokens(
        _ tokens: [ParsedToken],
        by semitones: Int,
        preference: EnharmonicPreference,
        key: DetectedKey?
    ) -> [ParsedToken] {
        tokens.map { token in
            switch token {
            case .chord(let chord, let column):
                let transposed = chord.transposed(by: semitones, preference: preference, key: key)
                return .chord(transposed, column: column)
            case .text:
                return token
            }
        }
    }
}

// MARK: - Text Renderer

/// Renders a Song back to plain text with proper spacing.
public enum TextRenderer {
    /// Render a song to plain text, preserving chord-to-lyric alignment.
    public static func render(song: Song) -> String {
        var output: [String] = []

        for line in song.lines {
            switch line {
            case .chordLine(let tokens):
                output.append(renderChordLine(tokens))
            case .lyricLine(let text):
                output.append(text)
            case .mixed(let tokens):
                output.append(renderMixedLine(tokens))
            case .empty:
                output.append("")
            case .directive(let text):
                output.append(text)
            }
        }

        return output.joined(separator: "\n")
    }

    /// Render a chord line, positioning each chord at its column.
    /// Adjusts spacing when transposed chord widths differ from originals.
    private static func renderChordLine(_ tokens: [ParsedToken]) -> String {
        struct ChordPosition {
            let chord: Chord
            let targetColumn: Int
        }

        var chords: [ChordPosition] = []
        var leadingText = ""

        for token in tokens {
            switch token {
            case .chord(let chord, let column):
                chords.append(ChordPosition(chord: chord, targetColumn: column))
            case .text(let text):
                if chords.isEmpty {
                    leadingText = text
                }
            }
        }

        guard !chords.isEmpty else { return leadingText }

        var result = ""
        var currentColumn = 0

        for (index, pos) in chords.enumerated() {
            let chordText = pos.chord.originalText
            let targetCol = pos.targetColumn

            // Ensure we don't go backwards; maintain at least 1 space between chords
            let minColumn = index == 0 ? targetCol : max(targetCol, currentColumn + 1)

            // Pad with spaces to reach the target column
            let spacesNeeded = max(0, minColumn - currentColumn)
            result += String(repeating: " ", count: spacesNeeded)
            result += chordText
            currentColumn = minColumn + chordText.count
        }

        return result
    }

    /// Render a mixed line (inline chords with lyrics).
    private static func renderMixedLine(_ tokens: [ParsedToken]) -> String {
        var result = ""
        for token in tokens {
            switch token {
            case .chord(let chord, _):
                result += chord.originalText
            case .text(let text):
                result += text
            }
        }
        return result
    }
}
