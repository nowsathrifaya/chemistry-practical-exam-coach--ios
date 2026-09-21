//
//  CalculationPracticeView.swift
//  ChemistryCoach
//
//  Interactive calculation practice using CalculationPracticeLibrary data.
//  v6: "Check answer" now actually marks the student's typed answer against
//  item.answer (previously the reveal button showed the answer regardless
//  of what was typed, with no comparison and nothing recorded). Each check
//  is now logged as an Attempt so calculation practice shows up in progress
//  history like every other practice mode.
//

import SwiftUI
import SwiftData

struct CalculationPracticeView: View {
    let curriculum: Curriculum
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTopic: String? = nil
    @State private var revealedAnswers: Set<String> = []
    @State private var userAnswers: [String: String] = [:]
    @State private var checkedCorrect: [String: Bool] = [:]

    init(curriculum: Curriculum = .general) {
        self.curriculum = curriculum
    }

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
                        isCorrect: checkedCorrect[item.id],
                        userAnswer: Binding(
                            get: { userAnswers[item.id] ?? "" },
                            set: { userAnswers[item.id] = $0; checkedCorrect[item.id] = nil }
                        ),
                        onReveal: { revealedAnswers.insert(item.id) },
                        onHide: { revealedAnswers.remove(item.id) },
                        onCheck: { checkAnswer(for: item) }
                    )
                }
            }

            Section {
                Text("Work through each calculation on paper, then use Check answer to mark your own numeric answer, or reveal the full worked solution. These cover titration, gas volumes, energy changes, yield, purity and water of crystallisation — the calculation types most frequently assessed in Paper 3.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Calculation Practice")
    }

    /// Extracts the first signed decimal number found in a string, so a typed
    /// answer like "0.102" or "75%" can be compared against a stored answer
    /// like "0.102 mol/dm³" or "75.0%" without requiring identical formatting.
    private func extractNumber(from text: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: #"[-+]?[0-9]*\.?[0-9]+"#) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range), let r = Range(match.range, in: text) else { return nil }
        return Double(text[r])
    }

    private func checkAnswer(for item: CalculationPracticeItem) {
        let typed = userAnswers[item.id] ?? ""
        guard let userValue = extractNumber(from: typed), let expectedValue = extractNumber(from: item.answer) else {
            checkedCorrect[item.id] = nil
            return
        }
        // A generous relative tolerance (plus a small absolute floor) since
        // some answers are themselves approximate (e.g. "x ≈ 6").
        let tolerance = max(abs(expectedValue) * 0.03, 0.05)
        let correct = abs(userValue - expectedValue) <= tolerance
        checkedCorrect[item.id] = correct

        AttemptRepository(modelContext: modelContext).save(
            curriculum: curriculum,
            mode: .calculationPractice,
            target: "Calculation Practice · \(item.topic)",
            score: correct ? 1 : 0,
            maxScore: 1,
            feedback: ["\(item.question) — you answered \"\(typed)\"; \(correct ? "correct" : "expected \(item.answer)")."]
        )
    }
}

private struct CalculationQuestionCard: View {
    let item: CalculationPracticeItem
    let isRevealed: Bool
    let isCorrect: Bool?
    @Binding var userAnswer: String
    let onReveal: () -> Void
    let onHide: () -> Void
    let onCheck: () -> Void

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

            HStack {
                Button("Check answer") { onCheck() }
                    .font(.caption.weight(.semibold))
                    .disabled(userAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                Spacer()
                Button(isRevealed ? "Hide solution" : "Reveal solution") { isRevealed ? onHide() : onReveal() }
                    .font(.caption)
            }

            if let isCorrect {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? .green : .red)
                    Text(isCorrect ? "Correct." : "Not quite — expected \(item.answer).")
                        .font(.footnote)
                        .foregroundStyle(isCorrect ? .green : .red)
                }
            }

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
            }
        }
        .padding(.vertical, 4)
    }
}
