// KeyDetector.swift
// ChordTransposerEngine

import Foundation

/// Protocol for detecting the musical key from a set of chords.
public protocol KeyDetecting: Sendable {
    func detectKey(from chords: [Chord]) -> [DetectedKey]
}

/// Key detector using the Krumhansl-Schmuckler algorithm.
/// Correlates observed pitch-class frequency against major/minor key profiles.
public struct KeyDetector: KeyDetecting, Sendable {

    public init() {}

    // MARK: - Krumhansl-Kessler Key Profiles

    /// Major key profile (Krumhansl-Kessler weights for each scale degree).
    /// Index 0 = tonic, 1 = semitone above tonic, etc.
    private static let majorProfile: [Double] = [
        6.35, 2.23, 3.48, 2.33, 4.38, 4.09,
        2.52, 5.19, 2.39, 3.66, 2.29, 2.88
    ]

    /// Minor key profile (Krumhansl-Kessler).
    private static let minorProfile: [Double] = [
        6.33, 2.68, 3.52, 5.38, 2.60, 3.53,
        2.54, 4.75, 3.98, 2.69, 3.34, 3.17
    ]

    // MARK: - Detection

    public func detectKey(from chords: [Chord]) -> [DetectedKey] {
        guard !chords.isEmpty else { return [] }

        // Build a pitch-class histogram from chord roots and bass notes
        var histogram = [Double](repeating: 0, count: 12)

        for chord in chords {
            // Root note gets full weight
            histogram[chord.root.note.rawValue] += 2.0

            // Bass note gets some weight
            if let bass = chord.bass {
                histogram[bass.note.rawValue] += 1.0
            }

            // Add implicit chord tones based on quality
            let impliedPitches = impliedPitchClasses(root: chord.root.note, quality: chord.quality)
            for pitch in impliedPitches {
                histogram[pitch.rawValue] += 0.5
            }
        }

        // Correlate against all 24 major/minor keys
        var candidates: [DetectedKey] = []

        for rootValue in 0..<12 {
            guard let root = Note(rawValue: rootValue) else { continue }

            let majorCorr = pearsonCorrelation(
                histogram,
                Self.rotatedProfile(Self.majorProfile, by: rootValue)
            )
            let minorCorr = pearsonCorrelation(
                histogram,
                Self.rotatedProfile(Self.minorProfile, by: rootValue)
            )

            candidates.append(DetectedKey(root: root, mode: .major, confidence: majorCorr))
            candidates.append(DetectedKey(root: root, mode: .minor, confidence: minorCorr))
        }

        // Sort by confidence descending
        candidates.sort { $0.confidence > $1.confidence }

        // Normalize confidence to 0...1 range
        if let maxConf = candidates.first?.confidence,
           let minConf = candidates.last?.confidence,
           maxConf != minConf {
            candidates = candidates.map { key in
                let normalized = (key.confidence - minConf) / (maxConf - minConf)
                return DetectedKey(root: key.root, mode: key.mode, confidence: normalized)
            }
        }

        return candidates
    }

    // MARK: - Helpers

    /// Rotate a profile so that index 0 corresponds to the given root.
    private static func rotatedProfile(_ profile: [Double], by offset: Int) -> [Double] {
        let n = profile.count
        return (0..<n).map { profile[($0 - offset + n) % n] }
    }

    /// Compute Pearson correlation coefficient between two vectors.
    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        let n = Double(x.count)
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        var numerator = 0.0
        var denomX = 0.0
        var denomY = 0.0

        for i in 0..<x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            numerator += dx * dy
            denomX += dx * dx
            denomY += dy * dy
        }

        let denom = (denomX * denomY).squareRoot()
        guard denom > 0 else { return 0 }
        return numerator / denom
    }

    /// Return the implied pitch classes for a chord's quality (excluding the root).
    private func impliedPitchClasses(root: Note, quality: ChordQuality) -> [Note] {
        let intervals: [Int]
        switch quality {
        case .major, .dominant:
            intervals = [4, 7]       // major third, perfect fifth
        case .minor:
            intervals = [3, 7]       // minor third, perfect fifth
        case .diminished:
            intervals = [3, 6]       // minor third, diminished fifth
        case .augmented:
            intervals = [4, 8]       // major third, augmented fifth
        case .suspendedSecond:
            intervals = [2, 7]       // major second, perfect fifth
        case .suspendedFourth:
            intervals = [5, 7]       // perfect fourth, perfect fifth
        case .halfDiminished:
            intervals = [3, 6, 10]   // minor third, dim fifth, minor seventh
        case .power:
            intervals = [7]          // perfect fifth only
        }

        return intervals.map { root.transposed(by: $0) }
    }
}
