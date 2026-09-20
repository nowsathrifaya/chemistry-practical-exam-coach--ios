//
//  AttemptRepository.swift
//  ChemistryCoach
//
//  Port of `data.repository.AttemptRepository.kt`. Wraps a SwiftData
//  `ModelContext` the same way the Kotlin class wrapped an `AttemptDao`,
//  keeping ViewModels free of any direct persistence-framework imports.
//

import Foundation
import SwiftData

@MainActor
final class AttemptRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// All attempts, most recently completed first — the fetch equivalent of
    /// `AttemptDao.observeAttempts()`. SwiftData has no long-lived Flow
    /// equivalent tied to a repository, so views re-fetch via `@Query` or call
    /// this after a mutation; see `ProgressViewModel` for the pattern used.
    func fetchAttempts() -> [Attempt] {
        let descriptor = FetchDescriptor<Attempt>()
        let attempts = (try? modelContext.fetch(descriptor)) ?? []
        return attempts.sorted { $0.completedAt > $1.completedAt }
    }

    func save(
        curriculum: Curriculum,
        mode: AttemptMode,
        target: String,
        score: Int,
        maxScore: Int,
        feedback: [String]
    ) {
        let now = Date()
        let attempt = Attempt(
            curriculum: curriculum,
            mode: mode,
            target: target,
            startedAt: now.addingTimeInterval(-180),
            completedAt: now,
            score: score,
            maxScore: maxScore,
            feedback: feedback.joined(separator: "\n")
        )
        modelContext.insert(attempt)
        try? modelContext.save()
    }

    func record(_ attempt: Attempt) {
        modelContext.insert(attempt)
        try? modelContext.save()
    }

    /// (count, averageScore) — matches `AttemptRepository.summary()`.
    func summary() -> (count: Int, averageScore: Double) {
        let attempts = fetchAttempts()
        guard !attempts.isEmpty else { return (0, 0.0) }
        let average = Double(attempts.reduce(0) { $0 + $1.score }) / Double(attempts.count)
        return (attempts.count, average)
    }

    func resetAllProgress() {
        for attempt in fetchAttempts() {
            modelContext.delete(attempt)
        }
        try? modelContext.save()
    }
}
