//
//  SaltPreparationSim.swift
//  ChemistryCoach
//
//  Interactive decision-tree simulation for salt preparation.
//  Students identify the solubility, choose the correct method,
//  and follow the procedure step by step.
//

import SwiftUI

@MainActor
final class SaltPrepViewModel: ObservableObject {
    @Published var selectedSalt: SaltPrepTarget?
    @Published var step: SaltPrepStep = .selectSalt
    @Published var chosenMethod: String = ""
    @Published var completedSteps: [String] = []
    @Published var result: LabRunResult?

    private var targetMethod: String = ""

    func selectSalt(_ salt: SaltPrepTarget) {
        selectedSalt = salt
        step = .identifySolubility
        chosenMethod = ""
        completedSteps = []
        result = nil
        targetMethod = salt.correctMethod
    }

    func checkSolubility(_ isSoluble: Bool) {
        guard let salt = selectedSalt else { return }
        let correct = (isSoluble == salt.isSoluble)
        completedSteps.append("Solubility check: \(isSoluble ? "Soluble" : "Insoluble") — \(correct ? "Correct" : "Incorrect (salt is \(salt.isSoluble ? "soluble" : "insoluble"))")")
        step = .chooseMethod
    }

    func chooseMethod(_ method: String) {
        chosenMethod = method
        let correct = method == targetMethod
        completedSteps.append("Method chosen: \(method) — \(correct ? "Correct" : "Incorrect")")
        step = .executeSteps
    }

    func executeStep(_ stepDescription: String) {
        guard let salt = selectedSalt else { return }
        completedSteps.append("✓ \(stepDescription)")

        if completedSteps.filter({ $0.hasPrefix("✓") }).count >= salt.procedureSteps.count {
            step = .complete
            gradeResult()
        }
    }

    func skipExcessStep() {
        completedSteps.append("✓ (No excess step needed for this method)")
        step = .complete
        gradeResult()
    }

    private func gradeResult() {
        guard let salt = selectedSalt else { return }
        let methodCorrect = chosenMethod == targetMethod
        let stepsCompleted = completedSteps.filter { $0.hasPrefix("✓") }.count
        let stepAccuracy = Double(stepsCompleted) / Double(salt.procedureSteps.count)

        var score = 0
        var feedback: [String] = []

        if methodCorrect {
            score = Int(stepAccuracy * 100)
            feedback.append("Correct method: \(targetMethod)")
        } else {
            score = 30
            feedback.append("Incorrect method. The correct method for \(salt.name) is: \(targetMethod)")
            feedback.append("Decision: \(salt.isSoluble ? "Soluble" : "Insoluble") + \(salt.isSPA ? "SPA salt" : "not an SPA salt") → \(targetMethod)")
        }

        feedback.append("Steps completed: \(stepsCompleted) / \(salt.procedureSteps.count)")
        feedback.append("Remember: check solubility first, then check if it's an SPA (Sodium, Potassium, Ammonium) salt.")

        result = LabRunResult(
            correct: methodCorrect && score >= 80,
            score: max(score, 30),
            feedback: feedback,
            examTip: salt.examTip
        )
    }

    func reset() {
        selectedSalt = nil
        step = .selectSalt
        chosenMethod = ""
        completedSteps = []
        result = nil
    }
}

enum SaltPrepStep: Int, CaseIterable {
    case selectSalt = 0
    case identifySolubility = 1
    case chooseMethod = 2
    case executeSteps = 3
    case complete = 4
}

struct SaltPrepTarget: Identifiable, Hashable {
    let id: String
    let name: String
    let formula: String
    let isSoluble: Bool
    let isSPA: Bool
    let correctMethod: String
    let procedureSteps: [String]
    let examTip: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SaltPrepTarget, rhs: SaltPrepTarget) -> Bool { lhs.id == rhs.id }
}

