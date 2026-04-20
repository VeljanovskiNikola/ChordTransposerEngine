// EnharmonicResolver.swift
// ChordTransposerEngine

/// Protocol for resolving enharmonic spellings.
public protocol EnharmonicResolving: Sendable {
    func resolve(note: Note, preference: EnharmonicPreference, key: DetectedKey?) -> String
}

/// Default enharmonic resolver using key-signature-aware spelling rules.
public struct EnharmonicResolver: EnharmonicResolving, Sendable {

    public init() {}

    public func resolve(
        note: Note,
        preference: EnharmonicPreference,
        key: DetectedKey?
    ) -> String {
        return note.displayString(preference: preference, key: key)
    }

    // MARK: - Key Signature Spelling Logic

    /// Keys that conventionally use flat spellings.
    /// F major, Bb major, Eb major, Ab major, Db major, Gb major
    /// D minor, G minor, C minor, F minor, Bb minor, Eb minor
    private static let flatKeys: Set<Int> = {
        var keys = Set<Int>()
        let flatMajorRoots: [Note] = [.f, .aSharp, .dSharp, .gSharp, .cSharp, .fSharp]
        let flatMinorRoots: [Note] = [.d, .g, .c, .f, .aSharp, .dSharp]
        for root in flatMajorRoots { keys.insert(root.rawValue * 2) }
        for root in flatMinorRoots { keys.insert(root.rawValue * 2 + 1) }
        return keys
    }()

    /// Determine if a key prefers flat spelling.
    internal static func prefersFlatSpelling(key: DetectedKey) -> Bool {
        let encoded = key.root.rawValue * 2 + (key.mode == .minor ? 1 : 0)
        return flatKeys.contains(encoded)
    }
}
