//
//  ProgressScreenView.swift
//  ChemistryCoach
//
//  Replaces `ProgressFragment`. Named "ProgressScreenView" (not
//  "ProgressView") to avoid colliding with SwiftUI's own `ProgressView`.
//  Shows the same stats as `ProgressViewModel.kt`: streak, points, accuracy,
//  badges, and a weak-areas ranking computed from attempt history.
//

import SwiftUI

struct WeakArea: Identifiable {
    var id: String { target }
    let target: String
    let attemptCount: Int
    let averageAccuracy: Double
}

struct ProgressScreenView: View {
    let homeViewModel: HomeViewModel

    private var weakAreas: [WeakArea] {
        let grouped = Dictionary(grouping: homeViewModel.attempts, by: \.target)
        return grouped.compactMap { target, attempts -> WeakArea? in
            let scored = attempts.filter { $0.maxScore > 0 }
            guard !scored.isEmpty else { return nil }
            let avg = scored.reduce(0.0) { $0 + Double($1.score) / Double($1.maxScore) } / Double(scored.count)
            return WeakArea(target: target, attemptCount: attempts.count, averageAccuracy: avg)
        }
        .sorted { $0.averageAccuracy < $1.averageAccuracy }
    }

    var body: some View {
        List {
            Section {
                let stats = homeViewModel.userStats
                HStack {
                    ProgressStat(value: "\(stats.streakDays)", label: "Day streak")
                    Spacer()
                    ProgressStat(value: "\(stats.totalPoints)", label: "Points")
                    Spacer()
                    ProgressStat(value: "\(stats.accuracyPercent)%", label: "Accuracy")
                    Spacer()
                    ProgressStat(value: "\(stats.masteryPercent)%", label: "Mastery")
                }
                .padding(.vertical, 6)
            }

            Section {
                AdaptiveCoachView(homeViewModel: homeViewModel)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            }

            Section("Badges") {
                let stats = homeViewModel.userStats
                ForEach(stats.badges) { badge in
                    HStack {
                        Text(badge.emoji)
                        Text(badge.label)
                        Spacer()
                        if badge.unlocked {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        } else {
                            Image(systemName: "lock.fill").foregroundStyle(.secondary)
                        }
                    }
                    .opacity(badge.unlocked ? 1.0 : 0.5)
                }
            }

            if !weakAreas.isEmpty {
                Section("Focus areas (lowest accuracy first)") {
                    ForEach(weakAreas.prefix(5)) { area in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(area.target).font(.subheadline)
                            Text("\(area.attemptCount) attempt(s) \u{00B7} \(Int(area.averageAccuracy * 100))% average")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Recent attempts") {
                if homeViewModel.attempts.isEmpty {
                    Text("No attempts yet. Start practicing to see your history here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(homeViewModel.attempts.prefix(20)) { attempt in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attempt.target).font(.subheadline)
                                Text(attempt.completedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(attempt.score)/\(attempt.maxScore)")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
        }
        .navigationTitle("Progress")
        .onAppear { homeViewModel.refreshStats() }
    }
}

private struct ProgressStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack {
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