enum SaltPrepBank {
    static let salts: [SaltPrepTarget] = [
        .init(
            id: "cuso4",
            name: "Copper(II) sulfate",
            formula: "CuSO₄",
            isSoluble: true,
            isSPA: false,
            correctMethod: "Excess insoluble base method",
            procedureSteps: [
                "Add excess copper(II) oxide to warm sulfuric acid",
                "Filter to remove excess CuO (residue)",
                "Heat filtrate to concentrate (evaporate some water)",
                "Allow to cool for crystallisation",
                "Filter crystals, wash with cold water, dry between filter paper"
            ],
            examTip: "CuSO₄ is soluble but NOT an SPA salt → use the excess method. Use excess INSOLUBLE base (CuO) so the excess can be filtered off."
        ),
        .init(
            id: "nacl",
            name: "Sodium chloride",
            formula: "NaCl",
            isSoluble: true,
            isSPA: true,
            correctMethod: "Titration method",
            procedureSteps: [
                "Titrate HCl with NaOH using methyl orange indicator",
                "Record the exact volume of acid needed to neutralise the alkali",
                "Repeat the titration WITHOUT indicator using the exact volumes",
                "Evaporate the solution to saturation",
                "Allow to crystallise, filter and dry"
            ],
            examTip: "NaCl is an SPA (Sodium) salt → use titration. Both reactants are soluble, so exact volumes are needed with no excess."
        ),
        .init(
            id: "pbso4",
            name: "Lead(II) sulfate",
            formula: "PbSO₄",
            isSoluble: false,
            isSPA: false,
            correctMethod: "Precipitation method",
            procedureSteps: [
                "Mix lead(II) nitrate solution with sodium sulfate solution",
                "A white precipitate of PbSO₄ forms immediately",
                "Filter to collect the precipitate (residue)",
                "Wash with distilled water to remove impurities",
                "Dry between sheets of filter paper"
            ],
            examTip: "PbSO₄ is insoluble → use precipitation. Mix two soluble solutions (one with Pb²⁺, one with SO₄²⁻) and filter the precipitate."
        ),
        .init(
            id: "kno3",
            name: "Potassium nitrate",
            formula: "KNO₃",
            isSoluble: true,
            isSPA: true,
            correctMethod: "Titration method",
            procedureSteps: [
                "Titrate HNO₃ with KOH using phenolphthalein",
                "Record exact volumes for neutralisation",
                "Repeat without indicator using those volumes",
                "Evaporate to saturation and crystallise",
                "Filter, wash with cold water, dry"
            ],
            examTip: "KNO₃ is an SPA (Potassium) salt → titration. Use phenolphthalein (strong acid + strong alkali)."
        ),
        .init(
            id: "caco3",
            name: "Calcium carbonate",
            formula: "CaCO₃",
            isSoluble: false,
            isSPA: false,
            correctMethod: "Precipitation method",
            procedureSteps: [
                "Mix calcium nitrate solution with sodium carbonate solution",
                "White precipitate of CaCO₃ forms",
                "Filter to collect the precipitate",
                "Wash with distilled water",
                "Dry between sheets of filter paper"
            ],
            examTip: "CaCO₃ is insoluble → precipitation. Most carbonates are insoluble except SPA carbonates."
        ),
        .init(
            id: "mgcl2",
            name: "Magnesium chloride",
            formula: "MgCl₂",
            isSoluble: true,
            isSPA: false,
            correctMethod: "Excess insoluble base method",
            procedureSteps: [
                "Add excess magnesium oxide to warm hydrochloric acid",
                "Filter to remove excess MgO",
                "Heat filtrate to concentrate",
                "Crystallise by cooling",
                "Filter crystals, wash with cold water, dry"
            ],
            examTip: "MgCl₂ is soluble but NOT SPA → excess method. Use MgO (insoluble base) so excess can be filtered."
        )
    ]

    static let methods: [String] = [
        "Precipitation method",
        "Excess insoluble base method",
        "Titration method"
    ]
}

struct SaltPreparationView: View {
    let curriculum: Curriculum
    @StateObject private var model = SaltPrepViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var didRecordResult = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Salt Preparation")
                    .font(.title.bold())

                Text("Choose a salt, identify its solubility, select the correct preparation method, and follow the procedure step by step.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                switch model.step {
                case .selectSalt:
                    saltSelection
                case .identifySolubility:
                    solubilityStep
                case .chooseMethod:
                    methodStep
                case .executeSteps:
                    executeSteps
                case .complete:
                    completeStep
                }

                if !model.completedSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Progress log").font(.headline)
                        ForEach(Array(model.completedSteps.enumerated()), id: \.offset) { _, step in
                            Text(step).font(.caption)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Salt Preparation")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.result?.score) { _, newValue in
            guard newValue != nil, !didRecordResult, let salt = model.selectedSalt else { return }
            didRecordResult = true
            let repository = AttemptRepository(modelContext: modelContext)
            repository.save(curriculum: curriculum, mode: AttemptMode.simulationLab, target: "Salt Preparation · \(salt.name)", score: model.result?.score ?? 0, maxScore: 100, feedback: model.result?.feedback ?? [])
        }
        .onChange(of: model.step) { _, newStep in
            if newStep == .selectSalt { didRecordResult = false }
        }
    }

    private var saltSelection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select a salt to prepare:")
                .font(.headline)

            ForEach(SaltPrepBank.salts) { salt in
                Button {
                    model.selectSalt(salt)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(salt.name).font(.subheadline.bold())
                            Text(salt.formula).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var solubilityStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 1: Is \(model.selectedSalt?.name ?? "") soluble in water?")
                .font(.headline)

            Text("Check the solubility rules before answering. Remember: all nitrates are soluble; SPA salts (Sodium, Potassium, Ammonium) are always soluble; most carbonates and hydroxides are insoluble.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Soluble") { model.checkSolubility(true) }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                Button("Insoluble") { model.checkSolubility(false) }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var methodStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 2: Choose the preparation method")
                .font(.headline)

            Text("Decision: \(model.selectedSalt?.isSoluble == true ? "Soluble" : "Insoluble") salt\(model.selectedSalt?.isSPA == true ? " (SPA — Sodium/Potassium/Ammonium)" : " (not an SPA salt)")")
                .font(.subheadline)
                .foregroundStyle(.blue)

            ForEach(SaltPrepBank.methods, id: \.self) { method in
                Button {
                    model.chooseMethod(method)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(method).font(.subheadline.bold())
                            Text(methodHint(for: method))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var executeSteps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 3: Follow the procedure")
                .font(.headline)

            Text("Method: \(model.chosenMethod)")
                .font(.subheadline.bold())
                .foregroundStyle(.blue)

            if let salt = model.selectedSalt {
                ForEach(Array(salt.procedureSteps.enumerated()), id: \.offset) { index, step in
                    Button {
                        model.executeStep(step)
                    } label: {
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.blue)
                            Text("\(index + 1). \(step)")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var completeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let result = model.result {
                ChemistryLabFeedback(result: result)
                Button("New salt") { model.reset() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func methodHint(for method: String) -> String {
        switch method {
        case "Precipitation method": return "For insoluble salts — mix two soluble solutions"
        case "Excess insoluble base method": return "For soluble non-SPA salts — add excess insoluble solid to acid"
        case "Titration method": return "For soluble SPA salts — exact volumes, no excess"
        default: return ""
        }
    }
}
