// IntegrationTests.swift
// ChordTransposerEngineTests

import XCTest
@testable import ChordTransposerEngine

final class IntegrationTests: XCTestCase {
    let engine = ChordTransposerEngine()

    // MARK: - Full Parse → Transpose → Render Pipeline

    func testFullPipelineSimpleSong() {
        let input = """
        [Verse 1]
        Am    G    F    C
        Amazing grace how sweet the sound

        [Chorus]
        F    C    G    Am
        That saved a wretch like me
        """

        let song = engine.parse(text: input)

        // Verify structure
        let lineTypes = song.lines.map { line -> String in
            switch line {
            case .chordLine: return "chord"
            case .lyricLine: return "lyric"
            case .mixed: return "mixed"
            case .empty: return "empty"
            case .directive: return "directive"
            }
        }

        XCTAssertEqual(lineTypes, [
            "directive",   // [Verse 1]
            "chord",       // Am G F C
            "lyric",       // Amazing grace...
            "empty",       // blank line
            "directive",   // [Chorus]
            "chord",       // F C G Am
            "lyric"        // That saved...
        ])

        // Transpose up by 2 (Am → Bm, G → A, F → G, C → D)
        let result = engine.transpose(song, by: 2, preference: .sharps)
        let output = result.renderText()

        XCTAssertTrue(output.contains("Bm"), "Expected Bm: \(output)")
        XCTAssertTrue(output.contains("[Verse 1]"), "Directives preserved")
        XCTAssertTrue(output.contains("Amazing grace"), "Lyrics preserved")
    }

    func testBracketedNotation() {
        let input = "[Am]Amazing [G]grace, how [F]sweet the [C]sound"

        let song = engine.parse(text: input)

        // Should be a single mixed line
        XCTAssertEqual(song.lines.count, 1)
        if case .mixed(let tokens) = song.lines[0] {
            let chordCount = tokens.filter {
                if case .chord = $0 { return true }
                return false
            }.count
            XCTAssertEqual(chordCount, 4)
        } else {
            XCTFail("Expected .mixed line")
        }

        // Transpose
        let result = engine.transpose(song, by: 3, preference: .flats)
        let output = result.renderText()

        XCTAssertTrue(output.contains("Cm"), "Expected Cm: \(output)")
        XCTAssertTrue(output.contains("Amazing"), "Lyrics preserved: \(output)")
    }

    func testRealWorldSong() {
        let input = """
        [Intro]
        Em    C    G    D

        [Verse 1]
        Em           C
        When the night has come
        G                D
        And the land is dark

        [Chorus]
        G       Em
        Stand by me
        C    D    G
        Stand by me
        """

        let song = engine.parse(text: input)
        XCTAssertFalse(song.metadata.uniqueChords.isEmpty, "Should find chords")

        // Transpose up 5 semitones (Em → Am, C → F, G → C, D → G)
        let result = engine.transpose(song, by: 5, preference: .sharps)
        let output = result.renderText()

        XCTAssertTrue(output.contains("Am"), "Expected Am: \(output)")
        XCTAssertTrue(output.contains("When the night has come"), "Lyrics preserved")
        XCTAssertTrue(output.contains("[Intro]"), "Directives preserved")
        XCTAssertTrue(output.contains("[Verse 1]"), "Directives preserved")
        XCTAssertTrue(output.contains("[Chorus]"), "Directives preserved")
    }

    // MARK: - Spacing Preservation

    func testSpacingPreservation() {
        let input = "Am    G    F    C"
        let song = engine.parse(text: input)
        let result = engine.transpose(song, by: 0, preference: .sharps)
        let output = result.renderText()

        // With 0 transposition, output should match input
        XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines),
                       input.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Metadata

    func testUniqueChordExtraction() {
        let input = """
        Am  G  F  C
        Am  G  F  C
        Dm  Am  G  C
        """

        let song = engine.parse(text: input)
        let unique = engine.uniqueChords(in: song)
        let uniqueNames = unique.map { $0.originalText }

        XCTAssertEqual(uniqueNames, ["Am", "G", "F", "C", "Dm"],
            "Should deduplicate and preserve first-appearance order")
    }

    func testCapoDetection() {
        let input = """
        Capo 3

        Am  G  C  F
        """

        let song = engine.parse(text: input)
        XCTAssertEqual(song.metadata.capo, 3)
    }

    // MARK: - Edge Cases

    func testEmptyInput() {
        let song = engine.parse(text: "")
        XCTAssertEqual(song.lines.count, 1) // One empty line
        let result = engine.transpose(song, by: 5, preference: .sharps)
        let output = result.renderText()
        XCTAssertEqual(output, "")
    }

    func testOnlyChordsNoLyrics() {
        let input = """
        Am  G  F  C
        Dm  Em  F  G
        """

        let result = engine.transposeText(input, by: 2, preference: .sharps)
        let output = result.renderText()
        XCTAssertTrue(output.contains("Bm"))
        XCTAssertTrue(output.contains("A"))
    }

    func testOnlyLyricsNoChords() {
        let input = """
        Amazing grace how sweet the sound
        That saved a wretch like me
        """

        let result = engine.transposeText(input, by: 5, preference: .sharps)
        let output = result.renderText()
        XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines),
                       input.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testComplexChordProgression() {
        let input = "Cmaj7  Am7  Dm7  G7  C7#9  Fmaj7  Bbm7b5  Em/B"

        let song = engine.parse(text: input)

        // Verify all chords parsed
        if case .chordLine(let tokens) = song.lines[0] {
            let chordCount = tokens.filter {
                if case .chord = $0 { return true }
                return false
            }.count
            XCTAssertEqual(chordCount, 8, "Should parse all 8 chords")
        } else {
            XCTFail("Expected chord line")
        }

        // Transpose and verify no crash
        let result = engine.transpose(song, by: 7, preference: .flats)
        XCTAssertFalse(result.renderText().isEmpty)
    }

    // MARK: - Sendable / Concurrency Safety

    func testConcurrentTransposition() async {
        let input = """
        Am    G    F    C
        Amazing grace how sweet the sound
        """
        let song = engine.parse(text: input)

        await withTaskGroup(of: String.self) { group in
            for offset in -6...6 {
                group.addTask {
                    let result = self.engine.transpose(song, by: offset, preference: .sharps)
                    return result.renderText()
                }
            }

            var results: [String] = []
            for await result in group {
                results.append(result)
            }

            XCTAssertEqual(results.count, 13, "All 13 transpositions should complete")
        }
    }
}
