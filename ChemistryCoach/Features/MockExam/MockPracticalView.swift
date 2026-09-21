//
//  MockPracticalView.swift
//  ChemistryCoach
//
//  v6: Paper 3-style practical mock rebuilt against the real SEAB 6092
//  "O" Level Chemistry scheme of assessment, so the shape of the mock
//  (not just its content) matches what students will actually sit.
//
//  Sources (structure/weighting only — no exam text is reproduced):
//   • SEAB 6092 syllabus (2026), "Scheme of Assessment" and "Practical
//     Assessment" sections: Paper 3 is 40 marks / 1 h 50 min, and within
//     Paper 3 the skills are weighted Planning ≈15%, MMO/PDO/ACE ≈85%.
//     https://www.seab.gov.sg/files/O%20Lvl%20Syllabus%20Sch%20Cddts/2026/6092_y26_sy.pdf
//   • SEAB 6092 specimen papers (for examination from 2024), for question
//     style and the P / MMO / PDO / ACE terminology used throughout.
//     https://www.seab.gov.sg/files/O%20Lvl%20Syllabus%20Sch%20Cddts/2025/6092_y24_sp_1.pdf
//     https://www.seab.gov.sg/files/O%20Lvl%20Syllabus%20Private%20Cddts/2025/6092_y24_sp_2.pdf
//
//  This mock is a shorter, original-question set built to the *same
//  proportions* as the real paper (skill weighting, not question text),
//  so a 20/20 here tracks roughly the same profile as strong Paper 3
//  performance. It is deliberately not full-length (40 marks / 1 h 50)
//  so it can be attempted in one sitting; the real paper is longer.
//

import SwiftUI
import SwiftData

struct MockPracticalQuestion: Identifiable, Hashable {
    let id: String
    let skillArea: AceSkillArea
    let maxMarks: Int
    let prompt: String
    let markingPoints: [String]
    let modelAnswer: String
    /// One keyword group per available mark; a mark is earned if the
    /// student's answer contains any keyword from that group.
    let keywords: [[String]]
}

