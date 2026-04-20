// ChordQuality.swift
// ChordTransposerEngine

/// The harmonic quality of a chord, independent of extensions.
public enum ChordQuality: String, Hashable, Codable, Sendable {
    case major
    case minor
    case diminished
    case augmented
    case suspendedSecond
    case suspendedFourth
    case dominant
    case halfDiminished
    case power
}

/// A single extension or alteration applied to a chord.
public enum ChordExtension: String, Hashable, Codable, Sendable {
    // Tensions
    case seventh
    case majorSeventh
    case sixth
    case ninth
    case eleventh
    case thirteenth

    // Additions
    case add9
    case add11
    case add13
    case add2
    case add4

    // Alterations
    case flatFifth
    case sharpFifth
    case flatNinth
    case sharpNinth
    case sharpEleventh
    case flatThirteenth

    // Sus as extension (for compound forms like C7sus4)
    case sus2
    case sus4
}

/// Enharmonic preference for rendering notes in output.
public enum EnharmonicPreference: String, Hashable, Codable, Sendable {
    /// Always use sharps: C# D# F# G# A#
    case sharps
    /// Always use flats: Db Eb Gb Ab Bb
    case flats
    /// Infer spelling from detected key signature.
    case auto
}

/// A detected musical key with confidence score.
public struct DetectedKey: Hashable, Codable, Sendable {
    public let root: Note
    public let mode: KeyMode
    public let confidence: Double

    public init(root: Note, mode: KeyMode, confidence: Double) {
        self.root = root
        self.mode = mode
        self.confidence = confidence
    }
}

/// Major or minor mode.
public enum KeyMode: String, Hashable, Codable, Sendable {
    case major
    case minor
}
