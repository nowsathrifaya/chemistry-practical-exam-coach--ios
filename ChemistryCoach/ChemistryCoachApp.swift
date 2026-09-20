//
//  ChemistryCoachApp.swift
//  ChemistryCoach
//
//  App entry point. Replaces `ChemistryCoachApplication.kt` + `MainActivity.kt`.
//  Wires up the SwiftData `ModelContainer` (replacing Room's
//  `ChemistryCoachDatabase.get(context)` singleton) and the shared
//  `UserPreferencesStore` (replacing the DataStore singleton), then hands
//  both down through the environment the way `AppContainer.kt` handed them
//  to Android ViewModel factories.
//

import SwiftUI
import SwiftData

@main
struct ChemistryCoachApp: App {
    let modelContainer: ModelContainer
    @State private var preferencesStore = UserPreferencesStore()

    init() {
        do {
            modelContainer = try ModelContainer(for: Attempt.self)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.userPreferences, preferencesStore)
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Environment plumbing for UserPreferences

private struct UserPreferencesKey: EnvironmentKey {
    // The environment default is only ever a placeholder — real screens
    // always receive a concrete store via `.environment(\.userPreferences, ...)`
    // — so it's safe to opt this single global out of Swift 6's Sendable check.
    nonisolated(unsafe) static let defaultValue: UserPreferences = UserPreferencesStore()
}

extension EnvironmentValues {
    var userPreferences: UserPreferences {
        get { self[UserPreferencesKey.self] }
        set { self[UserPreferencesKey.self] = newValue }
    }
}
