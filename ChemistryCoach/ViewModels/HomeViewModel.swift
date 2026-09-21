//
//  HomeViewModel.swift
//  ChemistryCoach
//
//  Port of `ui.viewmodel.HomeViewModel.kt`. Uses the `@Observable` macro
//  (Swift Observation framework) instead of `StateFlow` — the idiomatic
//  SwiftUI replacement that still gives every view a single source of
//  truth without manual Combine plumbing.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let preferences: UserPreferences
    private let attemptRepository: AttemptRepository

    var curriculum: Curriculum = .singapore
    var onboardingComplete: Bool?
    private(set) var attempts: [Attempt] = []

    /// Every number here is computed live from `attempts`, refreshed via `refreshStats()`.
    var userStats: UserStats {
        UserStatsCalculator.compute(attempts: attempts, profile: CurriculumProfiles.forCurriculum(curriculum))
    }

    init(preferences: UserPreferences, attemptRepository: AttemptRepository) {
        self.preferences = preferences
        self.attemptRepository = attemptRepository
        self.curriculum = preferences.selectedCurriculum ?? .singapore
        self.onboardingComplete = preferences.hasCompletedOnboarding
        refreshStats()
    }

    /// HomeViewModel outlives individual visits to the Home tab, so call this
    /// whenever Home becomes visible again to pick up attempts recorded
    /// elsewhere (matches the Android `onResume` refresh pattern).
    func refreshStats() {
        attempts = attemptRepository.fetchAttempts()
    }

    func saveCurriculum(_ curriculum: Curriculum, onSaved: () -> Void) {
        preferences.saveCurriculum(curriculum)
        self.curriculum = curriculum
        self.onboardingComplete = true
        onSaved()
    }
}
