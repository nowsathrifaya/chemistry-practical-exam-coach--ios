import Foundation

struct LabReading: Identifiable, Hashable {
    let id = UUID()
    let trialNumber: Int
    let label: String
    let value: Double
    let unit: String
    var derivedLabel: String? = nil
    var derivedValue: Double? = nil
    var derivedUnit: String? = nil
}

/// One line item in a per-skill mark breakdown (Section 18 of the practical
/// realism upgrade — scoring individual practical skills rather than only a
/// final answer).
struct PracticalSkillMark: Identifiable, Hashable {
    var id: String { skill }
    let skill: String
    let scored: Int
    let outOf: Int
}

/// A single logged mistake with an explanation of its practical consequence,
/// rather than a bare "wrong answer" (Section 15, Experiment Mistake Engine).
struct PracticalMistake: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let consequence: String
}

struct LabRunResult {
    let correct: Bool
    let score: Int
    let feedback: [String]
    let examTip: String
    /// Optional per-skill mark breakdown. Empty for simulations that have not
    /// yet been migrated to skill-based scoring.
    var skillMarks: [PracticalSkillMark] = []
    /// Mistakes made during this attempt, each with its practical consequence.
    var mistakes: [PracticalMistake] = []
}
