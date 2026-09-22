import Foundation

struct SkillReadiness: Identifiable, Hashable {
    let skill: PracticalSkill
    let score: Int?
    let evidenceCount: Int
    let detail: String
    var id: String { skill.rawValue }
}

struct PracticalReadiness: Hashable {
    let skills: [SkillReadiness]
    let overall: Int?
    let weakest: SkillReadiness?

    var hasEnoughEvidence: Bool { skills.contains { $0.score != nil } }
}

enum PracticalReadinessCalculator {
    static func compute(attempts: [Attempt], curriculum: Curriculum) -> PracticalReadiness {
        let relevant = attempts.filter { $0.curriculumValue == curriculum && $0.maxScore > 0 }
        let skills = PracticalSkill.allCases.map { skill in
            let matched = relevant.filter { inferredSkill(for: $0) == skill }
            guard !matched.isEmpty else {
                return SkillReadiness(skill: skill, score: nil, evidenceCount: 0, detail: "No evidence yet")
            }
            let weighted = matched.map { attempt -> Double in
                let ratio = min(1, max(0, Double(attempt.score) / Double(attempt.maxScore)))
                // Recent work gets slightly more weight without allowing one
                // attempt to dominate the readiness score.
                let ageDays = max(0, Date().timeIntervalSince(attempt.completedAt) / 86_400)
                return ratio * max(0.55, 1.0 - min(ageDays / 60.0, 0.45))
            }
            let weights: [Double] = matched.map { attempt in
                let ageDays = max(0.0, Date().timeIntervalSince(attempt.completedAt) / 86_400.0)
                return max(0.55, 1.0 - min(ageDays / 60.0, 0.45))
            }
            let totalWeight: Double = weights.reduce(0.0) { partial, value in
                partial + value
            }
            let weightedTotal: Double = weighted.reduce(0.0) { partial, value in
                partial + value
            }
            let value = totalWeight > 0.0
                ? Int((weightedTotal / totalWeight * 100.0).rounded())
                : 0
            return SkillReadiness(skill: skill, score: value, evidenceCount: matched.count, detail: "Based on \(matched.count) recent practice result\(matched.count == 1 ? "" : "s")")
        }
        let scored = skills.compactMap { $0.score }
        let overall = scored.isEmpty ? nil : Int((Double(scored.reduce(0, +)) / Double(scored.count)).rounded())
        let scoredSkills: [SkillReadiness] = skills.filter { item in
            item.score != nil
        }
        let weakest: SkillReadiness? = scoredSkills.min { lhs, rhs in
            let lhsScore = lhs.score ?? Int.max
            let rhsScore = rhs.score ?? Int.max
            return lhsScore < rhsScore
        }
        return PracticalReadiness(skills: skills, overall: overall, weakest: weakest)
    }

    private static func inferredSkill(for attempt: Attempt) -> PracticalSkill {
        if let explicit = attempt.skillValue { return explicit }
        let text = "\(attempt.target) \(attempt.feedback)".lowercased()
        if text.contains("planning") || text.contains("plan") || text.contains("variable") { return .planning }
        if attempt.modeValue == .apparatusPractice || attempt.modeValue == .simulationLab || text.contains("measure") || text.contains("apparatus") || text.contains("titration") { return .mmo }
        if attempt.modeValue == .graphCoach || text.contains("graph") || text.contains("data") || text.contains("observation") { return .pdo }
        return .ace
    }
}
