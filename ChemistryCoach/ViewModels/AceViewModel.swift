//
//  AceViewModel.swift
//  ChemistryCoach
//
//  Full port of `ui.viewmodel.AceViewModel.kt`. Spaced-repetition-lite using
//  a simple 5-box Leitner system:
//
//  Box 1 = just got wrong / never seen -> resurfaces after 0 questions (immediately eligible)
//  Box 2 = got right once              -> resurfaces after 3 questions
//  Box 3 = got right twice             -> resurfaces after 7 questions
//  Box 4 = got right three times       -> resurfaces after 15 questions
//  Box 5 = mastered                    -> resurfaces after 30 questions
//
//  Boxes are tracked in-memory for the session; persistence is via
//  `AttemptRepository` (each self-mark is recorded as an attempt so the
//  Progress tab can show ACE accuracy) — identical division of
//  responsibility to the Kotlin original.
//

import Foundation
import Observation

struct AceSessionStats {
    var answered: Int = 0
    var correct: Int = 0
    var accuracy: Int { answered == 0 ? 0 : (correct * 100) / answered }
}

@MainActor
@Observable
final class AceViewModel {
    private let repository: AttemptRepository
    private let activeCurriculum: Curriculum

    // MARK: - Question pool

    private let pool: [AceQuestion]

    // MARK: - Leitner box state

    /// Question id -> box number (1-5). Default box = 1 (unseen).
    private var boxes: [String: Int] = [:]
    /// How many questions have been answered since each question was last seen.
    /// `Int.max` is the sentinel for "never seen, always eligible."
    private var questionsSinceLastSeen: [String: Int] = [:]
    private let boxResurfaceAfter: [Int: Int] = [1: 0, 2: 3, 3: 7, 4: 15, 5: 30]
    private var questionsAnsweredTotal = 0
    private struct LeitnerSnapshot: Codable {
        var boxes: [String: Int]
        var questionsSinceLastSeen: [String: Int]
        var questionsAnsweredTotal: Int
    }
    private var persistenceKey: String { "ChemistryCoach.aceLeitner." + activeCurriculum.rawValue }

    // MARK: - UI state

    private(set) var currentQuestion: AceQuestion?
    private(set) var answerRevealed = false
    private(set) var sessionStats = AceSessionStats()
    private(set) var masteryBySkill: [AceSkillArea: Int] = [:]

    // MARK: - Mock exam state

    let isMockExam: Bool
    private(set) var mockExamSecondsRemaining: Int
    private(set) var mockExamFinished = false
    private var mockExamTimer: Timer?

    init(
        repository: AttemptRepository,
        curriculum: Curriculum = .general,
        filterTopic: AceTopic? = nil,
        filterSkill: AceSkillArea? = nil,
        isMockExam: Bool = false,
        mockExamMinutes: Int = 30
    ) {
        self.repository = repository
        self.activeCurriculum = curriculum
        self.isMockExam = isMockExam
        self.mockExamSecondsRemaining = mockExamMinutes * 60

        let basePool: [AceQuestion]
        if let filterTopic {
            basePool = AceQuestionBank.forTopic(filterTopic, curriculum: curriculum)
        } else if let filterSkill {
            basePool = AceQuestionBank.forSkill(filterSkill, curriculum: curriculum)
        } else {
            basePool = AceQuestionBank.forCurriculum(curriculum)
        }
        self.pool = basePool.sorted { $0.difficulty.sortOrder < $1.difficulty.sortOrder }

        for q in pool {
            boxes[q.id] = 1
            questionsSinceLastSeen[q.id] = Int.max // never seen = always eligible
        }
        restoreLeitnerState()
        advanceToNextQuestion()

        if isMockExam {
            startMockExamTimer()
        }
    }


    func revealAnswer() {
        SoundManager.shared.play(.tap)
        answerRevealed = true
    }

    /// Student self-marks their answer. `correct` = true if they felt their
    /// answer matched the model answer.
    func markSelf(correct: Bool) {
        guard let q = currentQuestion else { return }
        let currentBox = boxes[q.id] ?? 1
        boxes[q.id] = correct ? min(currentBox + 1, 5) : 1 // wrong -> back to box 1
        questionsSinceLastSeen[q.id] = 0
        questionsAnsweredTotal += 1
        SoundManager.shared.play(correct ? .success : .error)

        for other in pool where other.id != q.id {
            bumpSinceLastSeen(other.id)
        }

        sessionStats.answered += 1
        if correct { sessionStats.correct += 1 }

        updateMastery()
        persistLeitnerState()

        repository.save(
            curriculum: activeCurriculum,
            mode: .acePractice,
            target: "\(q.skillArea.label): \(q.topic.label)",
            score: correct ? q.marks : 0,
            maxScore: q.marks,
            feedback: [correct ? "Self-marked correct" : "Self-marked incorrect"]
        )

        advanceToNextQuestion()
    }

