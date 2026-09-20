//
//  SeededRandomNumberGenerator.swift
//  ChemistryCoach
//
//  Swift's `Int.random(in:using:)` has no built-in seeded generator the way
//  Kotlin's `kotlin.random.Random(seed)` does. This SplitMix64-based
//  generator gives the same guarantee the Android app relies on: the same
//  seed always produces the same sequence, so a given apparatus/simulation
//  question is fully reproducible from its `seed` field (needed for
//  "regenerate the worked answer" and for deterministic unit tests).
//

import Foundation

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        // Mix the seed so small/sequential seeds (1, 2, 3...) still produce
        // well-distributed output.
        self.state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

extension SeededRandomNumberGenerator {
    /// Mirrors Kotlin's `Random.nextDouble(from, until)`.
    mutating func nextDouble(_ lowerBound: Double, _ upperBound: Double) -> Double {
        let fraction = Double(next() >> 11) * (1.0 / 9007199254740992.0) // 53-bit precision, [0,1)
        return lowerBound + fraction * (upperBound - lowerBound)
    }

    /// Mirrors Kotlin's `Random.nextDouble()` (0.0 until 1.0).
    mutating func nextDouble() -> Double {
        nextDouble(0.0, 1.0)
    }

    /// Mirrors Kotlin's `Random.nextInt(from, until)` — `until` is exclusive.
    mutating func nextInt(_ lowerBound: Int, _ upperBound: Int) -> Int {
        precondition(upperBound > lowerBound, "upperBound must be greater than lowerBound")
        return Int.random(in: lowerBound..<upperBound, using: &self)
    }

    /// Mirrors Kotlin's `Random.nextBoolean()`.
    mutating func nextBoolean() -> Bool {
        next() & 1 == 1
    }

    /// Mirrors Kotlin's `list.random(rng)`.
    mutating func randomElement<T>(_ array: [T]) -> T {
        array[nextInt(0, array.count)]
    }
}
