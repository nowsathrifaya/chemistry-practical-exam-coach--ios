//
//  AceView.swift
//  ChemistryCoach
//
//  Replaces `AceListFragment` + `AceFragment.kt`. `AceListView` is the entry
//  point (browse by topic, or jump into "Practice all" / Mock Exam);
//  `AcePracticeSessionView` is the continuous Leitner-driven session screen
//  that replaces the old single-question reveal flow.
//

import SwiftUI

struct AceListView: View {
    let curriculum: Curriculum
    @Environment(\.modelContext) private var modelContext

    private var questions: [AceQuestion] { AceQuestionBank.forCurriculum(curriculum) }
    private var groupedByTopic: [(AceTopic, [AceQuestion])] {
        Dictionary(grouping: questions, by: \.topic)
            .sorted { $0.key.label < $1.key.label }
    }
    private var profile: CurriculumProfile { CurriculumProfiles.forCurriculum(curriculum) }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AcePracticeSessionView(
                        repository: AttemptRepository(modelContext: modelContext),
                        curriculum: curriculum, filterTopic: nil, filterSkill: nil,
                        isMockExam: false, mockExamMinutes: profile.durationMinutes
                    )
                } label: {
                    Label("Practice all questions", systemImage: "shuffle")
                        .font(.headline)
                }
                NavigationLink {
                    AcePracticeSessionView(
                        repository: AttemptRepository(modelContext: modelContext),
                        curriculum: curriculum, filterTopic: nil, filterSkill: nil,
                        isMockExam: true, mockExamMinutes: profile.durationMinutes
                    )
                } label: {
                    Label("Mock exam (\(profile.durationMinutes) min timed)", systemImage: "timer")
                        .font(.headline)
                        .foregroundStyle(.purple)
                }
            }

            ForEach(groupedByTopic, id: \.0) { topic, topicQuestions in
                Section(topic.label) {
                    NavigationLink {
                        AcePracticeSessionView(
                            repository: AttemptRepository(modelContext: modelContext),
                            curriculum: curriculum, filterTopic: topic, filterSkill: nil,
                            isMockExam: false, mockExamMinutes: profile.durationMinutes
                        )
                    } label: {
                        HStack {
                            Text("Practice this topic")
                            Spacer()
                            Text("\(topicQuestions.count) question\(topicQuestions.count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("ACE Practice")
    }
}

struct AcePracticeSessionView: View {
    @State private var viewModel: AceViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        repository: AttemptRepository, curriculum: Curriculum,
        filterTopic: AceTopic?, filterSkill: AceSkillArea?,
        isMockExam: Bool, mockExamMinutes: Int
    ) {
        _viewModel = State(initialValue: AceViewModel(
            repository: repository, curriculum: curriculum,
            filterTopic: filterTopic, filterSkill: filterSkill,
            isMockExam: isMockExam, mockExamMinutes: mockExamMinutes
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if viewModel.isMockExam {
                    mockExamTimerBar
                }

                if let question = viewModel.currentQuestion {
                    questionCard(question)
                    sessionStatsBar
                    masteryPanel
                } else {
                    ContentUnavailableFallback()
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.isMockExam ? "Mock Exam" : "ACE Practice")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isMockExam && !viewModel.mockExamFinished)
        .toolbar {
            if viewModel.isMockExam && !viewModel.mockExamFinished {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End exam") { viewModel.endMockExamEarly() }
                }
            }
        }
        .alert("Mock exam complete", isPresented: Binding(
            get: { viewModel.mockExamFinished },
            set: { _ in }
        )) {
            Button("Done") { dismiss() }
        } message: {
            Text("\(viewModel.sessionStats.correct)/\(viewModel.sessionStats.answered) correct \u{00B7} \(viewModel.sessionStats.accuracy)% accuracy")
        }
    }

    private var mockExamTimerBar: some View {
        HStack {
            Image(systemName: "timer")
            Text(viewModel.mockExamTimeString)
                .font(.headline.monospacedDigit())
            Spacer()
        }
        .padding(12)
        .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .foregroundStyle(.purple)
    }

    @ViewBuilder
    private func questionCard(_ question: AceQuestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(question.difficulty.label)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(question.difficulty.colour.opacity(0.15), in: Capsule())
                    .foregroundStyle(question.difficulty.colour)
                Text("\(question.marks) mark\(question.marks == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                LeitnerBoxIndicator(box: viewModel.boxFor(question.id))
            }

            Text("Topic: \(question.topic.label)")
                .font(.caption).foregroundStyle(.secondary)

            Text(question.questionText)
                .font(.body)

            if viewModel.answerRevealed {
                AceInfoBlock(title: "Model answer", text: question.modelAnswer, tint: .green)
                AceInfoBlock(title: "Common mistakes", text: question.commonMistakes, tint: .red)
                AceInfoBlock(title: "Examiner tip", text: question.examinerTip, tint: .orange)

                Text("Did your answer match?")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 12) {
                    Button {
                        viewModel.markSelf(correct: true)
                    } label: {
                        Label("Correct", systemImage: "checkmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button {
                        viewModel.markSelf(correct: false)
                    } label: {
                        Label("Wrong", systemImage: "xmark").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            } else {
                HStack(spacing: 12) {
                    Button("Reveal answer") { viewModel.revealAnswer() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    Button("Skip") { viewModel.skipQuestion() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var sessionStatsBar: some View {
        let stats = viewModel.sessionStats
        return Group {
            if stats.answered > 0 {
                HStack {
                    Text("\(stats.correct)/\(stats.answered) correct")
                    Spacer()
                    Text("\(stats.accuracy)% accuracy")
                }
                .font(.subheadline.weight(.medium))
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var masteryPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !viewModel.masteryBySkill.isEmpty {
                Text("Mastery by skill area").font(.subheadline.weight(.semibold))
                ForEach(AceSkillArea.allCases, id: \.self) { skill in
                    let pct = viewModel.masteryBySkill[skill] ?? 0
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(skill.label).font(.caption)
                            Spacer()
                            Text("\(pct)%").font(.caption).foregroundStyle(.secondary)
                        }
                        ProgressView(value: Double(pct), total: 100)
                            .tint(skill.colour)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Renders the box (1-5) as filled/empty squares, e.g. \u25A0\u25A0\u25A1\u25A1\u25A1, matching
/// the Android Leitner progress indicator.
private struct LeitnerBoxIndicator: View {
    let box: Int

    private var label: String {
        switch box {
        case 1: return "New / Needs practice"
        case 2: return "Seen once correctly"
        case 3: return "Getting there"
        case 4: return "Almost mastered"
        case 5: return "\u{2605} Mastered"
        default: return ""
        }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(String(repeating: "\u{25A0}", count: box) + String(repeating: "\u{25A1}", count: 5 - box))
                .font(.caption.monospaced())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private struct ContentUnavailableFallback: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.circle").font(.largeTitle).foregroundStyle(.secondary)
            Text("No questions available for this filter.").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

private struct AceInfoBlock: View {
    let title: String
    let text: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).foregroundStyle(tint)
            Text(text).font(.subheadline)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private extension AceDifficulty {
    var label: String {
        switch self {
        case .basic: return "Basic"
        case .standard: return "Standard"
        case .challenging: return "Challenging"
        }
    }

    var colour: Color {
        switch self {
        case .basic: return Color(hex: "#2980B9")
        case .standard: return Color(hex: "#D98B36")
        case .challenging: return Color(hex: "#D42B2B")
        }
    }
}