enum MockPracticalQuestionBank {
    // Marks below sum to 20 (Planning 3 / MMO 5 / PDO 5 / ACE 7), the
    // same ≈15% : 85% Planning vs MMO+PDO+ACE split SEAB uses for the
    // full 40-mark Paper 3.
    static let questions: [MockPracticalQuestion] = [
        .init(id: "mp_plan1", skillArea: .planning, maxMarks: 3,
              prompt: "A student wants to compare the rate of reaction between excess dilute hydrochloric acid and magnesium ribbon at three different acid concentrations, using the volume of hydrogen gas produced. Name the apparatus you would use to measure the gas, and state two variables that must be kept constant for the comparison to be fair.",
              markingPoints: ["Gas syringe (or an inverted measuring cylinder filled with water)", "Same length/mass of magnesium ribbon in every run", "Same total volume of acid and same temperature in every run"],
              modelAnswer: "Use a gas syringe (or collect the gas in an inverted, water-filled measuring cylinder) and record the volume at fixed time intervals. Keep the length/mass of magnesium the same in every run, and keep the volume of acid and the temperature the same in every run — only the concentration should change.",
              keywords: [["gas syringe", "measuring cylinder"], ["mass", "length"], ["temperature", "volume of acid"]]),

        .init(id: "mp_mmo1", skillArea: .mmo, maxMarks: 2,
              prompt: "A student's burette reads 0.20 cm³ before starting a titration and 23.45 cm³ at the end-point. State the titre, and explain why the reading should be taken at the bottom of the meniscus, at eye level.",
              markingPoints: ["Titre = 23.25 cm³ (23.45 − 0.20)", "Reading at eye level, at the bottom of the meniscus, avoids parallax error"],
              modelAnswer: "Titre = 23.45 − 0.20 = 23.25 cm³. The reading is taken at eye level at the bottom of the meniscus so the line of sight is perpendicular to the scale, avoiding parallax error.",
              keywords: [["23.25"], ["parallax", "eye level"]]),

        .init(id: "mp_mmo2", skillArea: .mmo, maxMarks: 3,
              prompt: "Describe how a student should use a pipette filler to measure exactly 25.0 cm³ of dilute acid into a conical flask, including one precaution that avoids a systematic error.",
              markingPoints: ["Rinse the pipette with the acid to be measured before use", "Fill to just above the graduation mark, then let liquid out until the bottom of the meniscus sits on the mark at eye level", "Deliver into the flask by touching the pipette tip against the inside wall, without blowing out the last drop left in the tip"],
              modelAnswer: "Rinse the pipette with the acid first so the concentration is not diluted by residual water. Draw liquid to just above the graduation mark, then lower it until the bottom of the meniscus is level with the mark (read at eye level). Deliver into the flask by resting the tip against the inside wall; do not blow out the small amount of liquid left in the tip, since the pipette is calibrated to allow for it.",
              keywords: [["rinse"], ["graduation", "eye level", "meniscus"], ["inside wall", "without blowing", "not blow"]]),

        .init(id: "mp_pdo1", skillArea: .pdo, maxMarks: 2,
              prompt: "A rough titre of 24.90 cm³ and two accurate titres of 24.15 cm³ and 24.20 cm³ are obtained. State which value(s) should be used to calculate the mean titre, and give the mean to an appropriate number of decimal places.",
              markingPoints: ["Use only the two concordant accurate titres, 24.15 and 24.20 cm³ (ignore the rough titre)", "Mean = 24.18 cm³ (2 d.p., matching burette precision)"],
              modelAnswer: "Only 24.15 and 24.20 cm³ are used — they are concordant (within 0.10 cm³) — the rough titre is for guidance only and is excluded. Mean = (24.15 + 24.20) / 2 = 24.175, recorded as 24.18 cm³ to match the precision of the burette.",
              keywords: [["24.15", "24.20"], ["24.18", "24.175"]]),

        .init(id: "mp_pdo2", skillArea: .pdo, maxMarks: 3,
              prompt: "A student records the volume of gas produced against time during a rate experiment. State the two column headings (with units) this results table needs, and explain why a stopwatch, rather than an estimate, should be used to measure time.",
              markingPoints: ["Time / s", "Volume of gas / cm³", "A stopwatch gives precise, repeatable readings and removes reaction-time/estimation error"],
              modelAnswer: "Time / s and Volume of gas / cm³. A stopwatch is used because estimating time introduces human reaction-time error and would make readings inconsistent between repeats; a stopwatch gives a precise, repeatable measurement.",
              keywords: [["time", "s"], ["volume", "cm"], ["precise", "accurate", "reduces error", "repeatable"]]),

        .init(id: "mp_ace1", skillArea: .ace, maxMarks: 3,
              prompt: "In a set of five gas-volume readings taken every 30 seconds, one value is much lower than the trend of the other four. Explain what should be checked before treating this value as anomalous, and how it should be handled once confirmed anomalous.",
              markingPoints: ["Check for an error in technique/apparatus at that reading (e.g. a leak, a misread scale) rather than assuming it is wrong", "If confirmed anomalous, exclude it from the line of best fit/any mean calculated", "The raw value is still recorded in the table, not deleted — it is simply not used in further working"],
              modelAnswer: "Before dismissing it, check whether there was an identifiable error at that point (a gas leak, a misread scale, a timing slip), rather than assuming it is wrong just because it doesn't fit. If a cause is found (or the point clearly breaks the trend with no better explanation), it is excluded from the best-fit line or mean, but the original reading stays in the results table rather than being deleted.",
              keywords: [["check", "error", "leak", "technique"], ["exclude", "best fit", "not used", "ignored"], ["not deleted", "still recorded", "kept in the table"]]),

        .init(id: "mp_ace2", skillArea: .ace, maxMarks: 2,
              prompt: "A solution gives a white precipitate with aqueous ammonia that does not dissolve when excess ammonia is added. Which cation does this indicate, and what further test would help confirm it?",
              markingPoints: ["Aluminium ion, Al³⁺", "Confirm with aqueous sodium hydroxide: the white precipitate formed would dissolve in excess NaOH (unlike with excess ammonia)"],
              modelAnswer: "This indicates the aluminium ion, Al³⁺ — its hydroxide precipitate does not redissolve in excess ammonia (unlike zinc's). This can be confirmed with aqueous sodium hydroxide: Al(OH)₃ forms as a white precipitate that does dissolve in excess NaOH.",
              keywords: [["aluminium", "al3+", "al 3+"], ["sodium hydroxide", "naoh", "dissolves in excess"]]),

        .init(id: "mp_ace3", skillArea: .ace, maxMarks: 2,
              prompt: "In a calorimetry experiment, a student records the maximum temperature reached but does not account for heat lost to the surroundings while mixing. Explain the effect this has on the measured temperature change, and suggest one improvement.",
              markingPoints: ["The measured temperature change is smaller than the true value, since some heat is lost before/while the maximum is reached", "Improvement: insulate/lid the container, or plot a cooling curve and extrapolate back to the time of mixing"],
              modelAnswer: "Because heat is lost to the surroundings during mixing, the recorded maximum temperature rise is smaller than the true value — the calculated energy change would be an underestimate. This can be improved by using a lid/better insulation, or by plotting temperature against time and extrapolating the cooling trend back to the moment of mixing.",
              keywords: [["lower", "smaller", "underestimate", "less than"], ["lid", "insulat", "extrapolat"]])
    ]

