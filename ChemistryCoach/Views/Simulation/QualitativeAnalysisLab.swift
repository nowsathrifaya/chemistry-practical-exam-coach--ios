//
//  QualitativeAnalysisLab.swift
//  ChemistryCoach
//
//  Full Unknown Sample Laboratory for QA practice.
//  Multi-step workflow: choose unknown → select reagent → observe →
//  add excess if appropriate → observe → choose conclusion.
//

import SwiftUI

// MARK: - Data Model

struct QAUnknownSample: Identifiable, Hashable {
    let id: String
    let description: String
    let cation: String?
    let anion: String?
    let gas: String?
    let expectedTests: [QATestResult]
}

struct QATestResult: Hashable {
    let reagent: String
    let observation: String
    let inference: String
    let requiresExcess: Bool
    let excessObservation: String?
    let excessInference: String?
}

enum QATestStep: Int, CaseIterable {
    case selectSample = 0
    case addReagent = 1
    case observe = 2
    case addExcess = 3
    case conclude = 4
    case complete = 5

    var label: String {
        switch self {
        case .selectSample: return "Select unknown"
        case .addReagent: return "Add reagent"
        case .observe: return "Observe"
        case .addExcess: return "Excess test"
        case .conclude: return "Conclude"
        case .complete: return "Complete"
        }
    }
}

// MARK: - Sample Bank

