//
//  CalculationPracticeView.swift
//  ChemistryCoach
//
//  Interactive calculation practice using CalculationPracticeLibrary data.
//  Students attempt a calculation, then reveal the worked solution.
//

import SwiftUI

struct CalculationPracticeView: View {
    @State private var selectedTopic: String? = nil
    @State private var revealedAnswers: Set<String> = []
    @State private var userAnswers: [String: String] = [:]

    private var topics: [String] {
        Array(Set(CalculationPracticeLibrary.items.map { $0.topic })).sorted()
    }

    private var filteredItems: [CalculationPracticeItem] {
        if let topic = selectedTopic {
            return CalculationPracticeLibrary.items.filter { $0.topic == topic }
        }
        return CalculationPracticeLibrary.items
    }

    var body: some View {
        List {
            Section {
                Picker("Filter by topic", selection: $selectedTopic) {
                    Text("All topics").tag(String?.none)
                    ForEach(topics, id: \.self) { topic in
                        Text(topic).tag(Optional(topic))
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Questions") {
                ForEach(filteredItems) { item in
                    CalculationQuestionCard(
                        item: item,
                        isRevealed: revealedAnswers.contains(item.id),
                        userAnswer: Binding(
                            get: { userAnswers[item.id] ?? "" },
                            set: { userAnswers[item.id] = $0 }
                        ),
                        onReveal: { revealedAnswers.insert(item.id) },
                        onHide: { revealedAnswers.remove(item.id) }
                    )
                }
            }

            Section {
                Text("Work through each calculation on paper before revealing the solution. These cover titration, gas volumes, energy changes, yield, purity and water of crystallisation — the calculation types most frequently assessed in Paper 3.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Calculation Practice")
    }
}

private struct CalculationQuestionCard: View {
    let item: CalculationPracticeItem
    let isRevealed: Bool
    @Binding var userAnswer: String
    let onReveal: () -> Void
    let onHide: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.topic)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Spacer()
                Text("\(item.id)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(item.question)
                .font(.subheadline)

            TextField("Your answer", text: $userAnswer)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numbersAndPunctuation)

            if isRevealed {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Answer: \(item.answer)")
                            .font(.headline)
                    }

                    Text("Worked solution:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(Array(item.steps.enumerated()), id: \.offset) { _, step in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundStyle(.blue)
                            Text(step)
                                .font(.caption)
                        }
                    }
                }
                .padding(12)
                .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                Button("Hide solution") { onHide() }
                    .font(.caption)
            } else {
                Button("Reveal solution") { onReveal() }
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
    }
}
