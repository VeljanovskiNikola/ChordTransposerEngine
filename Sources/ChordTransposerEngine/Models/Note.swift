// Note.swift
// ChordTransposerEngine

/// Represents one of the 12 chromatic pitch classes.
/// The raw value is the semitone index: C = 0, C#/Db = 1, ... B = 11.
public enum Note: Int, CaseIterable, Hashable, Codable, Sendable {
    case c      = 0
    case cSharp = 1
    case d      = 2
    case dSharp = 3
    case e      = 4
    case f      = 5
    case fSharp = 6
    case g      = 7
    case gSharp = 8
    case a      = 9
    case aSharp = 10
    case b      = 11
}

// MARK: - Transposition

extension Note {
    /// Transpose this note by the given number of semitones (wraps modulo 12).
    public func transposed(by semitones: Int) -> Note {
        // Normalize to positive modular arithmetic
        let raw = (self.rawValue + semitones % 12 + 12) % 12
        return Note(rawValue: raw)!
    }
}

// MARK: - Parsing from String

extension Note {
    /// Initialize from a note name string like "C", "C#", "Db", "F##", "Ebb".
    /// Returns nil if the string is not a recognized note name.
    /// Also returns the number of characters consumed from the string.
    public init?(string: String) {
        guard let (note, _) = Note.parse(from: string) else { return nil }
        self = note
    }

    /// Parse a note from the beginning of a string, returning the note
    /// and the number of characters consumed.
    internal static func parse(from string: String) -> (Note, consumed: Int)? {
        guard let first = string.first,
              let baseValue = Note.letterValue(first) else {
            return nil
        }

        var offset = 0
        var consumed = 1
        let chars = Array(string)

        // Count sharps and flats after the letter
        var idx = 1
        while idx < chars.count {
            let ch = chars[idx]
            if ch == "#" || ch == "♯" {
                offset += 1
                consumed += 1
                idx += 1
            } else if ch == "b" || ch == "♭" {
                // Disambiguate: 'b' after a note letter could be a flat OR part of "Bb"
                // Only treat as flat if the base letter is NOT 'B' or we're past the first accidental
                offset -= 1
                consumed += 1
                idx += 1
            } else {
                break
            }
        }

        let raw = (baseValue + offset + 120) % 12
        guard let note = Note(rawValue: raw) else { return nil }
        return (note, consumed)
    }

    /// Map a letter character to its base semitone value.
    private static func letterValue(_ ch: Character) -> Int? {
        switch ch {
        case "C": return 0
        case "D": return 2
        case "E": return 4
        case "F": return 5
        case "G": return 7
        case "A": return 9
        case "B": return 11
        default:  return nil
        }
    }

    /// Check whether a character is a valid note letter.
    internal static func isNoteLetter(_ ch: Character) -> Bool {
        letterValue(ch) != nil
    }
}

// MARK: - Display

extension Note {
    /// The sharp-preferring display names for each pitch class.
    internal static let sharpNames: [String] = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]

    /// The flat-preferring display names for each pitch class.
    internal static let flatNames: [String] = [
        "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"
    ]

    /// Render this note as a display string given an enharmonic preference.
    public func displayString(preference: EnharmonicPreference) -> String {
        switch preference {
        case .sharps:
            return Note.sharpNames[rawValue]
        case .flats:
            return Note.flatNames[rawValue]
        case .auto:
            // .auto without context falls back to sharps
            return Note.sharpNames[rawValue]
        }
    }

    /// Render with key context for `.auto` preference.
    internal func displayString(
        preference: EnharmonicPreference,
        key: DetectedKey?
    ) -> String {
        switch preference {
        case .sharps:
            return Note.sharpNames[rawValue]
        case .flats:
            return Note.flatNames[rawValue]
        case .auto:
            guard let key = key else {
                return Note.sharpNames[rawValue]
            }
            return EnharmonicResolver.prefersFlatSpelling(key: key)
                ? Note.flatNames[rawValue]
                : Note.sharpNames[rawValue]
        }
    }
}
