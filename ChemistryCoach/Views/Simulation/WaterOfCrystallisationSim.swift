//
//  WaterOfCrystallisationSim.swift
//  ChemistryCoach
//
//  Interactive simulation for determining x in a hydrated salt
//  (e.g. CuSO₄·xH₂O). Students heat, weigh to constant mass,
//  and calculate the mole ratio.
//

import SwiftUI

@MainActor
final class WaterOfCrystallisationViewModel: ObservableObject {
    @Published var hydratedMass: Double = 0
    @Published var anhydrousMass: Double = 0
    @Published var heatingCount: Int = 0
    @Published var constantMass: Bool = false
    @Published var saltName: String = ""
    @Published var mrAnhydrous: Double = 0
    @Published var studentX: String = ""
    @Published var result: LabRunResult?
    /// Every weighing so far: index 0 is the initial hydrated mass, then one entry per heating.
    @Published var massHistory: [Double] = []
    /// Set when the student last pressed "Declare constant mass" while the mass was still falling.
    @Published var lastDeclareWasPremature: Bool = false
    @Published var prematureDeclarations: Int = 0
    @Published var extraHeatingsAfterConstant: Int = 0

    private var targetX: Int = 0
    /// The heating number (1-based) at which the true mass has actually stopped changing (to 2 dp).
    private var trueConstantHeating: Int = 0

    let saltOptions: [(name: String, formula: String, mr: Double, x: Int)] = [
        ("Copper(II) sulfate", "CuSO₄", 159.6, 5),
        ("Magnesium sulfate", "MgSO₄", 120.0, 7),
        ("Sodium carbonate", "Na₂CO₃", 106.0, 10),
        ("Iron(II) sulfate", "FeSO₄", 151.9, 7)
    ]

    func selectSalt(_ salt: (name: String, formula: String, mr: Double, x: Int)) {
        saltName = salt.name
        mrAnhydrous = salt.mr
        targetX = salt.x
        hydratedMass = 0
        anhydrousMass = 0
        heatingCount = 0
        constantMass = false
        studentX = ""
        result = nil
        massHistory = []
        lastDeclareWasPremature = false
        prematureDeclarations = 0
        extraHeatingsAfterConstant = 0

        // Generate a random hydrated mass
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        hydratedMass = (rng.nextDouble(3.0, 8.0) * 100).rounded() / 100
        // Calculate exact anhydrous mass based on target x
        let mrWater = 18.0
        let totalMr = salt.mr + Double(salt.x) * mrWater
        anhydrousMass = (hydratedMass * salt.mr / totalMr * 100).rounded() / 100
        massHistory = [hydratedMass]

        // Work out which heating number will actually reach constant mass (2 dp), so the
        // simulation can tell early declarations from correct ones.
        var n = 1
        while n < 8 {
            let a = massAfterHeatings(n)
            let b = massAfterHeatings(n - 1)
            if (a * 100).rounded() == (b * 100).rounded() { break }
            n += 1
        }
        trueConstantHeating = n
    }

    /// Physical model of progressive mass loss on repeated heating: an exponential decay
    /// toward the true anhydrous mass, so early heatings lose a lot and later ones lose
    /// almost nothing — mirroring what a student actually sees on the balance.
    private func massAfterHeatings(_ n: Int) -> Double {
        guard n > 0 else { return hydratedMass }
        let k = 1.7
        let gap = hydratedMass - anhydrousMass
        let remaining = anhydrousMass + gap * exp(-k * Double(n))
        return (remaining * 100).rounded() / 100
    }

    func heatSample() {
        guard !constantMass else { return }
        heatingCount += 1
        let newMass = massAfterHeatings(heatingCount)
        massHistory.append(newMass)
        lastDeclareWasPremature = false
        if heatingCount > trueConstantHeating { extraHeatingsAfterConstant += 1 }
    }

    /// True once two consecutive weighings agree to 2 dp — the real test for constant mass,
    /// not a hard-coded heating count.
    var isActuallyConstantNow: Bool {
        guard massHistory.count >= 3 else { return false } // need ≥2 heatings to compare two post-heat readings
        let last = massHistory[massHistory.count - 1]
        let previous = massHistory[massHistory.count - 2]
        return (last * 100).rounded() == (previous * 100).rounded()
    }

    var canDeclareConstant: Bool { heatingCount >= 2 && !constantMass }

    /// The student's own decision that mass is no longer changing. Either way the experiment
    /// moves on to the calculation step — if they're wrong, they just get a warning (and a
    /// scoring penalty) instead of being blocked, since real students do make this call
    /// themselves and should see the consequence of an early call rather than get stuck.
    func declareConstantMass() {
        guard canDeclareConstant else { return }
        constantMass = true
        if isActuallyConstantNow {
            lastDeclareWasPremature = false
        } else {
            prematureDeclarations += 1
            lastDeclareWasPremature = true
        }
    }

