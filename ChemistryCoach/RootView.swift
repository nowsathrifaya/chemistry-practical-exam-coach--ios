//
//  RootView.swift
//  ChemistryCoach
//
//  Replaces the Navigation Component's start-destination logic
//  (`nav_graph.xml`: curriculumFragment -> homeFragment). Shows the
//  curriculum picker on first launch, then the 5-tab shell.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.userPreferences) private var preferences
    @State private var homeViewModel: HomeViewModel?

    var body: some View {
        Group {
            if let homeViewModel {
                if homeViewModel.onboardingComplete == true {
                    MainTabView(homeViewModel: homeViewModel)
                } else {
                    CurriculumPickerView(homeViewModel: homeViewModel, isOnboarding: true)
                }
            } else {
                ProgressView()
            }
        }
        .task {
            if homeViewModel == nil {
                let repository = AttemptRepository(modelContext: modelContext)
                homeViewModel = HomeViewModel(preferences: preferences, attemptRepository: repository)
            }
        }
    }
}

/// The 5-tab shell replacing `bottom_nav_menu.xml`: Home / Learn / Practice / Progress / Settings.
struct MainTabView: View {
    @Bindable var homeViewModel: HomeViewModel

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(homeViewModel: homeViewModel)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                StudyNotesListView(curriculum: homeViewModel.curriculum)
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink { CurriculumAcademyView() } label: { Label("Practical Academy", systemImage: "flask") } } }
            }
            .tabItem { Label("Learn", systemImage: "book.fill") }

            NavigationStack {
                PracticeHubView(homeViewModel: homeViewModel)
            }
            .tabItem { Label("Practice", systemImage: "target") }

            NavigationStack {
                ProgressScreenView(homeViewModel: homeViewModel)
            }
            .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            NavigationStack {
                SettingsView(homeViewModel: homeViewModel)
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Attempt.self, inMemory: true)
}
