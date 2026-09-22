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
    @EnvironmentObject private var purchases: PurchaseManager

    var body: some View {
        List {
            Section("Integrated practical labs") {
                ForEach(profile.simulations) { type in
                    NavigationLink {
                        integratedLabDestination(
                            for: type, curriculum: profile.curriculum,
                            repository: AttemptRepository(modelContext: modelContext),
                            purchases: purchases
                        )
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
                    advancedLabDestination(for: .qualitativeUnknown, curriculum: profile.curriculum, purchases: purchases)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Image(systemName: "testtube.2").foregroundStyle(.purple); Text("Unknown Sample Laboratory").font(.headline) }
                        Text("Multi-step QA: choose reagent → observe → add excess → conclude. Full cation, anion and gas test set.").font(.caption).foregroundStyle(.secondary)
                        Text("Exam-realistic workflow").font(.caption2.weight(.semibold)).foregroundStyle(.purple)
                    }.padding(.vertical, 5)
                }

                NavigationLink {
                    advancedLabDestination(for: .waterOfCrystallisation, curriculum: profile.curriculum, purchases: purchases)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack { Image(systemName: "drop.degreesign.fill").foregroundStyle(.teal); Text("Water of Crystallisation").font(.headline) }
                        Text("Heat a hydrated salt to constant mass and calculate x in CuSO₄·xH₂O.").font(.caption).foregroundStyle(.secondary)
                        Text("Heating · weighing · mole ratio").font(.caption2.weight(.semibold)).foregroundStyle(.teal)
                    }.padding(.vertical, 5)
                }

                NavigationLink {
                    advancedLabDestination(for: .saltPreparation, curriculum: profile.curriculum, purchases: purchases)
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

