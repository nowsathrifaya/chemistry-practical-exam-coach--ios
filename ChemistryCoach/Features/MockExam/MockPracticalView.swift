//
//  MockPracticalView.swift
//  ChemistryCoach
//
//  v5: dedicated Paper 3-style practical mock. This is intentionally separate
//  from the general ACE bank so practical technique, observations and evaluation
//  are assessed as one coherent paper.
//

import SwiftUI
import SwiftData

struct MockPracticalQuestion: Identifiable, Hashable {
    let id: String
    let prompt: String
    let markingPoints: [String]
    let modelAnswer: String
    let keywords: [[String]]
}

enum MockPracticalQuestionBank {
    static let questions: [MockPracticalQuestion] = [
        .init(id: "mp1", prompt: "A student investigates the effect of temperature on reaction rate. State two variables that should be kept constant.", markingPoints: ["Concentration/volume of reactants", "Surface area or mass of a solid reactant"], modelAnswer: "Keep the concentration and volume of the reactants constant; also keep the mass/surface area of any solid reactant constant. Only temperature should be deliberately changed.", keywords: [["concentration", "volume"], ["surface area", "mass"]]),
        .init(id: "mp2", prompt: "During a titration, a student obtains titres of 24.10, 24.15, 24.55 and 24.10 cm³. State which titres should be used and explain why.", markingPoints: ["24.10, 24.15 and 24.10 cm³", "They are concordant within 0.20 cm³"], modelAnswer: "Use 24.10, 24.15 and 24.10 cm³. They are concordant because the maximum difference between them is 0.05 cm³, whereas 24.55 cm³ is not concordant with them.", keywords: [["24.10", "24.15"], ["concordant", "0.20"]]),
        .init(id: "mp3", prompt: "An unknown solution gives a white precipitate when acidified silver nitrate is added. What ion is indicated, and what observation should be recorded?", markingPoints: ["Chloride ion / Cl⁻", "White precipitate of silver chloride"], modelAnswer: "Chloride ions, Cl⁻, are indicated. Record that a white precipitate forms after adding acidified silver nitrate.", keywords: [["chloride", "cl"], ["white", "precipitate"]]),
        .init(id: "mp4", prompt: "A student measures temperature change in a calorimetry experiment. Give two practical improvements that reduce heat loss to the surroundings.", markingPoints: ["Use an insulated/polystyrene container", "Use a lid and/or reduce exposure time"], modelAnswer: "Use an insulated container such as a polystyrene cup and cover it with a lid. These reduce heat exchange with the surroundings.", keywords: [["insulat", "polystyrene"], ["lid", "cover"]]),
        .init(id: "mp5", prompt: "A burette is used to deliver an alkali. Describe two good measurement practices needed for an accurate titre.", markingPoints: ["Read the bottom of the meniscus at eye level", "Remove air bubbles and read the scale correctly"], modelAnswer: "Read the bottom of the meniscus at eye level to avoid parallax and ensure the burette is free of air bubbles. Record readings to the appropriate precision and subtract initial from final reading.", keywords: [["meniscus", "eye level"], ["bubble", "air"]])
    ]
}

struct MockPracticalView: View {
    let curriculum: Curriculum
    @Environment(\.modelContext) private var modelContext
    @State private var answers = Array(repeating: "", count: MockPracticalQuestionBank.questions.count)
    @State private var index = 0
    @State private var submitted = false
    @State private var score = 0
    @State private var feedback: [String] = []
    @State private var didRecord = false

    init(curriculum: Curriculum = .general) {
        self.curriculum = curriculum
    }

    private var question: MockPracticalQuestion { MockPracticalQuestionBank.questions[index] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if submitted {
                    resultView
                } else {
                    questionView
                }
            }
            .padding(20)
        }
        .navigationTitle("Practical Mock")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paper 3 Practical Mock")
                .font(.largeTitle.bold())
            Text("5 structured practical questions · 10 marks")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: Double(submitted ? 5 : index), total: 5)
        }
    }

    private var questionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Question \(index + 1) of 5")
                .font(.headline)
            Text(question.prompt)
                .font(.title3.weight(.semibold))

            TextEditor(text: Binding(get: { answers[index] }, set: { answers[index] = $0 }))
                .frame(minHeight: 150)
                .padding(6)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.35)))

            HStack {
                Button("Previous") { index = max(0, index - 1) }
                    .disabled(index == 0)
                Spacer()
                Button(index == 4 ? "Submit Mock" : "Next") {
                    if index < 4 { index += 1 } else { submit() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var resultView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Score: \(score)/10")
                .font(.title.bold())

            ForEach(MockPracticalQuestionBank.questions.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question \(i + 1)").font(.headline)
                    Text(MockPracticalQuestionBank.questions[i].modelAnswer)
                        .font(.subheadline)
                    Text(feedback.indices.contains(i) ? feedback[i] : "Review the marking points.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }

            Button("Try the mock again") {
                answers = Array(repeating: "", count: MockPracticalQuestionBank.questions.count)
                index = 0
                submitted = false
                score = 0
                feedback = []
                didRecord = false
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func submit() {
        var total = 0
        var messages: [String] = []

        for (i, q) in MockPracticalQuestionBank.questions.enumerated() {
            let answer = answers[i].lowercased()
            var earned = 0
            for group in q.keywords where group.contains(where: { answer.contains($0) }) {
                earned += 1
            }
            total += min(earned, 2)
            messages.append("\(min(earned, 2))/2 marks · \(q.markingPoints.joined(separator: "; "))")
        }

        score = total
        feedback = messages
        submitted = true

        guard !didRecord else { return }
        didRecord = true
        AttemptRepository(modelContext: modelContext).save(
            curriculum: curriculum,
            mode: .simulationLab,
            target: "Practical Mock · Paper 3",
            score: total,
            maxScore: 10,
            feedback: messages
        )
    }
}
