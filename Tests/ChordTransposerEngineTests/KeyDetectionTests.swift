// KeyDetectionTests.swift
// ChordTransposerEngineTests

import XCTest
@testable import ChordTransposerEngine

final class KeyDetectionTests: XCTestCase {
    let engine = ChordTransposerEngine()

    func testDetectCMajor() {
        // Classic I-IV-V-I in C: C F G C
        let song = engine.parse(text: "C  F  G  C\nC  F  G  C\nC  Am  F  G")
        let key = engine.detectKey(of: song)
        XCTAssertNotNil(key)
        XCTAssertEqual(key?.root, .c)
        XCTAssertEqual(key?.mode, .major)
    }

    func testDetectGMajor() {
        // I-IV-V in G: G C D G
        let song = engine.parse(text: "G  C  D  G\nEm  C  D  G\nG  C  D  G")
        let key = engine.detectKey(of: song)
        XCTAssertNotNil(key)
        XCTAssertEqual(key?.root, .g)
    }

    func testDetectAMinor() {
        // Am Dm E Am — classic minor progression
        let song = engine.parse(text: "Am  Dm  E  Am\nAm  Dm  E  Am\nAm  F  G  Am")
        let key = engine.detectKey(of: song)
        XCTAssertNotNil(key)
        // Am and C major share the same pitch set, so either is acceptable.
        let rootIsA = key?.root == .a && key?.mode == .minor
        let rootIsC = key?.root == .c && key?.mode == .major
        XCTAssertTrue(rootIsA || rootIsC, "Expected Am or C, got \(String(describing: key))")
    }

    func testEmptySongReturnsNilKey() {
        let song = engine.parse(text: "")
        let key = engine.detectKey(of: song)
        XCTAssertNil(key)
    }

    func testKeyConfidenceIsNormalized() {
        let song = engine.parse(text: "C  Am  F  G\nC  Am  F  G")
        let key = engine.detectKey(of: song)
        if let confidence = key?.confidence {
            XCTAssertGreaterThanOrEqual(confidence, 0.0)
            XCTAssertLessThanOrEqual(confidence, 1.0)
        }
    }
}
