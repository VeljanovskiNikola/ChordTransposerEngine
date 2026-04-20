// ChordAnalyzer.swift
// ChordTransposerEngine

/// Provides analytical utilities for chords and songs.
public struct ChordAnalyzer: Sendable {

    public init() {}

    /// Extract all chords from a song in document order.
    public func allChords(in song: Song) -> [Chord] {
        var chords: [Chord] = []
        for line in song.lines {
            switch line {
            case .chordLine(let tokens), .mixed(let tokens):
                for token in tokens {
                    if case .chord(let chord, _) = token {
                        chords.append(chord)
                    }
                }
            default:
                break
            }
        }
        return chords
    }

    /// Extract unique chords in order of first appearance.
    public func uniqueChords(in song: Song) -> [Chord] {
        var seen = Set<String>()
        var unique: [Chord] = []
        for chord in allChords(in: song) {
            if !seen.contains(chord.originalText) {
                seen.insert(chord.originalText)
                unique.append(chord)
            }
        }
        return unique
    }

    /// Count occurrences of each chord.
    public func chordFrequency(in song: Song) -> [(chord: Chord, count: Int)] {
        var counts: [String: (chord: Chord, count: Int)] = [:]
        for chord in allChords(in: song) {
            if let existing = counts[chord.originalText] {
                counts[chord.originalText] = (existing.chord, existing.count + 1)
            } else {
                counts[chord.originalText] = (chord, 1)
            }
        }
        return counts.values.sorted { $0.count > $1.count }
    }
}
