// ChordParsingTests.swift
// ChordTransposerEngineTests

import XCTest
@testable import ChordTransposerEngine

final class ChordParsingTests: XCTestCase {
    let engine = ChordTransposerEngine()

    // MARK: - Basic Chords

    func testParseMajorChords() {
        let chord = engine.parseChord("C")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .c)
        XCTAssertEqual(chord?.quality, .major)
        XCTAssertTrue(chord?.extensions.isEmpty ?? false)
        XCTAssertNil(chord?.bass)
    }

    func testParseMinorChords() {
        let chord = engine.parseChord("Am")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .a)
        XCTAssertEqual(chord?.quality, .minor)

        let chord2 = engine.parseChord("F#m")
        XCTAssertNotNil(chord2)
        XCTAssertEqual(chord2?.root.note, .fSharp)
        XCTAssertEqual(chord2?.quality, .minor)
    }

    func testParseFlatRootChords() {
        let chord = engine.parseChord("Bb7")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .aSharp)
        XCTAssertEqual(chord?.root.originalText, "Bb")
        XCTAssertEqual(chord?.quality, .dominant)
        XCTAssertTrue(chord?.extensions.contains(.seventh) ?? false)
    }

    func testParseBbMinor() {
        let chord = engine.parseChord("Bbm")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .aSharp)
        XCTAssertEqual(chord?.quality, .minor)
    }

    // MARK: - Extended Chords

    func testParseDominantSeventh() {
        let chord = engine.parseChord("G7")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .dominant)
        XCTAssertTrue(chord?.extensions.contains(.seventh) ?? false)
    }

    func testParseMajorSeventh() {
        let chord = engine.parseChord("Cmaj7")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .c)
        XCTAssertEqual(chord?.quality, .major)
        XCTAssertTrue(chord?.extensions.contains(.majorSeventh) ?? false)
    }

    func testParseMinorSeventh() {
        let chord = engine.parseChord("Dm7")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .minor)
        XCTAssertTrue(chord?.extensions.contains(.seventh) ?? false)
    }

    func testParseNinth() {
        let chord = engine.parseChord("C9")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .dominant)
        XCTAssertTrue(chord?.extensions.contains(.ninth) ?? false)
    }

    func testParseAdd9() {
        let chord = engine.parseChord("Cadd9")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .major)
        XCTAssertTrue(chord?.extensions.contains(.add9) ?? false)
    }

    func testParseParentheticalAdd9() {
        let chord = engine.parseChord("C(add9)")
        XCTAssertNotNil(chord)
        XCTAssertTrue(chord?.extensions.contains(.add9) ?? false)
    }

    // MARK: - Diminished & Augmented

    func testParseDiminished() {
        for symbol in ["Cdim", "C°", "Co"] {
            let chord = engine.parseChord(symbol)
            XCTAssertNotNil(chord, "Failed to parse: \(symbol)")
            XCTAssertEqual(chord?.quality, .diminished, "Wrong quality for: \(symbol)")
        }
    }

    func testParseAugmented() {
        for symbol in ["Caug", "C+"] {
            let chord = engine.parseChord(symbol)
            XCTAssertNotNil(chord, "Failed to parse: \(symbol)")
            XCTAssertEqual(chord?.quality, .augmented, "Wrong quality for: \(symbol)")
        }
    }

    func testParseHalfDiminished() {
        let chord = engine.parseChord("Cø")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .halfDiminished)
    }

    // MARK: - Suspended Chords

    func testParseSus4() {
        let chord = engine.parseChord("Csus4")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .suspendedFourth)
    }

    func testParseSus2() {
        let chord = engine.parseChord("Dsus2")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .suspendedSecond)
    }

    func testParseBareSus() {
        let chord = engine.parseChord("Asus")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .suspendedFourth)
    }

    // MARK: - Slash Chords

    func testParseSlashChord() {
        let chord = engine.parseChord("Am/G")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .a)
        XCTAssertEqual(chord?.quality, .minor)
        XCTAssertEqual(chord?.bass?.note, .g)
    }

    func testParseSlashChordWithSharpBass() {
        let chord = engine.parseChord("D/F#")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .d)
        XCTAssertEqual(chord?.bass?.note, .fSharp)
        XCTAssertEqual(chord?.bass?.originalText, "F#")
    }

    func testParseComplexSlashChord() {
        let chord = engine.parseChord("Cmaj7/B")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .c)
        XCTAssertTrue(chord?.extensions.contains(.majorSeventh) ?? false)
        XCTAssertEqual(chord?.bass?.note, .b)
    }

    // MARK: - Altered Chords

    func testParseSharpNinth() {
        let chord = engine.parseChord("C7#9")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .dominant)
        XCTAssertTrue(chord?.extensions.contains(.seventh) ?? false)
        XCTAssertTrue(chord?.extensions.contains(.sharpNinth) ?? false)
    }

    func testParseFlatFifth() {
        let chord = engine.parseChord("Cm7b5")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .minor)
        XCTAssertTrue(chord?.extensions.contains(.seventh) ?? false)
        XCTAssertTrue(chord?.extensions.contains(.flatFifth) ?? false)
    }

    func testParseMinorNinth() {
        let chord = engine.parseChord("Fm9")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .f)
        XCTAssertEqual(chord?.quality, .minor)
        XCTAssertTrue(chord?.extensions.contains(.ninth) ?? false)
    }

    func testParseThirteenth() {
        let chord = engine.parseChord("A13")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.quality, .dominant)
        XCTAssertTrue(chord?.extensions.contains(.thirteenth) ?? false)
    }

    // MARK: - Power Chords

    func testParsePowerChord() {
        let chord = engine.parseChord("E5")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.root.note, .e)
        XCTAssertEqual(chord?.quality, .power)
    }

    // MARK: - Sixth Chords

    func testParseSixth() {
        let chord = engine.parseChord("C6")
        XCTAssertNotNil(chord)
        XCTAssertTrue(chord?.extensions.contains(.sixth) ?? false)
    }

    // MARK: - Rejection of Non-Chords

    func testRejectsEnglishWords() {
        let nonChords = [
            "Amazing", "the", "Hello", "World", "Love",
            "Dad", "Bad", "Face", "Grace", "Down",
            "Every", "Give", "Back", "And", "For",
            "Because", "Between", "Call", "Day"
        ]
        for word in nonChords {
            XCTAssertNil(engine.parseChord(word), "Should reject '\(word)' as chord")
        }
    }

    func testRejectsEmptyString() {
        XCTAssertNil(engine.parseChord(""))
    }

    func testRejectsLowercase() {
        XCTAssertNil(engine.parseChord("am"))
        XCTAssertNil(engine.parseChord("c"))
    }

    // MARK: - Original Text Preservation

    func testPreservesOriginalText() {
        let chord = engine.parseChord("Bbm7b5")
        XCTAssertEqual(chord?.originalText, "Bbm7b5")
        XCTAssertEqual(chord?.root.originalText, "Bb")
    }
}
