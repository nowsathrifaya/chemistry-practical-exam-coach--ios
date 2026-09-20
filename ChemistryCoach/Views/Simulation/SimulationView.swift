//
//  SimulationView.swift
//  ChemistryCoach
//
//  Lists all practical simulations — the 8 integrated ChemistryPracticalLabView
//  types plus the standalone advanced simulations (QA Lab, Water of
//  Crystallisation, Salt Preparation).
//

import SwiftUI

struct SimulationListView: View {
    let profile: CurriculumProfile
    @Environment(\.modelContext) private var modelContext
    @StateObject private var purchases = PurchaseManager()

    var body: some View {
        List {
            Section("Integrated practical labs") {
                ForEach(profile.simulations) { type in
                    NavigationLink {
                        if type == .titration || purchases.isPremium {
                            ChemistryPracticalLabView(type: type, curriculum: profile.curriculum, repository: AttemptRepository(modelContext: modelContext))
                        } else {
                            PremiumPaywallView(purchases: purchases)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack { Image(systemName: icon(for: type)).foregroundStyle(.tint); Text(type.label).font(.headline) }
                            Text(type.descriptionText).font(.caption).foregroundStyle(.secondary)
                            Text("Virtual lab · prepare → perform → measure → analyse").font(.caption2.weight(.semibold)).foregroundStyle(.tint)
                        }.padding(.vertical, 5)
                    }
                }
            }

            Section("Advanced simulations") {
                NavigationLink {
                    QualitativeAnalysisLabView(curriculum: profile.curriculum)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Image(systemName: "testtube.2").foregroundStyle(.purple); Text("Unknown Sample Laboratory").font(.headline) }
                        Text("Multi-step QA: choose reagent → observe → add excess → conclude. Full cation, anion and gas test set.").font(.caption).foregroundStyle(.secondary)
                        Text("Exam-realistic workflow").font(.caption2.weight(.semibold)).foregroundStyle(.purple)
                    }.padding(.vertical, 5)
                }

                NavigationLink {
                    WaterOfCrystallisationView(curriculum: profile.curriculum)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Image(systemName: "drop.degreesign.fill").foregroundStyle(.teal); Text("Water of Crystallisation").font(.headline) }
                        Text("Heat a hydrated salt to constant mass and calculate x in CuSO₄·xH₂O.").font(.caption).foregroundStyle(.secondary)
                        Text("Heating · weighing · mole ratio").font(.caption2.weight(.semibold)).foregroundStyle(.teal)
                    }.padding(.vertical, 5)
                }

                NavigationLink {
                    SaltPreparationView(curriculum: profile.curriculum)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Image(systemName: "cylinder.split.50percent").foregroundStyle(.orange); Text("Salt Preparation").font(.headline) }
                        Text("Decision tree: identify solubility → choose method → execute procedure for 6 different salts.").font(.caption).foregroundStyle(.secondary)
                        Text("Precipitation · excess method · titration").font(.caption2.weight(.semibold)).foregroundStyle(.orange)
                    }.padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("Practical Labs")
        .task { await purchases.refresh() }
    }

    private func icon(for type: SimulationType) -> String {
        switch type {
        case .titration: return "drop.triangles.fill"
        case .qualitativeAnalysis: return "testtube.2"
        case .rateReaction: return "timer"
        case .electrolysis: return "bolt.fill"
        case .chromatography: return "rectangle.split.3x1"
        case .energetics: return "thermometer.sun.fill"
        case .separation: return "line.3.horizontal.decrease"
        case .solubility: return "snowflake"
        }
    }
}

// Kept as a compatibility wrapper for Continue Learning routes created by older builds.
struct ChemistrySimulationView: View {
    let type: SimulationType
    let repository: AttemptRepository
    let curriculum: Curriculum
    var body: some View {
        ChemistryPracticalLabView(type: type, curriculum: curriculum, repository: repository)
    }
}
