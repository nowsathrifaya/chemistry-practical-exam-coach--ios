//
//  StructuredMockExamView.swift
//  ChemistryCoach
//
//  Full-length original Paper 3-style mock for Singapore-Cambridge
//  O-Level Chemistry (6092). Structure follows the 2026 syllabus:
//  40 marks, 1 h 50 min, compulsory practical questions, with Planning
//  forming about 15% of the paper and MMO/PDO/ACE the remaining 85%.
//
//  This is original practice content, not copied examination material.
//

import SwiftUI

struct StructuredMockExamView: View {
    @State private var started = false
    @State private var currentIndex = 0
    @State private var userAnswers: [String] = Array(repeating: "", count: FullPaper3Mock.questions.count)
    @State private var submitted = false
    @State private var showSubmitConfirmation = false
    @State private var secondsRemaining = 110 * 60
    @State private var timerActive = false
    @State private var examTimerTask: Task<Void, Never>?
    @State private var pointMarks: [[Bool]] = FullPaper3Mock.questions.map { Array(repeating: false, count: $0.markingPoints.count) }

    private var totalMarks: Int { FullPaper3Mock.totalMarks }
    private var selfMarks: [Int] { pointMarks.map { $0.filter { $0 }.count } }
    private var awardedMarks: Int { selfMarks.reduce(0, +) }
    private var currentQuestion: FullPaper3MockQuestion { FullPaper3Mock.questions[currentIndex] }

