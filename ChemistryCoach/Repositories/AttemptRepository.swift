import Foundation
import SwiftData

@MainActor
final class AttemptRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func fetchAttempts() -> [Attempt] {
        do {
            let attempts = try modelContext.fetch(FetchDescriptor<Attempt>())
            return attempts.sorted { $0.completedAt > $1.completedAt }
        } catch {
            assertionFailure("Failed to fetch attempts: \(error)")
            return []
        }
    }

    @discardableResult
    func save(
        curriculum: Curriculum,
        mode: AttemptMode,
        target: String,
        score: Int,
        maxScore: Int,
        feedback: [String],
        skill: PracticalSkill? = nil,
        durationSeconds: Int? = nil,
        hintsUsed: Int? = nil,
        confidence: Int? = nil
    ) -> Bool {
        let now = Date()
        let inferredSkill = skill ?? inferSkill(mode: mode, target: target, feedback: feedback)
        let errorType = ErrorTaxonomy.infer(from: feedback, target: target)
        let attempt = Attempt(
            curriculum: curriculum,
            mode: mode,
            target: target,
            startedAt: now.addingTimeInterval(TimeInterval(-(durationSeconds ?? 180))),
            completedAt: now,
            score: max(0, min(score, maxScore)),
            maxScore: max(0, maxScore),
            feedback: feedback.joined(separator: "\n"),
            skill: inferredSkill,
            errorType: errorType,
            durationSeconds: durationSeconds,
            hintsUsed: hintsUsed,
            confidence: confidence
        )
        modelContext.insert(attempt)
        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.delete(attempt)
            assertionFailure("Failed to save attempt: \(error)")
            return false
        }
    }

    @discardableResult
    func record(_ attempt: Attempt) -> Bool {
        modelContext.insert(attempt)
        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.delete(attempt)
            assertionFailure("Failed to record attempt: \(error)")
            return false
        }
    }

    func summary() -> (count: Int, averageScore: Double) {
        let attempts = fetchAttempts()
        guard !attempts.isEmpty else { return (0, 0.0) }
        let average = Double(attempts.reduce(0) { $0 + $1.score }) / Double(attempts.count)
        return (attempts.count, average)
    }

    @discardableResult
    func resetAllProgress() -> Bool {
        for attempt in fetchAttempts() { modelContext.delete(attempt) }
        do {
            try modelContext.save()
            return true
        } catch {
            assertionFailure("Failed to reset progress: \(error)")
            return false
        }
    }

    private func inferSkill(mode: AttemptMode, target: String, feedback: [String]) -> PracticalSkill {
        let text = (target + " " + feedback.joined(separator: " ")).lowercased()
        if text.contains("planning") || text.contains("controlled variable") || text.contains("independent variable") { return .planning }
        if mode == .apparatusPractice || mode == .simulationLab || text.contains("measure") || text.contains("titration") { return .mmo }
        if mode == .graphCoach || text.contains("graph") || text.contains("data presentation") || text.contains("observation") { return .pdo }
        return .ace
    }
}
