//
//  StructuredMockExamView.swift
//  ChemistryCoach
//
//  Interactive structured mock exam with 5 Paper 3 style questions.
//  Students attempt each question, then reveal the model answer and
//  self-assess against marking points.
//

import SwiftUI

struct StructuredMockExamView: View {
    @State private var currentIndex = 0
    @State private var userAnswers: [String] = Array(repeating: "", count: StructuredMockExam.questions.count)
    @State private var revealedAnswers = Set<Int>()
    @State private var selfMarks: [Int] = Array(repeating: 0, count: StructuredMockExam.questions.count)
    @State private var submitted = false

    private var totalMarks: Int { StructuredMockExam.questions.reduce(0) { $0 + $1.marks } }
    private var awardedMarks: Int { selfMarks.reduce(0, +) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Structured Mock Exam")
                        .font(.largeTitle.bold())
                    Text("Paper 3 style · \(totalMarks) marks · ~110 minutes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Progress
                ProgressView(value: Double(currentIndex + 1), total: Double(StructuredMockExam.questions.count))
                Text("Question \(currentIndex + 1) of \(StructuredMockExam.questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Current question
                let question = StructuredMockExam.questions[currentIndex]

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(question.title)
                            .font(.headline)
                        Spacer()
                        Text("\(question.marks) marks")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }

                    Text(question.questionText)
                        .font(.body)

                    TextEditor(text: Binding(
                        get: { userAnswers[currentIndex] },
                        set: { userAnswers[currentIndex] = $0 }
                    ))
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.secondary, lineWidth: 0.5))