    var body: some View {
        Group {
            if !started {
                instructionsView
            } else if submitted {
                resultView
            } else {
                examView
            }
        }
        .navigationTitle("Paper 3 Mock Examination")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopTimer() }
        .alert("Submit examination?", isPresented: $showSubmitConfirmation) {
            Button("Continue Exam", role: .cancel) { }
            Button("Submit", role: .destructive) { submitExam() }
        } message: {
            Text("Once submitted, the timed attempt will end. You can then compare your answers with the marking points.")
        }
    }

    // MARK: - Instructions

    private var instructionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GCE O-Level Chemistry")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Paper 3 · Practical Mock Examination")
                        .font(.largeTitle.bold())
                    HStack(spacing: 14) {
                        Label("40 marks", systemImage: "checkmark.circle")
                        Label("1 h 50 min", systemImage: "timer")
                    }
                    .font(.subheadline.weight(.semibold))
                }

                infoCard(title: "Before you begin", icon: "doc.text.fill") {
                    bullet("This is a full-length original Paper 3-style practice paper.")
                    bullet("All questions are compulsory.")
                    bullet("Suggested examination time: 1 hour 50 minutes.")
                    bullet("Do not use your notes or revision materials during the attempt if you want a realistic simulation.")
                    bullet("Write calculations clearly and include units where appropriate.")
                    bullet("For observations, describe what you would actually see rather than writing an inference.")
                }

                infoCard(title: "Paper structure", icon: "list.number") {
                    structureRow("Question 1", "Titration", 10)
                    structureRow("Question 2", "Rate investigation + data", 8)
                    structureRow("Question 3", "Qualitative analysis", 8)
                    structureRow("Question 4", "Salt preparation + separation", 7)
                    structureRow("Question 5", "Energetics + electrolysis", 7)
                    Divider()
                    structureRow("Total", "Compulsory questions", 40)
                }

                infoCard(title: "Skills assessed", icon: "flask.fill") {
                    Text("Planning (P) ≈ 6 marks · MMO/PDO/ACE ≈ 34 marks")
                        .font(.subheadline.weight(.semibold))
                    Text("The mock uses the Paper 3 skill areas: Planning, Manipulation/Measurement/Observation, Presentation of Data/Observations, and Analysis/Conclusions/Evaluation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    startExam()
                } label: {
                    Label("Begin 1 h 50 min examination", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(20)
        }
    }

    // MARK: - Examination

    private var examView: some View {
        VStack(spacing: 0) {
            timerHeader
            ProgressView(value: Double(currentIndex + 1), total: Double(FullPaper3Mock.questions.count))
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("Question \(currentIndex + 1) of \(FullPaper3Mock.questions.count)")
                                .font(.headline)
                            Spacer()
                            Text("\(currentQuestion.marks) marks")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.orange.opacity(0.14), in: Capsule())
                        }

                        Text(currentQuestion.title)
                            .font(.title2.bold())

                        Text(currentQuestion.questionText)
                            .font(.body)
                            .textSelection(.enabled)

                        Text("Your answer")
                            .font(.headline)

                        TextEditor(text: Binding(
                            get: { userAnswers[currentIndex] },
                            set: { userAnswers[currentIndex] = $0 }
                        ))
                        .font(.body)
                        .frame(minHeight: 300)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.35)))

                        Text("Tip: You may answer all sub-parts in the same box. Label your answers (a), (b), (c)… clearly.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Button {
                                if currentIndex > 0 {
                                    currentIndex -= 1
                                    proxy.scrollTo("top", anchor: .top)
                                }
                            } label: {
                                Label("Previous", systemImage: "chevron.left")
                            }
                            .buttonStyle(.bordered)
                            .disabled(currentIndex == 0)

                            Spacer()

                            if currentIndex < FullPaper3Mock.questions.count - 1 {
                                Button {
                                    currentIndex += 1
                                    proxy.scrollTo("top", anchor: .top)
                                } label: {
                                    Label("Next", systemImage: "chevron.right")
                                }
                                .buttonStyle(.borderedProminent)
                            } else {
                                Button("Finish & Submit") {
                                    showSubmitConfirmation = true
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                        }
                    }
                    .id("top")
                    .padding(20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var timerHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: secondsRemaining <= 300 ? "exclamationmark.triangle.fill" : "timer")
                .foregroundStyle(secondsRemaining <= 300 ? .red : .primary)
            Text(timeString)
                .font(.system(.headline, design: .monospaced).weight(.bold))
                .foregroundStyle(secondsRemaining <= 300 ? .red : .primary)
            Spacer()
            Text("Paper 3 · 40 marks")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var timeString: String {
        let hours = secondsRemaining / 3600
        let minutes = (secondsRemaining % 3600) / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Results

    private var resultView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)
                    Text("Examination Complete")
                        .font(.largeTitle.bold())
                    Text("Marked score: \(awardedMarks) / \(totalMarks)")
                        .font(.title3.weight(.semibold))
                    Text("Paper 3-style practice · 40 marks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                Text("Mark each criterion")
                    .font(.headline)

                Text("Each marking point is one criterion. Tick a point only when your answer contains that specific idea. This produces a transparent self-mark rather than a keyword-based automatic mark.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(FullPaper3Mock.questions.indices, id: \.self) { index in
                    resultQuestionCard(index: index)
                }

                Button("Attempt the full paper again") {
                    resetExam()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .navigationBarBackButtonHidden(false)
    }

    private func resultQuestionCard(index: Int) -> some View {
        let question = FullPaper3Mock.questions[index]
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Question \(index + 1)")
                    .font(.headline)
                Spacer()
                Text("\(selfMarks[index]) / \(question.marks)")
                    .font(.headline)
                    .foregroundStyle(selfMarks[index] == question.marks ? .green : .primary)
            }

            Text(question.title)
                .font(.subheadline.weight(.semibold))

            Text("Your answer")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(userAnswers[index].isEmpty ? "No answer entered." : userAnswers[index])
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            Text("Marking points")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(question.markingPoints.enumerated()), id: \.offset) { pointIndex, point in
                Button {
                    pointMarks[index][pointIndex].toggle()
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: pointMarks[index][pointIndex] ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(pointMarks[index][pointIndex] ? .green : .secondary)
                        Text(point)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }

            Text("Awarded: \(selfMarks[index]) / \(question.markingPoints.count) criteria")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(15)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Helpers

    private func infoCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.subheadline)
    }

    private func structureRow(_ number: String, _ topic: String, _ marks: Int) -> some View {
        HStack {
            Text(number).font(.subheadline.weight(.semibold))
            Text(topic).font(.subheadline)
            Spacer()
            Text("\(marks)")
                .font(.caption.bold())
                .frame(width: 32)
        }
    }

    private func startExam() {
        started = true
        submitted = false
        secondsRemaining = 110 * 60
        timerActive = true
        examTimerTask?.cancel()
        examTimerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, timerActive else { break }
                if secondsRemaining > 0 {
                    secondsRemaining -= 1
                } else {
                    submitExam()
                    break
                }
            }
        }
    }

    private func stopTimer() {
        examTimerTask?.cancel()
        examTimerTask = nil
        timerActive = false
    }

    private func submitExam() {
        stopTimer()
        submitted = true
    }

    private func resetExam() {
        stopTimer()
        started = false
        submitted = false
        currentIndex = 0
        userAnswers = Array(repeating: "", count: FullPaper3Mock.questions.count)
        pointMarks = FullPaper3Mock.questions.map { Array(repeating: false, count: $0.markingPoints.count) }
        secondsRemaining = 110 * 60
    }
}

