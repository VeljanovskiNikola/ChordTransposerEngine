// Chord.swift
// ChordTransposerEngine

/// Captures how a note was originally written, preserving round-trip fidelity.
public struct NoteSpelling: Hashable, Codable, Sendable {
    /// The resolved pitch class.
    public let note: Note

    /// The original text as it appeared in the source (e.g., "Db", "C#").
    public let originalText: String

    public init(note: Note, originalText: String) {
        self.note = note
        self.originalText = originalText
    }
}

/// A fully parsed chord symbol.
public struct Chord: Hashable, Codable, Sendable {
    /// The root pitch of the chord.
    public let root: NoteSpelling

    /// The harmonic quality (major, minor, dim, aug, sus, …).
    public let quality: ChordQuality

    /// Zero or more extensions/alterations, in the order they appeared.
    public let extensions: [ChordExtension]

    /// Optional slash bass note.
    public let bass: NoteSpelling?

    /// The original raw string exactly as written in the source.
    public let originalText: String

    /// The suffix text after the root note (quality + extensions as written).
    /// e.g., for "Bbm7b5" this would be "m7b5".
    public let suffixText: String

    public init(
        root: NoteSpelling,
        quality: ChordQuality,
        extensions: [ChordExtension],
        bass: NoteSpelling?,
        originalText: String,
        suffixText: String
    ) {
        self.root = root
        self.quality = quality
        self.extensions = extensions
        self.bass = bass
        self.originalText = originalText
        self.suffixText = suffixText
    }
}

// MARK: - Transposition

extension Chord {
    /// Transpose this chord by the given semitones, returning a new Chord.
    /// Only pitch-bearing components (root, bass) change. Quality and extensions stay.
    public func transposed(
        by semitones: Int,
        preference: EnharmonicPreference,
        key: DetectedKey? = nil
    ) -> Chord {
        guard semitones != 0 else { return self }

        let newRootNote = root.note.transposed(by: semitones)
        let newRootText = newRootNote.displayString(preference: preference, key: key)
        let newRoot = NoteSpelling(note: newRootNote, originalText: newRootText)

        let newBass: NoteSpelling?
        if let bass = bass {
            let newBassNote = bass.note.transposed(by: semitones)
            let newBassText = newBassNote.displayString(preference: preference, key: key)
            newBass = NoteSpelling(note: newBassNote, originalText: newBassText)
        } else {
            newBass = nil
        }

        let newOriginal = renderChordString(root: newRootText, suffix: suffixText, bass: newBass?.originalText)

        return Chord(
            root: newRoot,
            quality: quality,
            extensions: extensions,
            bass: newBass,
            originalText: newOriginal,
            suffixText: suffixText
        )
    }

    /// Render the chord as a display string.
    public func displayString(preference: EnharmonicPreference, key: DetectedKey? = nil) -> String {
        return originalText
    }

    /// Build a chord string from components.
    private func renderChordString(root: String, suffix: String, bass: String?) -> String {
        var result = root + suffix
        if let bass = bass {
            result += "/" + bass
        }
        return result
    }
}
