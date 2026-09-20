//
//  CompleteReferenceView.swift
//  ChemistryCoach
//
//  Unified reference screen combining CompleteUpgradeCatalog (structured
//  exam-skill resources) and PracticalReferenceLibrary (quick-reference
//  tables for solubility, flame tests, gas tests, indicators, etc.).
//

import SwiftUI

struct CompleteReferenceView: View {
    var body: some View {
        List {
            Section("Quick reference tables") {
                ForEach(PracticalReferenceLibrary.items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Exam technique resources") {
                ForEach(CompleteUpgradeCatalog.resources) { resource in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(resource.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            ForEach(resource.items, id: \.self) { item in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 5))
                                        .foregroundStyle(.blue)
                                        .padding(.top, 5)
                                    Text(item)
                                        .font(.footnote)
                                }
                            }
                        }
                    } label: {
                        Text(resource.title)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }

            Section {
                Text("These reference tables mirror the Notes for Qualitative Analysis provided in the actual Paper 3 exam. Memorise the solubility rules, flame test colours, and indicator pH ranges — they are essential for fast, accurate QA work under time pressure.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Practical Reference")
    }
}
