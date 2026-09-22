//
//  AdaptiveCoachView.swift
//  ChemistryCoach
//
//  v5: adaptive next-step coaching driven by persistent attempt history.
//

import SwiftUI
import SwiftData

struct AdaptiveCoachView: View {
    let homeViewModel: HomeViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchases: PurchaseManager

    private var recommendations: [AdaptiveRecommendation] {
        AdaptiveCoach.recommendations(from: homeViewModel.attempts, limit: 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Today's Focus", systemImage: "scope")
                    .font(.headline)
                Spacer()
                Text("Adaptive")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if recommendations.isEmpty {
                Text("Complete a practice activity to unlock targeted recommendations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recommendations) { recommendation in
                    NavigationLink {
                        destination(for: recommendation.action)
                    } label: {
                        RecommendationRow(recommendation: recommendation)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func destination(for action: AdaptiveAction) -> some View {
        let repository = AttemptRepository(modelContext: modelContext)
        switch action {
        case .qualitative:
            advancedLabDestination(for: .qualitativeUnknown, curriculum: homeViewModel.curriculum, purchases: purchases)
        case .calculation:
            CalculationPracticeView()
        case .aceTopic(let topic):
            AcePracticeSessionView(repository: repository, curriculum: homeViewModel.curriculum, filterTopic: topic, filterSkill: nil, isMockExam: false, mockExamMinutes: 10)
        case .aceSkill(let skill):
            AcePracticeSessionView(repository: repository, curriculum: homeViewModel.curriculum, filterTopic: nil, filterSkill: skill, isMockExam: false, mockExamMinutes: 10)
        case .simulation(let type):
            integratedLabDestination(for: type, curriculum: homeViewModel.curriculum, repository: repository, purchases: purchases)
        case .apparatus(let type):
            ApparatusPracticeView(apparatusType: type, curriculum: homeViewModel.curriculum, repository: repository, onSaved: { homeViewModel.refreshStats() })
        case .graph(let type):
            GraphCoachPracticeView(graphType: type, curriculum: homeViewModel.curriculum, repository: repository, onSaved: { homeViewModel.refreshStats() })
        }
    }
}

private struct RecommendationRow: View {
    let recommendation: AdaptiveRecommendation

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: recommendation.accuracy < 70 ? "arrow.down.right" : "arrow.up.right")
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(recommendation.title).font(.subheadline.weight(.semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    if let error = recommendation.commonError {
                        Text("Pattern: \(error)").font(.caption2.weight(.semibold)).foregroundStyle(.orange).lineLimit(1)
                    }
                }
            }

            Spacer()

            if recommendation.attempts > 0 {
                Text("\(recommendation.accuracy)%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(recommendation.accuracy < 70 ? .orange : .green)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
