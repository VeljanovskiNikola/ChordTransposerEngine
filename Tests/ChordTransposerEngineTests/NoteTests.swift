// NoteTests.swift
// ChordTransposerEngineTests

import XCTest
@testable import ChordTransposerEngine

final class NoteTests: XCTestCase {

    // MARK: - Parsing

    func testParseNaturalNotes() {
        XCTAssertEqual(Note(string: "C"), .c)
        XCTAssertEqual(Note(string: "D"), .d)
        XCTAssertEqual(Note(string: "E"), .e)
        XCTAssertEqual(Note(string: "F"), .f)
        XCTAssertEqual(Note(string: "G"), .g)
        XCTAssertEqual(Note(string: "A"), .a)
        XCTAssertEqual(Note(string: "B"), .b)
    }

    func testParseSharpNotes() {
        XCTAssertEqual(Note(string: "C#"), .cSharp)
        XCTAssertEqual(Note(string: "D#"), .dSharp)
        XCTAssertEqual(Note(string: "F#"), .fSharp)
        XCTAssertEqual(Note(string: "G#"), .gSharp)
        XCTAssertEqual(Note(string: "A#"), .aSharp)
    }

    func testParseFlatNotes() {
        XCTAssertEqual(Note(string: "Db"), .cSharp)
        XCTAssertEqual(Note(string: "Eb"), .dSharp)
        XCTAssertEqual(Note(string: "Gb"), .fSharp)
        XCTAssertEqual(Note(string: "Ab"), .gSharp)
        XCTAssertEqual(Note(string: "Bb"), .aSharp)
    }

    func testParseUnicodeAccidentals() {
        XCTAssertEqual(Note(string: "C♯"), .cSharp)
        XCTAssertEqual(Note(string: "D♭"), .cSharp)
    }

    func testParseDoubleAccidentals() {
        XCTAssertEqual(Note(string: "C##"), .d)
        XCTAssertEqual(Note(string: "Dbb"), .c)
        XCTAssertEqual(Note(string: "Ebb"), .d)
    }

    func testParseInvalidStrings() {
        XCTAssertNil(Note(string: ""))
        XCTAssertNil(Note(string: "H"))
        XCTAssertNil(Note(string: "X"))
        XCTAssertNil(Note(string: "1"))
        XCTAssertNil(Note(string: "c"))  // lowercase
    }

    // MARK: - Transposition

    func testTransposeUp() {
        XCTAssertEqual(Note.c.transposed(by: 1), .cSharp)
        XCTAssertEqual(Note.c.transposed(by: 2), .d)
        XCTAssertEqual(Note.c.transposed(by: 7), .g)
        XCTAssertEqual(Note.a.transposed(by: 3), .c)
    }

    func testTransposeDown() {
        XCTAssertEqual(Note.c.transposed(by: -1), .b)
        XCTAssertEqual(Note.c.transposed(by: -2), .aSharp)
        XCTAssertEqual(Note.e.transposed(by: -4), .c)
    }

    func testTransposeWraps() {
        XCTAssertEqual(Note.b.transposed(by: 1), .c)
        XCTAssertEqual(Note.c.transposed(by: 12), .c)
        XCTAssertEqual(Note.c.transposed(by: -12), .c)
        XCTAssertEqual(Note.c.transposed(by: 24), .c)
    }

    func testTransposeByZero() {
        for note in Note.allCases {
            XCTAssertEqual(note.transposed(by: 0), note)
        }
    }

    // MARK: - Display

    func testDisplaySharps() {
        XCTAssertEqual(Note.cSharp.displayString(preference: .sharps), "C#")
        XCTAssertEqual(Note.dSharp.displayString(preference: .sharps), "D#")
        XCTAssertEqual(Note.c.displayString(preference: .sharps), "C")
    }

    func testDisplayFlats() {
        XCTAssertEqual(Note.cSharp.displayString(preference: .flats), "Db")
        XCTAssertEqual(Note.dSharp.displayString(preference: .flats), "Eb")
        XCTAssertEqual(Note.aSharp.displayString(preference: .flats), "Bb")
        XCTAssertEqual(Note.c.displayString(preference: .flats), "C")
    }

    func testDisplayNaturalNotesUnaffectedByPreference() {
        for pref in [EnharmonicPreference.sharps, .flats] {
            XCTAssertEqual(Note.c.displayString(preference: pref), "C")
            XCTAssertEqual(Note.d.displayString(preference: pref), "D")
            XCTAssertEqual(Note.e.displayString(preference: pref), "E")
        }
    }
}
