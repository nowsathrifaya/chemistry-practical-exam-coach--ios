//
//  Attempt.swift
//  ChemistryCoach
//
//  SwiftData replacement for the Room `attempts` table
//  (`data.local.db.AttemptEntity` + `AttemptDao`). SwiftData was chosen over
//  Core Data per the brief ("SwiftData preferred") — the schema is a single
//  flat table with no relationships, which is exactly what SwiftData's
//  `@Model` macro is best at with the least boilerplate.
//

import Foundation
import SwiftData

@Model
final class Attempt: Identifiable, @unchecked Sendable {
    /// Matches Room's `id: String` primary key (a UUID string generated at
    /// insert time on Android too).
    @Attribute(.unique) var id: String
    var curriculum: String
    var mode: String
    var target: String
    var startedAt: Date
    var completedAt: Date
    var score: Int
    var maxScore: Int
    var feedback: String
    // Optional so existing SwiftData stores can migrate without requiring a
    // destructive reset. These fields power skill-level readiness and error
    // diagnosis in newer versions of the coach.
    var skillRaw: String?
    var errorTypeRaw: String?
    var durationSeconds: Int?
    var hintsUsed: Int?
    var confidence: Int?

    init(
        id: String = UUID().uuidString,
        curriculum: Curriculum,
        mode: AttemptMode,
        target: String,
        startedAt: Date,
        completedAt: Date,
        score: Int,
        maxScore: Int,
        feedback: String,
        skill: PracticalSkill? = nil,
        errorType: PracticalErrorType? = nil,
        durationSeconds: Int? = nil,
        hintsUsed: Int? = nil,
        confidence: Int? = nil
    ) {
        self.id = id
        self.curriculum = curriculum.rawValue
        self.mode = mode.rawValue
        self.target = target
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.score = score
        self.maxScore = maxScore
        self.feedback = feedback
        self.skillRaw = skill?.rawValue
        self.errorTypeRaw = errorType?.rawValue
        self.durationSeconds = durationSeconds
        self.hintsUsed = hintsUsed
        self.confidence = confidence
    }

    var curriculumValue: Curriculum? { Curriculum(rawValue: curriculum) }
    var modeValue: AttemptMode? { AttemptMode(rawValue: mode) }
    var skillValue: PracticalSkill? { skillRaw.flatMap(PracticalSkill.init(rawValue:)) }
    var errorTypeValue: PracticalErrorType? { errorTypeRaw.flatMap(PracticalErrorType.init(rawValue:)) }
}

extension ModelContainer {
    static var preview: ModelContainer {
        do { return try ModelContainer(for: Attempt.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) }
        catch { fatalError("Preview container failed: \(error)") }
    }
}