// MARK: - Original full Paper 3 mock content

struct FullPaper3MockQuestion: Identifiable {
    let id: Int
    let title: String
    let marks: Int
    let questionText: String
    let markingPoints: [String]
}

enum FullPaper3Mock {
    static let questions: [FullPaper3MockQuestion] = [
        .init(id: 1, title: "Titration — measurement, data and calculation", marks: 10, questionText: """
QUESTION 1

A student uses a standard solution of 0.100 mol dm⁻³ sodium hydroxide to determine the concentration of hydrochloric acid.

(a) State the apparatus used to transfer exactly 25.0 cm³ of the hydrochloric acid into a conical flask. [1]

(b) State how the burette should be prepared before the titration. Include the solution used for rinsing. [2]

(c) The initial burette reading is 0.10 cm³. The final readings for four titrations are 23.70 cm³, 23.20 cm³, 23.15 cm³ and 23.25 cm³.

(i) Calculate the titre for each titration. [2]
(ii) Identify the concordant titres. [1]
(iii) Calculate the mean concordant titre. Give your answer to 2 decimal places. [1]

(d) The reaction is:
HCl + NaOH → NaCl + H₂O

Use the mean titre to calculate the concentration of the hydrochloric acid. Show your working. [2]

(e) State one reason why the rough titre is not included when calculating the mean titre. [1]
""", markingPoints: [
            "(a) 25.0 cm³ volumetric pipette with pipette filler.",
            "(b) Rinse the burette with the solution that will be placed in it, then rinse/fill with the titrant and ensure the jet is filled with solution without bubbles.",
            "(c)(i) Titrés: 23.60, 23.10, 23.05 and 23.15 cm³.",
            "(c)(ii) Concordant titres: 23.10, 23.05 and 23.15 cm³.",
            "(c)(iii) Mean = (23.10 + 23.05 + 23.15) / 3 = 23.10 cm³.",
            "(d) Moles NaOH = 0.100 × 23.10/1000 = 0.002310 mol. 1:1 ratio, so moles HCl = 0.002310 mol in 25.0 cm³. Concentration = 0.002310/0.0250 = 0.0924 mol dm⁻³.",
            "(e) A rough titre is only used to locate the end-point approximately and may be affected by overshooting; it is not used for the accurate mean."
        ]),

        .init(id: 2, title: "Rate of reaction — planning and data analysis", marks: 8, questionText: """
QUESTION 2

A student investigates the effect of temperature on the rate of reaction between sodium thiosulfate solution and dilute hydrochloric acid. The reaction produces sulfur, making a mark beneath the reaction flask harder to see.

(a) State the independent variable and the dependent variable. [2]

(b) State two variables that must be kept constant for a fair test. [2]

(c) Describe a suitable method for carrying out the investigation at several temperatures. Your method should include how the temperature is controlled and how the reaction time is measured. [2]

(d) The following results were obtained:

Temperature / °C: 20   30   40   50
Time / s:          96   67   49   36

(i) Which temperature gives the fastest reaction? [1]
(ii) Explain how the results support the conclusion that increasing temperature increases the rate of reaction. [1]
""", markingPoints: [
            "(a) Independent variable: temperature. Dependent variable: time for the cross/mark to disappear (or rate calculated from time).",
            "(b) Examples: volumes and concentrations of sodium thiosulfate and hydrochloric acid; same apparatus; same viewing method/cross; same total reaction volume.",
            "(c) Use a water bath to bring reactants to the chosen temperature; mix the same measured volumes/concentrations, start the stopwatch immediately and stop when the cross can no longer be seen; repeat at other temperatures and preferably repeat trials.",
            "(d)(i) 50 °C.",
            "(d)(ii) Reaction time decreases as temperature rises (96 s → 36 s), so the reaction is faster at higher temperature."
        ]),

        .init(id: 3, title: "Qualitative analysis — observations and inference", marks: 8, questionText: """
QUESTION 3

A solution contains one cation and one anion. The following tests are carried out.

Test 1: Aqueous sodium hydroxide is added. A pale blue precipitate forms and remains insoluble when excess sodium hydroxide is added.

Test 2: Dilute nitric acid is added to a fresh portion of the solution, followed by aqueous silver nitrate. A white precipitate forms.

(a) State the observation in Test 1 and identify the cation. [2]

(b) State the observation in Test 2 and identify the anion. [2]

(c) Explain why dilute nitric acid is used instead of hydrochloric acid before the silver nitrate test. [2]

(d) Write the ionic equation for the reaction producing the precipitate in Test 2. Include state symbols. [1]

(e) State one additional observation that would be useful when recording a qualitative analysis experiment. [1]
""", markingPoints: [
            "(a) Pale/light blue precipitate, insoluble in excess NaOH; copper(II), Cu²⁺.",
            "(b) White precipitate with acidified silver nitrate; chloride, Cl⁻.",
            "(c) Hydrochloric acid contains chloride ions and could produce a false positive with AgNO₃; nitric acid does not introduce chloride ions.",
            "(d) Ag⁺(aq) + Cl⁻(aq) → AgCl(s).",
            "(e) Any valid visible observation such as colour of solution, colour/amount/solubility of precipitate, effervescence, or colour of flame where relevant."
        ]),

        .init(id: 4, title: "Preparation of a soluble salt — planning and technique", marks: 7, questionText: """
QUESTION 4

A student needs to prepare a pure, dry sample of copper(II) sulfate crystals from dilute sulfuric acid and copper(II) oxide.

(a) Explain why copper(II) oxide is added in excess. [1]

(b) Describe the procedure from mixing the reactants until the crystals are obtained. Include filtration and crystallisation. [4]

(c) State one reason why the solution should not be evaporated to complete dryness. [1]

(d) State one safety precaution for this experiment. [1]
""", markingPoints: [
            "(a) To ensure all sulfuric acid is neutralised/used up so no acid remains in the final solution.",
            "(b) Warm the dilute sulfuric acid, add copper(II) oxide in small portions with stirring until no more reacts/solid remains; filter to remove excess solid; gently heat the filtrate to concentrate it; allow it to cool so crystals form; filter and dry the crystals.",
            "(c) Heating to dryness can cause decomposition/splashing and does not give controlled crystallisation; the aim is to crystallise the salt while retaining suitable water for crystallisation.",
            "(d) Wear eye protection and handle hot acid/solution carefully; any equivalent valid precaution."
        ]),

        .init(id: 5, title: "Energetics and electrolysis — calculation and evaluation", marks: 7, questionText: """
QUESTION 5

PART A — Energetics

50.0 cm³ of 1.0 mol dm⁻³ hydrochloric acid is mixed with 50.0 cm³ of 1.0 mol dm⁻³ sodium hydroxide in an insulated cup. The temperature rises from 24.0 °C to 30.2 °C.

(a) Calculate the temperature change. [1]

(b) Assuming the density of the solution is 1.0 g cm⁻³ and its specific heat capacity is 4.2 J g⁻¹ °C⁻¹, calculate the energy released. [2]

(c) State one improvement that would reduce heat loss to the surroundings. [1]

PART B — Electrolysis

Aqueous copper(II) sulfate is electrolysed using copper electrodes.

(d) State the observation at the cathode. [1]

(e) State what happens to the copper anode. [1]

(f) Write the half-equation for the reaction at the cathode. [1]
""", markingPoints: [
            "(a) ΔT = 30.2 − 24.0 = 6.2 °C.",
            "(b) Total mass = 100 g. q = mcΔT = 100 × 4.2 × 6.2 = 2604 J = 2.604 kJ released.",
            "(c) Use a lid and/or better insulation around the cup; equivalent valid improvement accepted.",
            "(d) Reddish-brown copper is deposited at the cathode; the cathode gains mass.",
            "(e) Copper at the anode dissolves/oxidises and the anode loses mass.",
            "(f) Cu²⁺(aq) + 2e⁻ → Cu(s)."
        ])
    ]

    static var totalMarks: Int { questions.reduce(0) { $0 + $1.marks } }
}