enum QASampleBank {
    static let samples: [QAUnknownSample] = [
        // Cation-only samples (NaOH / NH3 tests)
        .init(id: "cu", description: "Blue solution", cation: "Cu²⁺", anion: nil, gas: nil, expectedTests: [
            .init(reagent: "NaOH (aqueous)", observation: "Light blue precipitate", inference: "Cu²⁺ may be present", requiresExcess: true, excessObservation: "Insoluble in excess NaOH", excessInference: "Consistent with Cu²⁺"),
            .init(reagent: "NH₃ (aqueous)", observation: "Light blue precipitate", inference: "Cu²⁺ may be present", requiresExcess: true, excessObservation: "Dissolves to deep blue solution", excessInference: "Cu²⁺ confirmed")
        ]),
        .init(id: "fe2", description: "Pale green solution", cation: "Fe²⁺", anion: nil, gas: nil, expectedTests: [
            .init(reagent: "NaOH (aqueous)", observation: "Green precipitate", inference: "Fe²⁺ may be present", requiresExcess: true, excessObservation: "Insoluble in excess; turns brown on standing", excessInference: "Fe²⁺ confirmed (oxidises to Fe³⁺)"),
            .init(reagent: "NH₃ (aqueous)", observation: "Green precipitate", inference: "Fe²⁺ may be present", requiresExcess: true, excessObservation: "Insoluble in excess", excessInference: "Consistent with Fe²⁺")
        ]),
        .init(id: "fe3", description: "Yellow-brown solution", cation: "Fe³⁺", anion: nil, gas: nil, expectedTests: [
            .init(reagent: "NaOH (aqueous)", observation: "Reddish-brown precipitate", inference: "Fe³⁺ may be present", requiresExcess: true, excessObservation: "Insoluble in excess NaOH", excessInference: "Fe³⁺ confirmed"),
            .init(reagent: "NH₃ (aqueous)", observation: "Reddish-brown precipitate", inference: "Fe³⁺ may be present", requiresExcess: true, excessObservation: "Insoluble in excess", excessInference: "Consistent with Fe³⁺")
        ]),
        .init(id: "zn", description: "Colourless solution", cation: "Zn²⁺", anion: nil, gas: nil, expectedTests: [
            .init(reagent: "NaOH (aqueous)", observation: "White precipitate", inference: "Zn²⁺ or Al³⁺ may be present", requiresExcess: true, excessObservation: "Dissolves to colourless solution", excessInference: "Zn²⁺ or Al³⁺ (need NH₃ to distinguish)"),
            .init(reagent: "NH₃ (aqueous)", observation: "White precipitate", inference: "Zn²⁺ or Al³⁺ may be present", requiresExcess: true, excessObservation: "Dissolves to colourless solution", excessInference: "Zn²⁺ confirmed (Al³⁺ would be insoluble in excess NH₃)")
        ]),
        .init(id: "al", description: "Colourless solution", cation: "Al³⁺", anion: nil, gas: nil, expectedTests: [
            .init(reagent: "NaOH (aqueous)", observation: "White precipitate", inference: "Al³⁺ or Zn²⁺ may be present", requiresExcess: true, excessObservation: "Dissolves to colourless solution", excessInference: "Al³⁺ or Zn²⁺ (need NH₃ to distinguish)"),
            .init(reagent: "NH₃ (aqueous)", observation: "White precipitate", inference: "Al³⁺ may be present", requiresExcess: true, excessObservation: "Insoluble in excess NH₃", excessInference: "Al³⁺ confirmed (Zn²⁺ would dissolve)")
        ]),
        .init(id: "ca", description: "Colourless solution", cation: "Ca²⁺", anion: nil, gas: nil, expectedTests: [
            .init(reagent: "NaOH (aqueous)", observation: "White precipitate", inference: "Ca²⁺ may be present (if concentration high enough)", requiresExcess: true, excessObservation: "Insoluble in excess NaOH", excessInference: "Consistent with Ca²⁺"),
            .init(reagent: "NH₃ (aqueous)", observation: "No precipitate", inference: "Ca²⁺ does not precipitate with NH₃", requiresExcess: false, excessObservation: nil, excessInference: nil),
            .init(reagent: "Flame test", observation: "Orange-red flame", inference: "Ca²⁺ confirmed", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
        .init(id: "nh4", description: "Colourless solution", cation: "NH₄⁺", anion: nil, gas: nil, expectedTests: [
            .init(reagent: "NaOH (warm)", observation: "Pungent gas produced on warming", inference: "NH₄⁺ may be present", requiresExcess: false, excessObservation: nil, excessInference: nil),
            .init(reagent: "Damp red litmus", observation: "Turns blue", inference: "NH₃ gas confirmed → NH₄⁺ present", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
        // Anion samples
        .init(id: "cl", description: "Solution containing chloride", cation: nil, anion: "Cl⁻", gas: nil, expectedTests: [
            .init(reagent: "HNO₃ + AgNO₃", observation: "White precipitate", inference: "Cl⁻ may be present", requiresExcess: false, excessObservation: nil, excessInference: nil),
            .init(reagent: "HNO₃ (acidify first)", observation: "No dissolving in dilute HNO₃", inference: "Confirms Cl⁻ (AgCl insoluble)", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
        .init(id: "so4", description: "Solution containing sulfate", cation: nil, anion: "SO₄²⁻", gas: nil, expectedTests: [
            .init(reagent: "HNO₃ + Ba(NO₃)₂", observation: "White precipitate", inference: "SO₄²⁻ may be present", requiresExcess: false, excessObservation: nil, excessInference: nil),
            .init(reagent: "HNO₃ (acidify first)", observation: "No dissolving in dilute HNO₃", inference: "Confirms SO₄²⁻ (BaSO₄ insoluble)", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
        .init(id: "co3", description: "White powder", cation: nil, anion: "CO₃²⁻", gas: nil, expectedTests: [
            .init(reagent: "Dilute HCl", observation: "Effervescence", inference: "CO₃²⁻ may be present", requiresExcess: false, excessObservation: nil, excessInference: nil),
            .init(reagent: "Limewater", observation: "Turns milky", inference: "CO₂ confirmed → CO₃²⁻ present", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
        .init(id: "no3", description: "Solution containing nitrate", cation: nil, anion: "NO₃⁻", gas: nil, expectedTests: [
            .init(reagent: "NaOH + Al foil (warm)", observation: "Pungent gas produced", inference: "NO₃⁻ may be present", requiresExcess: false, excessObservation: nil, excessInference: nil),
            .init(reagent: "Damp red litmus", observation: "Turns blue", inference: "NH₃ confirmed → NO₃⁻ present", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
        .init(id: "i", description: "Solution containing iodide", cation: nil, anion: "I⁻", gas: nil, expectedTests: [
            .init(reagent: "HNO₃ + AgNO₃", observation: "Yellow precipitate", inference: "I⁻ may be present", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
        .init(id: "br", description: "Solution containing bromide", cation: nil, anion: "Br⁻", gas: nil, expectedTests: [
            .init(reagent: "HNO₃ + AgNO₃", observation: "Cream precipitate", inference: "Br⁻ may be present", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
        // Mixed salt samples
        .init(id: "cucl2", description: "Blue-green crystalline solid", cation: "Cu²⁺", anion: "Cl⁻", gas: nil, expectedTests: [
            .init(reagent: "NaOH (aqueous)", observation: "Light blue precipitate", inference: "Cu²⁺ may be present", requiresExcess: true, excessObservation: "Insoluble in excess NaOH", excessInference: "Consistent with Cu²⁺"),
            .init(reagent: "HNO₃ + AgNO₃", observation: "White precipitate", inference: "Cl⁻ may be present", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
        .init(id: "feso4", description: "Pale green crystals", cation: "Fe²⁺", anion: "SO₄²⁻", gas: nil, expectedTests: [
            .init(reagent: "NaOH (aqueous)", observation: "Green precipitate", inference: "Fe²⁺ may be present", requiresExcess: true, excessObservation: "Insoluble; turns brown on standing", excessInference: "Fe²⁺ confirmed"),
            .init(reagent: "HNO₃ + Ba(NO₃)₂", observation: "White precipitate", inference: "SO₄²⁻ may be present", requiresExcess: false, excessObservation: nil, excessInference: nil)
        ]),
    ]

    static let availableReagents: [String] = [
        "NaOH (aqueous)",
        "NaOH (warm)",
        "NH₃ (aqueous)",
        "HNO₃ + AgNO₃",
        "HNO₃ + Ba(NO₃)₂",
        "Dilute HCl",
        "Limewater",
        "Damp red litmus",
        "NaOH + Al foil (warm)",
        "Flame test"
    ]

    static let observationOptions: [String] = [
        "White precipitate",
        "Light blue precipitate",
        "Green precipitate",
        "Reddish-brown precipitate",
        "Cream precipitate",
        "Yellow precipitate",
        "Effervescence",
        "Pungent gas produced",
        "No visible change",
        "Turns milky",
        "Turns blue",
        "Orange-red flame",
        "Yellow flame",
        "Lilac flame",
        "Apple green flame",
        "Blue-green flame",
        "Crimson red flame",
        "Dissolves to colourless solution",
        "Dissolves to deep blue solution",
        "Insoluble in excess",
        "Turns brown on standing"
    ]
}

// MARK: - View Model

@MainActor
final class QALabViewModel: ObservableObject {
    @Published var step: QATestStep = .selectSample
    @Published var currentSample: QAUnknownSample?
    @Published var selectedReagent: String = ""
    @Published var selectedObservation: String = ""
    @Published var selectedExcessObservation: String = ""
    @Published var performedTests: [(reagent: String, observation: String, inference: String)] = []
    @Published var studentConclusion: String = ""
    @Published var result: LabRunResult?
    @Published var showSamplePicker = false

    private var expectedTest: QATestResult?

    func selectSample(_ sample: QAUnknownSample) {
        currentSample = sample
        step = .addReagent
        performedTests = []
        selectedReagent = ""
        selectedObservation = ""
        result = nil
    }

    func addReagent() {
        guard let sample = currentSample, !selectedReagent.isEmpty else { return }
        // Find matching expected test
        expectedTest = sample.expectedTests.first { $0.reagent == selectedReagent }
        step = .observe
        selectedObservation = ""
        selectedExcessObservation = ""
    }

    func recordObservation() {
        guard currentSample != nil, let test = expectedTest else { return }

        let isCorrect = selectedObservation == test.observation
        let inference = isCorrect ? test.inference : "Observation does not match expected result for this sample"

        performedTests.append((reagent: selectedReagent, observation: selectedObservation, inference: inference))

        if test.requiresExcess {
            step = .addExcess
        } else {
            step = .conclude
        }
    }

    func recordExcessObservation() {
        guard let test = expectedTest else { return }
        let isCorrect = selectedExcessObservation == (test.excessObservation ?? "")
        let inference = isCorrect ? (test.excessInference ?? test.inference) : "Excess observation does not match"

        // Update the last test's inference
        if !performedTests.isEmpty {
            performedTests[performedTests.count - 1].inference += "\nExcess: \(inference)"
        }

        step = .conclude
    }

    func submitConclusion() {
        guard let sample = currentSample else { return }

        var expectedParts: [String] = []
        if let cation = sample.cation { expectedParts.append(cation) }
        if let anion = sample.anion { expectedParts.append(anion) }
        if let gas = sample.gas { expectedParts.append(gas) }
        let expected = expectedParts.joined(separator: " + ")

        let correct = studentConclusion.lowercased().contains(expected.lowercased()) ||
            (sample.cation != nil && studentConclusion.lowercased().contains(sample.cation!.lowercased()))

        var feedback: [String] = []
        var score = 0

        if correct {
            score = 100
            feedback.append("Correct identification: \(expected)")
        } else {
            score = 40
            feedback.append("The unknown was: \(expected)")
            feedback.append("Review the tests and observations above to see where the evidence pointed.")
        }

        let testCount = performedTests.count
        feedback.append("You performed \(testCount) test(s).")
        feedback.append("Tip: Always record the observation before stating the inference. Use the Notes for Qualitative Analysis provided in the exam.")

        result = LabRunResult(
            correct: correct,
            score: score,
            feedback: feedback,
            examTip: "In the exam, use approximately 1 cm depth of solution. Add reagents slowly. Record colour, precipitate, solubility in excess, and gas tests before naming any ion."
        )
        step = .complete
    }

    func reset() {
        step = .selectSample
        currentSample = nil
        selectedReagent = ""
        selectedObservation = ""
        selectedExcessObservation = ""
        performedTests = []
        studentConclusion = ""
        result = nil
        expectedTest = nil
    }
}

// MARK: - View

struct QualitativeAnalysisLabView: View {
    let curriculum: Curriculum
    @StateObject private var model = QALabViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var didRecordResult = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Step indicator
                HStack(spacing: 4) {
                    ForEach(QATestStep.allCases, id: \.self) { step in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(model.step.rawValue >= step.rawValue ? Color.blue : Color.secondary.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .overlay(Text("\(step.rawValue + 1)").font(.caption2.bold()).foregroundStyle(.white))
                            if step != .complete {
                                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)

                switch model.step {
                case .selectSample:
                    sampleSelectionStep
                case .addReagent:
                    addReagentStep
                case .observe:
                    observeStep
                case .addExcess:
                    excessStep
                case .conclude:
                    concludeStep
                case .complete:
                    completeStep
                }

                // Test log
                if !model.performedTests.isEmpty {
                    testLog
                }
            }
            .padding()
        }
        .navigationTitle("Unknown Sample Laboratory")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.result?.score) { _, newValue in
            guard newValue != nil, !didRecordResult, let sample = model.currentSample else { return }
            didRecordResult = true
            let ion = [sample.cation, sample.anion, sample.gas].compactMap { $0 }.joined(separator: " + ")
            let repository = AttemptRepository(modelContext: modelContext)
            repository.save(curriculum: curriculum, mode: AttemptMode.simulationLab, target: "Qualitative Analysis · \(ion.isEmpty ? sample.id.uppercased() : ion)", score: model.result?.score ?? 0, maxScore: 100, feedback: model.result?.feedback ?? [])
        }
        .onChange(of: model.step) { _, newStep in
            if newStep == .selectSample { didRecordResult = false }
        }
    }

    private var sampleSelectionStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Qualitative Analysis Laboratory")
                .font(.title2.bold())
            Text("Select an unknown sample to analyse. You will choose reagents, record observations, and identify the ion(s) present — just like in the actual Paper 3 exam.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(QASampleBank.samples) { sample in
                Button {
                    model.selectSample(sample)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unknown \(sample.id.uppercased())")
                                .font(.headline)
                            Text(sample.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var addReagentStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sample: \(model.currentSample?.description ?? "")")
                .font(.headline)

            Text("Select a reagent to test the sample:")
                .font(.subheadline)

            ForEach(QASampleBank.availableReagents, id: \.self) { reagent in
                Button {
                    model.selectedReagent = reagent
                    model.addReagent()
                } label: {
                    HStack {
                        Image(systemName: "flask")
                            .foregroundStyle(.blue)
                        Text(reagent)
                            .font(.subheadline)
                        Spacer()
                        if model.selectedReagent == reagent {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            if !model.performedTests.isEmpty {
                Button("Try another reagent") {
                    model.step = .addReagent
                    model.selectedReagent = ""
                    model.selectedObservation = ""
                }
                .font(.caption)
            }
        }
    }

    private var observeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Record your observation")
                .font(.headline)

            Text("Reagent: \(model.selectedReagent)")
                .font(.subheadline.bold())
                .foregroundStyle(.blue)

            Text("What do you observe after adding the reagent?")
                .font(.subheadline)

            Picker("Observation", selection: $model.selectedObservation) {
                Text("Select observation...").tag("")
                ForEach(QASampleBank.observationOptions, id: \.self) { obs in
                    Text(obs).tag(obs)
                }
            }
            .pickerStyle(.menu)

            Button("Record observation") {
                model.recordObservation()
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.selectedObservation.isEmpty)
        }
    }

    private var excessStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add excess reagent")
                .font(.headline)

            Text("The test requires adding excess reagent. What do you observe?")
                .font(.subheadline)

            Picker("Excess observation", selection: $model.selectedExcessObservation) {
                Text("Select observation...").tag("")
                ForEach(QASampleBank.observationOptions, id: \.self) { obs in
                    Text(obs).tag(obs)
                }
            }
            .pickerStyle(.menu)

            Button("Record excess observation") {
                model.recordExcessObservation()
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.selectedExcessObservation.isEmpty)
        }
    }

    private var concludeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("State your conclusion")
                .font(.headline)

            Text("Based on your observations, identify the ion(s) present in the sample.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("e.g. Cu²⁺ and Cl⁻", text: $model.studentConclusion)
                .textFieldStyle(.roundedBorder)

            Button("Submit conclusion") {
                model.submitConclusion()
            }
            .buttonStyle(.borderedProminent)

            Button("Perform another test") {
                model.step = .addReagent
                model.selectedReagent = ""
                model.selectedObservation = ""
            }
            .font(.caption)
        }
    }

    private var completeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let result = model.result {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: result.correct ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(result.correct ? .green : .orange)
                        Text(result.correct ? "Correct!" : "Not quite")
                            .font(.title2.bold())
                    }

                    Text("Score: \(result.score)%")
                        .font(.headline)

                    ForEach(result.feedback, id: \.self) { f in
                        Text("• \(f)")
                            .font(.caption)
                    }

                    Text("Exam tip: \(result.examTip)")
                        .font(.caption.italic())
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(16)
                .background(result.correct ? Color.green.opacity(0.1) : Color.orange.opacity(0.1),
                           in: RoundedRectangle(cornerRadius: 16))

                Button("New sample") {
                    model.reset()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var testLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test record")
                .font(.headline)

            ForEach(Array(model.performedTests.enumerated()), id: \.offset) { _, test in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "flask.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text(test.reagent)
                            .font(.caption.bold())
                    }
                    Text("Observation: \(test.observation)")
                        .font(.caption)
                    Text("Inference: \(test.inference)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
