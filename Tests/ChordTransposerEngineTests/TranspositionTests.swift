// TranspositionTests.swift
// ChordTransposerEngineTests

import XCTest
@testable import ChordTransposerEngine

final class TranspositionTests: XCTestCase {
    let engine = ChordTransposerEngine()

    // MARK: - Single Chord Transposition

    func testTransposeAmUp3IsCm() {
        let result = engine.transposeChord("Am", by: 3, preference: .flats)
        XCTAssertEqual(result, "Cm")
    }

    func testTransposeCUp1IsCSharp() {
        let result = engine.transposeChord("C", by: 1, preference: .sharps)
        XCTAssertEqual(result, "C#")
    }

    func testTransposeCUp1IsDb() {
        let result = engine.transposeChord("C", by: 1, preference: .flats)
        XCTAssertEqual(result, "Db")
    }

    func testTransposeGUp2IsA() {
        let result = engine.transposeChord("G", by: 2, preference: .sharps)
        XCTAssertEqual(result, "A")
    }

    func testTransposeSlashChordMovesRootAndBass() {
        let result = engine.transposeChord("D/F#", by: 2, preference: .sharps)
        XCTAssertEqual(result, "E/G#")
    }

    func testTransposeSlashChordFlats() {
        let result = engine.transposeChord("D/F#", by: 2, preference: .flats)
        XCTAssertEqual(result, "E/Ab")
    }

    func testTransposeSeventh() {
        let result = engine.transposeChord("G7", by: 2, preference: .sharps)
        XCTAssertEqual(result, "A7")
    }

    func testTransposeMajorSeventh() {
        let result = engine.transposeChord("Cmaj7", by: 5, preference: .sharps)
        XCTAssertEqual(result, "Fmaj7")
    }

    func testTransposeSus4() {
        let result = engine.transposeChord("Dsus4", by: 3, preference: .sharps)
        XCTAssertEqual(result, "Fsus4")
    }

    func testTransposeDiminished() {
        let result = engine.transposeChord("Bdim", by: 1, preference: .sharps)
        XCTAssertEqual(result, "Cdim")
    }

    func testTransposeBy0ReturnsSameText() {
        let result = engine.transposeChord("Am7", by: 0, preference: .sharps)
        XCTAssertEqual(result, "Am7")
    }

    func testTransposeInvalidChordReturnsNil() {
        XCTAssertNil(engine.transposeChord("Hello", by: 3, preference: .sharps))
    }

    // MARK: - Round-trip Transposition

    func testRoundTripTransposition() {
        let chords = ["C", "Am", "F#m", "Bb7", "Dmaj7", "G#dim", "Fsus4", "Cadd9", "D/F#"]
        for chord in chords {
            for offset in 1...11 {
                let up = engine.transposeChord(chord, by: offset, preference: .sharps)
                XCTAssertNotNil(up, "Transpose \(chord) by +\(offset) failed")
                if let up = up {
                    let back = engine.transposeChord(up, by: -offset, preference: .sharps)
                    XCTAssertNotNil(back, "Round-trip \(chord) → \(up) back failed")
                    // Verify the root note is the same (spelling may differ)
                    let originalRoot = engine.parseChord(chord)?.root.note
                    let roundTripRoot = engine.parseChord(back!)?.root.note
                    XCTAssertEqual(originalRoot, roundTripRoot,
                        "Round trip failed for \(chord) +\(offset): got \(back ?? "nil")")
                }
            }
        }
    }

    // MARK: - Full Song Transposition

    func testTransposeFullSong() {
        let input = """
        Am    G    F    C
        Amazing grace how sweet
        """

        let result = engine.transposeText(input, by: 2, preference: .sharps)
        let output = result.renderText()

        // Verify chords are transposed
        XCTAssertTrue(output.contains("Bm"), "Expected Bm in output: \(output)")
        XCTAssertTrue(output.contains("A"), "Expected A in output: \(output)")
        XCTAssertTrue(output.contains("G"), "Expected G in output: \(output)")
        XCTAssertTrue(output.contains("D"), "Expected D in output: \(output)")

        // Lyrics unchanged
        XCTAssertTrue(output.contains("Amazing grace how sweet"))
    }

    func testTransposePreservesEmptyLines() {
        let input = """
        [Verse 1]
        Am    G

        Amazing grace

        [Chorus]
        F    C
        How sweet the sound
        """

        let song = engine.parse(text: input)
        let result = engine.transpose(song, by: 1, preference: .sharps)
        let output = result.renderText()

        // Should still have blank lines and directives
        let lines = output.components(separatedBy: "\n")
        XCTAssertTrue(lines.contains(""), "Should preserve empty lines")
        XCTAssertTrue(lines.contains("Amazing grace"), "Should preserve lyrics")
    }

    // MARK: - Enharmonic Preference

    func testSharpsPreference() {
        let result = engine.transposeChord("C", by: 1, preference: .sharps)
        XCTAssertEqual(result, "C#")
    }

    func testFlatsPreference() {
        let result = engine.transposeChord("C", by: 1, preference: .flats)
        XCTAssertEqual(result, "Db")
    }

    // MARK: - Every Interval

    func testTransposeAllIntervals() {
        let expected_sharps = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        for (offset, expectedNote) in expected_sharps.enumerated() {
            let result = engine.transposeChord("C", by: offset, preference: .sharps)
            XCTAssertEqual(result, expectedNote,
                "C transposed by \(offset) with sharps should be \(expectedNote)")
        }

        let expected_flats = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        for (offset, expectedNote) in expected_flats.enumerated() {
            let result = engine.transposeChord("C", by: offset, preference: .flats)
            XCTAssertEqual(result, expectedNote,
                "C transposed by \(offset) with flats should be \(expectedNote)")
        }
    }
}