    var currentMass: Double { massHistory.last ?? hydratedMass }

    var massOfWater: Double {
        ((hydratedMass - currentMass) * 100).rounded() / 100
    }

    var molesAnhydrous: Double {
        currentMass / mrAnhydrous
    }

    var molesWater: Double {
        massOfWater / 18.0
    }

    var calculatedX: Double {
        guard molesAnhydrous > 0 else { return 0 }
        return molesWater / molesAnhydrous
    }

    func submitAnswer() {
        guard let x = Int(studentX) else { return }
        let correct = x == targetX
        var feedback: [String] = []

        if correct {
            feedback.append("Correct! The formula is \(saltOptions.first(where: { $0.name == saltName })?.formula ?? "")·\(targetX)H₂O")
            feedback.append("You heated \(heatingCount) time(s) to reach constant mass.")
        } else {
            feedback.append("The correct value is x = \(targetX).")
            feedback.append("Formula: \(saltOptions.first(where: { $0.name == saltName })?.formula ?? "")·\(targetX)H₂O")
            feedback.append("Moles of anhydrous salt: \(String(format: "%.4f", molesAnhydrous)) mol")
            feedback.append("Moles of water: \(String(format: "%.4f", molesWater)) mol")
            feedback.append("Ratio: \(String(format: "%.2f", calculatedX)) ≈ \(targetX)")
        }
        feedback.append("Key technique: heat gently to constant mass. Weigh after each heating until the mass no longer changes — this ensures all water of crystallisation has been driven off.")

        var mistakes: [PracticalMistake] = []
        if prematureDeclarations > 0 {
            mistakes.append(PracticalMistake(title: "Declared constant mass too early \(prematureDeclarations) time(s)", consequence: "Stopping before the mass genuinely stops changing means not all the water of crystallisation has been driven off, which would make the calculated mass of water — and x — too low."))
        }

        let constantMassSkill = max(0, 10 - prematureDeclarations * 4)
        let techniqueSkill = extraHeatingsAfterConstant <= 1 ? 10 : max(4, 10 - extraHeatingsAfterConstant * 2)
        let calcSkill = correct ? 10 : 4
        let totalScored = constantMassSkill + techniqueSkill + calcSkill
        let percentScore = Int((Double(totalScored) / 30.0) * 100)

        result = LabRunResult(
            correct: correct && prematureDeclarations == 0,
            score: percentScore,
            feedback: feedback,
            examTip: "Heat gently — too strong heating can decompose the salt. Weigh to constant mass (heat, cool, weigh, repeat until mass is unchanged). Round x to the nearest whole number.",
            skillMarks: [
                PracticalSkillMark(skill: "Judging constant mass", scored: constantMassSkill, outOf: 10),
                PracticalSkillMark(skill: "Heating technique", scored: techniqueSkill, outOf: 10),
                PracticalSkillMark(skill: "Calculation", scored: calcSkill, outOf: 10)
            ],
            mistakes: mistakes
        )
    }

    func reset() {
        hydratedMass = 0
        anhydrousMass = 0
        heatingCount = 0
        constantMass = false
        saltName = ""
        studentX = ""
        result = nil
        massHistory = []
        lastDeclareWasPremature = false
        prematureDeclarations = 0
        extraHeatingsAfterConstant = 0
    }
}

struct WaterOfCrystallisationView: View {
    let curriculum: Curriculum
    @StateObject private var model = WaterOfCrystallisationViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var didRecordResult = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Water of Crystallisation")
                    .font(.title.bold())

