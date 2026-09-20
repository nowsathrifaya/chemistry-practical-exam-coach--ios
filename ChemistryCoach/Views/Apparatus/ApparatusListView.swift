//
//  ApparatusListView.swift
//  ChemistryCoach
//
//  Replaces `ApparatusListFragment`. Lists the instruments relevant to the
//  active curriculum profile.
//

import SwiftUI

struct ApparatusListView: View {
    let profile: CurriculumProfile

    var body: some View {
        List(profile.apparatus) { type in
            NavigationLink {
                ApparatusPracticeContainerView(apparatusType: type, curriculum: profile.curriculum)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.label).font(.headline)
                    Text("Unit: \(type.unit)").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Apparatus Trainer")
    }
}

/// Wraps `ApparatusPracticeView` so it can be pushed from a `NavigationLink`
/// without every caller needing a `HomeViewModel` reference — the practice
/// view resolves its own repository from the environment `modelContext`.
struct ApparatusPracticeContainerView: View {
    let apparatusType: ApparatusType
    let curriculum: Curriculum
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ApparatusPracticeView(
            apparatusType: apparatusType,
            curriculum: curriculum,
            repository: AttemptRepository(modelContext: modelContext)
        )
    }
}