    func skipQuestion() {
        guard let q = currentQuestion else { return }
        SoundManager.shared.play(.tap)
        questionsSinceLastSeen[q.id] = 0
        for other in pool where other.id != q.id {
            bumpSinceLastSeen(other.id)
        }
        answerRevealed = false
        currentQuestion = selectNextQuestion()
        persistLeitnerState()
    }

    func boxFor(_ questionId: String) -> Int { boxes[questionId] ?? 1 }

    private func persistLeitnerState() {
        let snapshot = LeitnerSnapshot(boxes: boxes, questionsSinceLastSeen: questionsSinceLastSeen, questionsAnsweredTotal: questionsAnsweredTotal)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private func restoreLeitnerState() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let snapshot = try? JSONDecoder().decode(LeitnerSnapshot.self, from: data) else { return }
        for q in pool {
            if let box = snapshot.boxes[q.id] { boxes[q.id] = min(max(box, 1), 5) }
            if let since = snapshot.questionsSinceLastSeen[q.id] { questionsSinceLastSeen[q.id] = since }
        }
        questionsAnsweredTotal = snapshot.questionsAnsweredTotal
    }

    private func advanceToNextQuestion() {
        answerRevealed = false
        currentQuestion = selectNextQuestion()
    }

    /// Selects the most-due question using the Leitner box system. A
    /// question is eligible if `questionsSinceLastSeen >= boxResurfaceAfter[box]`.
    /// Among eligible questions, prefer lower boxes (needs more practice). If
    /// nothing is due, force the lowest-box question.
    private func selectNextQuestion() -> AceQuestion? {
        guard !pool.isEmpty else { return nil }

        let eligible = pool.filter { q in
            let box = boxes[q.id] ?? 1
            let since = questionsSinceLastSeen[q.id] ?? Int.max
            let threshold = boxResurfaceAfter[box] ?? 0
            return since >= threshold
        }

        let candidates = eligible.isEmpty ? pool : eligible
        return candidates.min { a, b in
            let boxA = boxes[a.id] ?? 1
            let boxB = boxes[b.id] ?? 1
            if boxA != boxB { return boxA < boxB }
            let sinceA = questionsSinceLastSeen[a.id] ?? 0
            let sinceB = questionsSinceLastSeen[b.id] ?? 0
            return sinceA > sinceB // longer since seen sorts first (tie-break)
        }
    }

    private func updateMastery() {
        var bySkill: [AceSkillArea: Int] = [:]
        for skill in AceSkillArea.allCases {
            let skillQs = pool.filter { $0.skillArea == skill }
            guard !skillQs.isEmpty else { bySkill[skill] = 0; continue }
            let masteredCount = skillQs.filter { (boxes[$0.id] ?? 1) >= 4 }.count
            bySkill[skill] = (masteredCount * 100) / skillQs.count
        }
        masteryBySkill = bySkill
    }

    /// Increments a question's "since last seen" counter without overflowing
    /// past `Int.max` — the sentinel for "never seen, always eligible."
    /// Incrementing that sentinel with plain `+ 1` would wrap around, which
    /// made every never-seen question permanently ineligible after the very
    /// first skip/answer on Android — ported here with the same overflow guard.
    private func bumpSinceLastSeen(_ id: String) {
        let current = questionsSinceLastSeen[id] ?? 0
        questionsSinceLastSeen[id] = current >= Int.max - 1 ? Int.max : current + 1
    }

    // MARK: - Mock exam timer

    private func startMockExamTimer() {
        mockExamTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tickMockExam()
            }
        }
    }

    private func tickMockExam() {
        guard mockExamSecondsRemaining > 0 else {
            mockExamTimer?.invalidate()
            mockExamTimer = nil
            mockExamFinished = true
            SoundManager.shared.play(.complete)
            return
        }
        mockExamSecondsRemaining -= 1
    }

    var mockExamTimeString: String {
        let m = mockExamSecondsRemaining / 60
        let s = mockExamSecondsRemaining % 60
        return String(format: "%02d:%02d remaining", m, s)
    }

    func endMockExamEarly() {
        mockExamTimer?.invalidate()
        mockExamTimer = nil
        mockExamFinished = true
        SoundManager.shared.play(.complete)
    }
}

private extension AceDifficulty {
    var sortOrder: Int {
        switch self {
        case .basic: return 0
        case .standard: return 1
        case .challenging: return 2
        }
    }
}
