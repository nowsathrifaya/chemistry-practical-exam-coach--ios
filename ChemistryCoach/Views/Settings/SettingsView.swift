//
//  SettingsView.swift
//  ChemistryCoach
//
//  Replaces `SettingsFragment`. Curriculum switcher, reset-progress action,
//  and app info — laid out as a native grouped Settings-style list.
//

import SwiftUI

struct SettingsView: View {
    let homeViewModel: HomeViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showResetConfirmation = false
    @State private var soundEffectsEnabled = true

    var body: some View {
        List {
            Section("Curriculum") {
                NavigationLink {
                    CurriculumPickerView(homeViewModel: homeViewModel, isOnboarding: false)
                } label: {
                    HStack {
                        Text("Current curriculum")
                        Spacer()
                        Text(CurriculumProfiles.forCurriculum(homeViewModel.curriculum).homeHeadlineLine1)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Feedback") {
                Toggle("Sound effects", isOn: $soundEffectsEnabled)
                    .onChange(of: soundEffectsEnabled) { _, newValue in
                        SoundManager.shared.isEnabled = newValue
                        if newValue {
                            SoundManager.shared.play(.tap)
                        }
                    }
            }

            Section("Data") {
                Button("Reset all progress", role: .destructive) {
                    showResetConfirmation = true
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.appVersionString).foregroundStyle(.secondary)
                }
                Text("All practice questions and simulations are generated on-device \u{2014} no account or internet connection required.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            soundEffectsEnabled = SoundManager.shared.isEnabled
        }
        .alert("Reset all progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                AttemptRepository(modelContext: modelContext).resetAllProgress()
                homeViewModel.refreshStats()
            }
        } message: {
            Text("This deletes every recorded attempt. This action cannot be undone.")
        }
    }
}

extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
