//
//  CurriculumPickerView.swift
//  ChemistryCoach
//
//  Replaces `CurriculumFragment` / `fragment_curriculum.xml`. Presented
//  full-screen on first launch (onboarding) and reachable again from
//  Settings ("Change curriculum") — the `isOnboarding` flag controls whether
//  it's shown as the root view or pushed/sheeted from Settings.
//

import SwiftUI
import SwiftData

struct CurriculumPickerView: View {
    let homeViewModel: HomeViewModel
    var isOnboarding: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Choose your curriculum")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Built specifically for the Singapore-Cambridge O-Level Chemistry practical examination.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, isOnboarding ? 32 : 8)

                LazyVStack(spacing: 14) {
                    ForEach([Curriculum.singapore]) { curriculum in
                        let profile = CurriculumProfiles.forCurriculum(curriculum)
                        Button {
                            homeViewModel.saveCurriculum(curriculum) {
                                if !isOnboarding { dismiss() }
                            }
                        } label: {
                            CurriculumCard(profile: profile)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isOnboarding ? "" : "Curriculum")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CurriculumCard: View {
    let profile: CurriculumProfile

    var body: some View {
        HStack(spacing: 16) {
            Text(profile.flagEmoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.homeHeadlineLine1)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(profile.paperSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(profile.levelTag)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.15), in: Capsule())
                .foregroundStyle(Color.accentColor)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        CurriculumPickerView(
            homeViewModel: HomeViewModel(
                preferences: UserPreferencesStore(),
                attemptRepository: AttemptRepository(modelContext: ModelContainer.preview.mainContext)
            ),
            isOnboarding: true
        )
    }
}
