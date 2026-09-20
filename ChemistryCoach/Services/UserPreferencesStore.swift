//
//  UserPreferencesStore.swift
//  ChemistryCoach
//
//  Port of `data.local.datastore.UserPreferencesStore.kt`. Android used
//  Jetpack DataStore for two small keys; the idiomatic, equally-persistent
//  iOS equivalent for a couple of lightweight preference values is
//  UserDefaults, wrapped behind the same narrow protocol the Kotlin file
//  defined so view models stay testable with a fake.
//

import Foundation
import Combine

protocol UserPreferences {
    var selectedCurriculumPublisher: AnyPublisher<Curriculum?, Never> { get }
    var hasCompletedOnboardingPublisher: AnyPublisher<Bool, Never> { get }
    var selectedCurriculum: Curriculum? { get }
    var hasCompletedOnboarding: Bool { get }
    func saveCurriculum(_ curriculum: Curriculum)
}

final class UserPreferencesStore: UserPreferences, ObservableObject {
    private enum Keys {
        static let curriculum = "selected_curriculum"
        static let onboarded = "has_completed_onboarding"
    }

    private let defaults: UserDefaults

    @Published private(set) var selectedCurriculum: Curriculum?
    @Published private(set) var hasCompletedOnboarding: Bool

    var selectedCurriculumPublisher: AnyPublisher<Curriculum?, Never> {
        $selectedCurriculum.eraseToAnyPublisher()
    }

    var hasCompletedOnboardingPublisher: AnyPublisher<Bool, Never> {
        $hasCompletedOnboarding.eraseToAnyPublisher()
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Keys.curriculum) {
            self.selectedCurriculum = Curriculum(rawValue: raw)
        } else {
            self.selectedCurriculum = nil
        }
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarded)
    }

    func saveCurriculum(_ curriculum: Curriculum) {
        defaults.set(curriculum.rawValue, forKey: Keys.curriculum)
        defaults.set(true, forKey: Keys.onboarded)
        selectedCurriculum = curriculum
        hasCompletedOnboarding = true
    }
}
