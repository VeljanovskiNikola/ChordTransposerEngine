// LineClassifierTests.swift
// ChordTransposerEngineTests

import XCTest
@testable import ChordTransposerEngine

final class LineClassifierTests: XCTestCase {
    let engine = ChordTransposerEngine()

    // MARK: - Empty Lines

    func testEmptyLine() {
        let result = engine.parseLine("")
        if case .empty = result {
            // pass
        } else {
            XCTFail("Expected .empty, got \(result)")
        }
    }

    func testWhitespaceLine() {
        let result = engine.parseLine("   \t  ")
        if case .empty = result {
            // pass
        } else {
            XCTFail("Expected .empty, got \(result)")
        }
    }

    // MARK: - Chord Lines

    func testChordOnlyLine() {
        let result = engine.parseLine("Am    G    F    C")
        if case .chordLine(let tokens) = result {
            let chordCount = tokens.filter {
                if case .chord = $0 { return true }
                return false
            }.count
            XCTAssertEqual(chordCount, 4)
        } else {
            XCTFail("Expected .chordLine, got \(result)")
        }
    }

    func testSingleChord() {
        let result = engine.parseLine("Am")
        if case .chordLine(let tokens) = result {
            let chordCount = tokens.filter {
                if case .chord = $0 { return true }
                return false
            }.count
            XCTAssertEqual(chordCount, 1)
        } else {
            XCTFail("Expected .chordLine, got \(result)")
        }
    }

    // MARK: - Lyric Lines

    func testPureLyricLine() {
        let result = engine.parseLine("Amazing grace how sweet the sound")
        if case .lyricLine(let text) = result {
            XCTAssertEqual(text, "Amazing grace how sweet the sound")
        } else {
            XCTFail("Expected .lyricLine, got \(result)")
        }
    }

    func testLyricWithArticleA() {
        let result = engine.parseLine("I am a believer in the power of love")
        if case .lyricLine = result {
            // pass — "a" should not be parsed as a chord here
        } else {
            XCTFail("Expected .lyricLine, got \(result)")
        }
    }

    // MARK: - Directives

    func testBracketedVerseDirective() {
        let result = engine.parseLine("[Verse 1]")
        if case .directive(let text) = result {
            XCTAssertEqual(text, "[Verse 1]")
        } else {
            XCTFail("Expected .directive, got \(result)")
        }
    }

    func testBracketedChorusDirective() {
        let result = engine.parseLine("[Chorus]")
        if case .directive = result {
            // pass
        } else {
            XCTFail("Expected .directive, got \(result)")
        }
    }

    func testCapoDirective() {
        let result = engine.parseLine("Capo 3")
        if case .directive = result {
            // pass
        } else {
            XCTFail("Expected .directive, got \(result)")
        }
    }

    func testKeyDirective() {
        let result = engine.parseLine("Key: Am")
        if case .directive = result {
            // pass
        } else {
            XCTFail("Expected .directive, got \(result)")
        }
    }

    func testCommentDirective() {
        let result = engine.parseLine("// This is a bridge")
        if case .directive = result {
            // pass
        } else {
            XCTFail("Expected .directive, got \(result)")
        }
    }

    func testVerseColonDirective() {
        let result = engine.parseLine("Verse 1:")
        if case .directive = result {
            // pass
        } else {
            XCTFail("Expected .directive, got \(result)")
        }
    }

    // MARK: - Mixed Lines (Bracketed Notation)

    func testBracketedChordNotation() {
        let result = engine.parseLine("[Am]Amazing [G]grace")
        if case .mixed(let tokens) = result {
            let chordCount = tokens.filter {
                if case .chord = $0 { return true }
                return false
            }.count
            XCTAssertEqual(chordCount, 2)

            let textTokens = tokens.compactMap { token -> String? in
                if case .text(let t) = token { return t }
                return nil
            }
            let joinedText = textTokens.joined()
            XCTAssertTrue(joinedText.contains("Amazing"))
            XCTAssertTrue(joinedText.contains("grace"))
        } else {
            XCTFail("Expected .mixed, got \(result)")
        }
    }

    // MARK: - Disambiguation

    func testAAsChordOnChordLine() {
        // "A  D  E  A" — all should be chords
        let result = engine.parseLine("A  D  E  A")
        if case .chordLine(let tokens) = result {
            let chordCount = tokens.filter {
                if case .chord = $0 { return true }
                return false
            }.count
            XCTAssertEqual(chordCount, 4, "All four tokens should be chords")
        } else {
            XCTFail("Expected .chordLine, got \(result)")
        }
    }

    func testBeIsNotAChord() {
        // "Be" is not a valid chord
        let result = engine.parseLine("Be still my heart")
        if case .lyricLine = result {
            // pass
        } else {
            XCTFail("Expected .lyricLine, got \(result)")
        }
    }
}