                    if revealedAnswers.contains(currentIndex) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                Text("Model answer")
                                    .font(.headline)
                            }

                            Text(question.modelAnswer)
                                .font(.subheadline)

                            if !question.markingPoints.isEmpty {
                                Text("Marking points:")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                ForEach(Array(question.markingPoints.enumerated()), id: \.offset) { _, point in
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 5))
                                            .foregroundStyle(.green)
                                            .padding(.top, 5)
                                        Text(point)
                                            .font(.caption)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Self-assessment: \(selfMarks[currentIndex]) / \(question.marks) marks")
                                    .font(.caption.bold())
                                Stepper("Award marks: \(selfMarks[currentIndex]) / \(question.marks)",
                                        value: Binding(
                                            get: { selfMarks[currentIndex] },
                                            set: { selfMarks[currentIndex] = min(max($0, 0), question.marks) }
                                        ),
                                        in: 0...question.marks)
                                    .font(.caption)
                            }
                        }
                        .padding(14)
                        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                        Button("Hide answer") { revealedAnswers.remove(currentIndex) }
                            .font(.caption)
                    } else {
                        Button("Reveal model answer") { revealedAnswers.insert(currentIndex) }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                // Navigation
                HStack {
                    Button("Previous") {
                        if currentIndex > 0 { currentIndex -= 1 }
                    }
                    .disabled(currentIndex == 0)
                    .buttonStyle(.bordered)

                    Spacer()

                    if currentIndex < StructuredMockExam.questions.count - 1 {
                        Button("Next question") { currentIndex += 1 }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Button("Submit exam") {
                            submitted = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }

                if submitted {
                    VStack(spacing: 8) {
                        Text("Exam complete")
                            .font(.title.bold())
                        Text("Your self-assessed score: \(awardedMarks) / \(totalMarks) marks")
                            .font(.headline)
                        Text("Review the questions you scored lowest on and revisit the corresponding revision materials.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Restart") {
                            currentIndex = 0
                            userAnswers = Array(repeating: "", count: StructuredMockExam.questions.count)
                            revealedAnswers.removeAll()
                            selfMarks = Array(repeating: 0, count: StructuredMockExam.questions.count)
                            submitted = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .navigationTitle("Structured Mock Exam")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Question Data

struct StructuredMockQuestion: Identifiable {
    let id: Int
    let title: String
    let marks: Int
    let questionText: String
    let modelAnswer: String
    let markingPoints: [String]
}

enum StructuredMockExam {
    static let questions: [StructuredMockQuestion] = [
        .init(
            id: 0,
            title: "1. Titration (MMO + PDO + ACE)",
            marks: 12,
            questionText: """
            A student carries out a titration to find the concentration of sulfuric acid (H₂SO₄) using a standard solution of 0.100 mol/dm³ sodium hydroxide (NaOH).

            (a) Describe how to prepare 250 cm³ of 0.100 mol/dm³ NaOH from solid. [3]
            (b) The student uses 25.0 cm³ of NaOH per titration. How is this measured accurately? [1]
            (c) Titration results: 23.50, 23.20, 23.15, 23.30 cm³ (initial = 0.00). Identify concordant titres and calculate the mean. [2]
            (d) H₂SO₄ + 2NaOH → Na₂SO₄ + 2H₂O. Calculate the concentration of H₂SO₄. [4]
            (e) Give two sources of error and how each is minimised. [2]
            """,
            modelAnswer: """
            (a) Weigh 1.00 g NaOH (0.100 × 0.250 × 40 = 1.00 g). Dissolve in distilled water in a beaker. Transfer to a 250 cm³ volumetric flask, washing the beaker into the flask. Make up to the mark with distilled water. Stopper and invert to mix.
            (b) Use a 25.0 cm³ pipette with a pipette filler.
            (c) Concordant: 23.20, 23.15, 23.30 cm³ (all within 0.20 cm³). 23.50 is a rough titre. Mean = (23.20 + 23.15 + 23.30) / 3 = 23.22 cm³. (Accept 23.18 using tightest pair.)
            (d) Moles NaOH = 0.100 × 0.0250 = 0.00250 mol. Mole ratio 1:2, so moles H₂SO₄ = 0.00125 mol. Volume = 23.22 cm³ = 0.02322 dm³. Concentration = 0.00125 / 0.02322 = 0.0538 mol/dm³.
            (e) Parallax error — read burette at eye level, bottom of meniscus. Not rinsing burette with titrant — rinse with the solution it will contain. Adding too fast near endpoint — add dropwise.
            """,
            markingPoints: [
                "(a) Correct mass calculation (1.00 g); use of volumetric flask; wash beaker into flask; make up to mark; mix",
                "(b) Pipette (25.0 cm³) with pipette filler",
                "(c) Identify 23.20, 23.15, 23.30 as concordant; 23.50 as rough; correct mean calculation",
                "(d) Balanced equation; moles NaOH = 0.00250; divide by 2 for H₂SO₄; convert cm³ to dm³; final concentration",
                "(e) Two specific errors with matching minimisations"
            ]
        ),
        .init(
            id: 1,
            title: "2. Qualitative Analysis (MMO + ACE)",
            marks: 10,
            questionText: """
            You are given two solid samples, P and Q.

            Solid P: Flame test gives yellow flame. Adding dilute HNO₃ produces effervescence; gas turns limewater milky.
            Solid Q: Adding dilute HNO₃ then AgNO₃ gives white precipitate. Adding NaOH gives light blue precipitate, insoluble in excess.

            (a) Identify P and give the ion tests. [3]
            (b) Identify Q and give the ion tests. [3]
            (c) Explain why nitric acid is used (not HCl) before adding AgNO₃. [1]
            (d) Write the ionic equation for the silver nitrate test. [1]
            (e) Give one common mistake students make in QA recording. [2]
            """,
            modelAnswer: """
            (a) P = Sodium carbonate (Na₂CO₃). Na⁺ identified by yellow flame test. CO₃²⁻ identified by adding dilute acid → effervescence → CO₂ turns limewater milky.
            (b) Q = Copper(II) chloride (CuCl₂). Cu²⁺ identified by light blue precipitate with NaOH, insoluble in excess. Cl⁻ identified by white precipitate with acidified AgNO₃.
            (c) HCl contains Cl⁻ ions which would give a false positive white precipitate with AgNO₃. HNO₃ does not interfere because all nitrates are soluble.
            (d) Ag⁺(aq) + Cl⁻(aq) → AgCl(s)
            (e) Writing an inference as an observation. "Chloride ion present" is an inference; "white precipitate formed" is the observation. Record what you SEE first, then state the inference.
            """,
            markingPoints: [
                "(a) Yellow flame → Na⁺; acid + gas test → CO₃²⁻; name as sodium carbonate",
                "(b) Blue ppt with NaOH → Cu²⁺; white ppt with AgNO₃ → Cl⁻; name as copper(II) chloride",
                "(c) HCl introduces Cl⁻ → false positive; HNO₃ does not interfere",
                "(d) Ag⁺ + Cl⁻ → AgCl(s)",
                "(e) Distinguish observation from inference with example"
            ]
        ),
        .init(
            id: 2,
            title: "3. Planning — Rate of Reaction",
            marks: 6,
            questionText: """
            Plan an experiment to investigate how temperature affects the rate of reaction between sodium thiosulfate and hydrochloric acid.
            Na₂S₂O₃ + 2HCl → 2NaCl + S + H₂O + SO₂

            (a) State the independent, dependent, and two controlled variables. [2]
            (b) Describe the procedure. [3]
            (c) State one safety precaution. [1]
            """,
            modelAnswer: """
            (a) IV: Temperature of reaction mixture (e.g. 20, 30, 40, 50, 60°C). DV: Time for cross beneath flask to disappear (s). CVs: Volume and concentration of Na₂S₂O₃ and HCl; same flask; same cross.
            (b) 1. Measure 50 cm³ Na₂S₂O₃ into conical flask over a cross. 2. Heat to desired temperature using water bath; check with thermometer. 3. Measure 10 cm³ HCl. 4. Add HCl, start stopwatch immediately. 5. Look down at cross; stop timer when cross disappears. 6. Record time. 7. Repeat at different temperatures. 8. Repeat each temperature and calculate mean.
            (c) SO₂ is produced — irritating to respiratory system. Work in a well-ventilated room or fume cupboard. Wear goggles.
            """,
            markingPoints: [
                "(a) IV: temperature; DV: time for cross to disappear; CVs: volume/concentration/identity of reactants; same apparatus",
                "(b) Use water bath for temperature control; start timer at mixing; observe cross; repeat; calculate mean",
                "(c) SO₂ hazard; ventilation or fume cupboard; goggles"
            ]
        ),
        .init(
            id: 3,
            title: "4. Energy Changes / Calorimetry",
            marks: 7,
            questionText: """
            A student mixes 50 cm³ of 1.0 mol/dm³ HCl with 50 cm³ of 1.0 mol/dm³ NaOH in a polystyrene cup. Temperature changes from 22.0°C to 28.6°C.

            (a) Calculate the energy released (c = 4.2 J/g/°C, assume 1 cm³ = 1 g). [3]
            (b) Calculate the enthalpy change per mole of water formed. [2]
            (c) Give two ways to improve accuracy. [2]
            """,
            modelAnswer: """
            (a) Total mass = 50 + 50 = 100 g. ΔT = 28.6 − 22.0 = 6.6°C. q = m × c × ΔT = 100 × 4.2 × 6.6 = 2772 J = 2.772 kJ.
            (b) Moles HCl = 1.0 × 0.050 = 0.050 mol. Moles NaOH = 1.0 × 0.050 = 0.050 mol. Mole ratio 1:1, so moles H₂O = 0.050 mol. ΔH = −2.772 / 0.050 = −55.4 kJ/mol (negative = exothermic).
            (c) Use a lid on the cup to reduce heat loss. Use a digital thermometer for precision. Plot a cooling curve and extrapolate. Insulate further (cotton wool). Stir continuously.
            """,
            markingPoints: [
                "(a) Total mass = 100 g; ΔT = 6.6°C; q = 2772 J = 2.772 kJ",
                "(b) Moles = 0.050; ΔH = −55.4 kJ/mol; correct sign (negative)",
                "(c) Two specific improvements with justification"
            ]
        ),
        .init(
            id: 4,
            title: "5. Water of Crystallisation",
            marks: 5,
            questionText: """
            5.50 g of hydrated magnesium sulfate (MgSO₄·xH₂O) is heated to constant mass. The anhydrous salt weighs 2.70 g.
            (Mr: Mg = 24, S = 32, O = 16, H = 1)

            (a) Calculate the mass of water lost. [1]
            (b) Calculate moles of anhydrous MgSO₄ and moles of water. [2]
            (c) Determine x and write the formula. [2]
            """,
            modelAnswer: """
            (a) Mass of water = 5.50 − 2.70 = 2.80 g
            (b) Mr(MgSO₄) = 24 + 32 + (4 × 16) = 120. Moles MgSO₄ = 2.70 / 120 = 0.0225 mol. Mr(H₂O) = 18. Moles H₂O = 2.80 / 18 = 0.1556 mol.
            (c) x = 0.1556 / 0.0225 = 6.92 ≈ 7. Formula: MgSO₄·7H₂O
            """,
            markingPoints: [
                "(a) Mass water = 2.80 g",
                "(b) Mr MgSO₄ = 120; moles = 0.0225; Mr H₂O = 18; moles = 0.1556",
                "(c) Ratio = 6.92 ≈ 7; formula MgSO₄·7H₂O"
            ]
        )
    ]
}