                Text("Determine the value of x in a hydrated salt by heating to constant mass and calculating the mole ratio.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Step 1: Select salt
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Select a hydrated salt")
                        .font(.headline)

                    ForEach(Array(model.saltOptions.enumerated()), id: \.offset) { _, salt in
                        Button {
                            model.selectSalt(salt)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(salt.name).font(.subheadline.bold())
                                    Text("\(salt.formula)·xH₂O (Mr = \(String(format: "%.1f", salt.mr)))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if model.saltName == salt.name {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                }
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !model.saltName.isEmpty {
                    // Step 2: Heat and weigh
                    VStack(alignment: .leading, spacing: 10) {
                        Text("2. Heat to constant mass")
                            .font(.headline)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Initial mass (hydrated)")
                                    .font(.caption)
                                Text("\(String(format: "%.2f", model.hydratedMass)) g")
                                    .font(.headline.monospacedDigit())
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current mass")
                                    .font(.caption)
                                Text("\(String(format: "%.2f", model.currentMass)) g")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(model.constantMass ? .green : .orange)
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Heating #")
                                    .font(.caption)
                                Text("\(model.heatingCount)")
                                    .font(.headline.monospacedDigit())
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                        if model.massHistory.count > 1 {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Weighings so far").font(.caption.bold())
                                ForEach(Array(model.massHistory.enumerated()), id: \.offset) { idx, mass in
                                    HStack {
                                        Text(idx == 0 ? "Before heating" : "After heating \(idx)").font(.caption2)
                                        Spacer()
                                        Text("\(String(format: "%.2f", mass)) g").font(.caption2.monospacedDigit())
                                    }
                                }
                            }
                        }

                        Button {
                            model.heatSample()
                        } label: {
                            Label(model.heatingCount == 0 ? "Heat sample (1st heating)" : model.constantMass ? "Constant mass reached" : "Heat again (\(model.heatingCount + 1))",
                                  systemImage: "flame.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.constantMass)

                        if model.canDeclareConstant {
                            Button("Compare readings: declare constant mass") { model.declareConstantMass() }
                                .buttonStyle(.bordered)
                        }

                        if model.constantMass && model.lastDeclareWasPremature {
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Careful — the mass was still falling between your last two readings, so this call was premature. You can continue to the calculation, but not all the water may have been driven off, which will affect your result.")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        } else if model.constantMass {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Constant mass reached — the last two weighings agree, so all water has been driven off")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        } else if model.heatingCount > 0 {
                            Text("Weigh, then decide for yourself whether the mass has stopped changing.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if model.constantMass {
                        // Step 3: Calculate
                        VStack(alignment: .leading, spacing: 12) {
                            Text("3. Calculate x")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                CalculationRow(label: "Mass of hydrated salt", value: "\(String(format: "%.2f", model.hydratedMass)) g")
                                CalculationRow(label: "Mass of anhydrous salt", value: "\(String(format: "%.2f", model.anhydrousMass)) g")
                                CalculationRow(label: "Mass of water lost", value: "\(String(format: "%.2f", model.massOfWater)) g")
                                CalculationRow(label: "Moles of anhydrous salt", value: "\(String(format: "%.4f", model.molesAnhydrous)) mol")
                                CalculationRow(label: "Moles of water", value: "\(String(format: "%.4f", model.molesWater)) mol")
                                CalculationRow(label: "x = moles water / moles salt", value: String(format: "%.2f", model.calculatedX), highlight: true)
                            }
                            .padding(12)
                            .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                            HStack {
                                Text("Your answer: x =")
                                    .font(.subheadline)
                                TextField("x", text: $model.studentX)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                            }

                            Button("Submit answer") {
                                model.submitAnswer()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.studentX.isEmpty)
                        }

                        if let result = model.result {
                            ResultCard(result: result)
                            Button("New sample") { model.reset() }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Water of Crystallisation")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.result?.score) { _, newValue in
            guard newValue != nil, !didRecordResult else { return }
            didRecordResult = true
            let repository = AttemptRepository(modelContext: modelContext)
            repository.save(curriculum: curriculum, mode: .simulationLab, target: "Water of Crystallisation · \(model.saltName)", score: model.result?.score ?? 0, maxScore: 100, feedback: model.result?.feedback ?? [])
        }
        .onChange(of: model.saltName) { _, newValue in
            if newValue.isEmpty { didRecordResult = false }
        }
    }
}

private struct CalculationRow: View {
    let label: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        HStack {
            Text(label).font(.caption)
            Spacer()
            Text(value)
                .font(highlight ? .headline.monospacedDigit() : .subheadline.monospacedDigit())
                .foregroundStyle(highlight ? Color.blue : Color.primary)
        }
    }
}

private struct ResultCard: View {
    let result: LabRunResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: result.correct ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(result.correct ? .green : .orange)
                Text(result.correct ? "Correct!" : "Review needed")
                    .font(.title3.bold())
            }
            Text("Score: \(result.score)%")
                .font(.headline)
            ForEach(result.feedback, id: \.self) { f in
                Text("• \(f)").font(.caption)
            }
            if !result.skillMarks.isEmpty {
                Divider()
                ForEach(result.skillMarks) { mark in
                    HStack {
                        Text(mark.skill).font(.caption2)
                        Spacer()
                        Text("\(mark.scored)/\(mark.outOf)").font(.caption2.monospacedDigit())
                    }
                }
            }
            if !result.mistakes.isEmpty {
                Divider()
                ForEach(result.mistakes) { mistake in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mistake.title).font(.caption.weight(.semibold))
                        Text(mistake.consequence).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Text("Exam tip: \(result.examTip)")
                .font(.caption.italic())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(result.correct ? Color.green.opacity(0.1) : Color.orange.opacity(0.1),
                   in: RoundedRectangle(cornerRadius: 16))
    }
}
