// Song.swift
// ChordTransposerEngine

/// A single token within a parsed line of song text.
public enum ParsedToken: Sendable {
    /// A recognized chord symbol, with its position in the source line.
    case chord(Chord, column: Int)

    /// Plain text (lyrics, whitespace, punctuation).
    case text(String)
}

extension ParsedToken: Equatable {
    public static func == (lhs: ParsedToken, rhs: ParsedToken) -> Bool {
        switch (lhs, rhs) {
        case (.chord(let a, let colA), .chord(let b, let colB)):
            return a == b && colA == colB
        case (.text(let a), .text(let b)):
            return a == b
        default:
            return false
        }
    }
}

/// A single line from the song, classified by content.
public enum ParsedLine: Sendable, Equatable {
    /// A line consisting primarily of chord symbols separated by whitespace.
    case chordLine([ParsedToken])

    /// A line of pure lyrics with no chord symbols.
    case lyricLine(String)

    /// A line that interleaves chords and lyrics (inline chord notation).
    case mixed([ParsedToken])

    /// A blank or whitespace-only line.
    case empty

    /// A non-musical directive line (section headers, capo markers, etc.).
    case directive(String)
}

/// A fully parsed song: an ordered sequence of classified lines.
public struct Song: Sendable, Equatable {
    /// The parsed lines in document order.
    public let lines: [ParsedLine]

    /// Optional metadata extracted during parsing.
    public let metadata: SongMetadata

    public init(lines: [ParsedLine], metadata: SongMetadata) {
        self.lines = lines
        self.metadata = metadata
    }
}

/// Metadata detected during parsing or analysis.
public struct SongMetadata: Sendable, Equatable {
    /// Detected or declared key, if any.
    public let key: DetectedKey?

    /// Detected capo position, if any.
    public let capo: Int?

    /// All unique chords in order of first appearance.
    public let uniqueChords: [Chord]

    public init(key: DetectedKey?, capo: Int?, uniqueChords: [Chord]) {
        self.key = key
        self.capo = capo
        self.uniqueChords = uniqueChords
    }

    /// The total number of unique chords found.
    public var uniqueChordCount: Int { uniqueChords.count }
}

/// The output of a transposition operation.
public struct TranspositionResult: Sendable {
    /// The transposed song.
    public let song: Song

    /// The semitone offset that was applied.
    public let semitones: Int

    /// The enharmonic preference that was used.
    public let preference: EnharmonicPreference

    /// The detected key of the original song.
    public let originalKey: DetectedKey?

    /// The key of the transposed song.
    public let transposedKey: DetectedKey?

    public init(
        song: Song,
        semitones: Int,
        preference: EnharmonicPreference,
        originalKey: DetectedKey?,
        transposedKey: DetectedKey?
    ) {
        self.song = song
        self.semitones = semitones
        self.preference = preference
        self.originalKey = originalKey
        self.transposedKey = transposedKey
    }

    /// Render the entire song back to a plain-text string,
    /// preserving spacing and alignment.
    public func renderText() -> String {
        TextRenderer.render(song: song)
    }
}

/// Configuration options for the parser and engine.
public struct ParserConfiguration: Sendable {
    /// Minimum ratio of chord tokens to classify a line as `.chordLine`.
    public var chordLineThreshold: Double

    /// Whether to recognize bracketed chord notation: [Am]word[G]word
    public var recognizeBracketedChords: Bool

    /// Whether to treat single uppercase letters as chords when on chord-context lines.
    public var allowSingleLetterChords: Bool

    /// Default enharmonic preference when `.auto` cannot determine key.
    public var defaultEnharmonicPreference: EnharmonicPreference

    public init(
        chordLineThreshold: Double = 0.8,
        recognizeBracketedChords: Bool = true,
        allowSingleLetterChords: Bool = true,
        defaultEnharmonicPreference: EnharmonicPreference = .sharps
    ) {
        self.chordLineThreshold = chordLineThreshold
        self.recognizeBracketedChords = recognizeBracketedChords
        self.allowSingleLetterChords = allowSingleLetterChords
        self.defaultEnharmonicPreference = defaultEnharmonicPreference
    }

    public static let `default` = ParserConfiguration()
}