    static var totalMarks: Int { questions.reduce(0) { $0 + $1.maxMarks } }
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

    private var questions: [MockPracticalQuestion] { MockPracticalQuestionBank.questions }
    private var question: MockPracticalQuestion { questions[index] }
    private var totalMarks: Int { MockPracticalQuestionBank.totalMarks }

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
            Text("\(questions.count) structured questions · \(totalMarks) marks")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Weighted like the real 6092 Paper 3 (40 marks, 1 h 50 min): Planning ≈15%, Measurement/Data/Analysis ≈85%.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: Double(submitted ? questions.count : index), total: Double(questions.count))
        }
    }

    private var questionView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Question \(index + 1) of \(questions.count)")
                    .font(.headline)
                Spacer()
                skillBadge(question.skillArea, marks: question.maxMarks)
            }
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
                Button(index == questions.count - 1 ? "Submit Mock" : "Next") {
                    if index < questions.count - 1 { index += 1 } else { submit() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var resultView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Score: \(score)/\(totalMarks)")
                .font(.title.bold())

            ForEach(questions.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Question \(i + 1)").font(.headline)
                        Spacer()
                        skillBadge(questions[i].skillArea, marks: questions[i].maxMarks)
                    }
                    Text(questions[i].modelAnswer)
                        .font(.subheadline)
                    Text(feedback.indices.contains(i) ? feedback[i] : "Review the marking points.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }

            Button("Try the mock again") {
                answers = Array(repeating: "", count: questions.count)
                index = 0
                submitted = false
                score = 0
                feedback = []
                didRecord = false
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func skillBadge(_ skill: AceSkillArea, marks: Int) -> some View {
        Text("\(skill.label) · \(marks) mark\(marks == 1 ? "" : "s")")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(skill.colour.opacity(0.18), in: Capsule())
            .foregroundStyle(skill.colour)
    }

    private func submit() {
        var total = 0
        var messages: [String] = []

        for (i, q) in questions.enumerated() {
            let answer = answers[i].lowercased()
            var earned = 0
            for group in q.keywords where group.contains(where: { answer.contains($0) }) {
                earned += 1
            }
            let capped = min(earned, q.maxMarks)
            total += capped
            messages.append("\(capped)/\(q.maxMarks) marks · \(q.markingPoints.joined(separator: "; "))")
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
            maxScore: totalMarks,
            feedback: messages
        )
    }
}
