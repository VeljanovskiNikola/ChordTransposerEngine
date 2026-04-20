// ChordTransposerEngine.swift
// ChordTransposerEngine
//
// The main entry point for consumers of this framework.

/// The main entry point for chord parsing, transposition, and analysis.
///
/// Usage:
/// ```swift
/// let engine = ChordTransposerEngine()
/// let song = engine.parse(text: rawSongText)
/// let result = engine.transpose(song, by: 3, preference: .auto)
/// let output = result.renderText()
/// ```
public struct ChordTransposerEngine: Sendable {

    private let parser: SongParser
    private let transposer: Transposing
    private let keyDetector: KeyDetecting
    private let analyzer: ChordAnalyzer
    private let configuration: ParserConfiguration

    // MARK: - Initialization

    /// Create an engine with default configuration.
    public init() {
        self.init(configuration: .default)
    }

    /// Create an engine with custom configuration.
    public init(configuration: ParserConfiguration) {
        let tokenizer = ChordTokenizer(configuration: configuration)
        let classifier = LineClassifier(configuration: configuration)
        self.parser = SongParser(tokenizer: tokenizer, classifier: classifier, configuration: configuration)
        self.transposer = TranspositionEngine()
        self.keyDetector = KeyDetector()
        self.analyzer = ChordAnalyzer()
        self.configuration = configuration
    }

    /// Create an engine with fully injected dependencies (for testing).
    public init(
        tokenizer: ChordParsing,
        classifier: LineClassifying,
        transposer: Transposing,
        keyDetector: KeyDetecting,
        configuration: ParserConfiguration = .default
    ) {
        self.parser = SongParser(tokenizer: tokenizer, classifier: classifier, configuration: configuration)
        self.transposer = transposer
        self.keyDetector = keyDetector
        self.analyzer = ChordAnalyzer()
        self.configuration = configuration
    }

    // MARK: - Parsing

    /// Parse raw song text into a structured `Song`.
    public func parse(text: String) -> Song {
        var song = parser.parse(text: text)

        // Enrich metadata with key detection
        let allChords = analyzer.allChords(in: song)
        let detectedKeys = keyDetector.detectKey(from: allChords)
        let bestKey = detectedKeys.first

        if bestKey != nil || song.metadata.key == nil {
            let enrichedMetadata = SongMetadata(
                key: bestKey,
                capo: song.metadata.capo,
                uniqueChords: song.metadata.uniqueChords
            )
            song = Song(lines: song.lines, metadata: enrichedMetadata)
        }

        return song
    }

    /// Parse a single line into a `ParsedLine`.
    public func parseLine(_ line: String) -> ParsedLine {
        parser.parseLine(line)
    }

    // MARK: - Transposition

    /// Transpose a parsed song by the given number of semitones.
    public func transpose(
        _ song: Song,
        by semitones: Int,
        preference: EnharmonicPreference = .auto
    ) -> TranspositionResult {
        let resolvedPreference: EnharmonicPreference
        if preference == .auto, let key = song.metadata.key {
            resolvedPreference = EnharmonicResolver.prefersFlatSpelling(key: key) ? .flats : .sharps
        } else if preference == .auto {
            resolvedPreference = configuration.defaultEnharmonicPreference
        } else {
            resolvedPreference = preference
        }

        return transposer.transpose(
            song,
            by: semitones,
            preference: resolvedPreference,
            key: song.metadata.key
        )
    }

    /// Convenience: parse and transpose in one call.
    public func transposeText(
        _ text: String,
        by semitones: Int,
        preference: EnharmonicPreference = .auto
    ) -> TranspositionResult {
        let song = parse(text: text)
        return transpose(song, by: semitones, preference: preference)
    }

    // MARK: - Analysis

    /// Detect the key of a parsed song.
    public func detectKey(of song: Song) -> DetectedKey? {
        song.metadata.key
    }

    /// Extract all unique chords from a parsed song.
    public func uniqueChords(in song: Song) -> [Chord] {
        analyzer.uniqueChords(in: song)
    }

    // MARK: - Single Chord Operations

    /// Parse a single chord string. Returns nil if not a valid chord.
    public func parseChord(_ string: String) -> Chord? {
        let tokenizer = ChordTokenizer(configuration: configuration)
        return tokenizer.parseChord(string)
    }

    /// Transpose a single chord string and return the new chord string.
    public func transposeChord(
        _ string: String,
        by semitones: Int,
        preference: EnharmonicPreference = .auto
    ) -> String? {
        guard let chord = parseChord(string) else { return nil }
        let resolvedPref = preference == .auto ? configuration.defaultEnharmonicPreference : preference
        let transposed = chord.transposed(by: semitones, preference: resolvedPref)
        return transposed.originalText
    }
}
