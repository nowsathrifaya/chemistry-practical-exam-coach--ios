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

    init(
        id: String = UUID().uuidString,
        curriculum: Curriculum,
        mode: AttemptMode,
        target: String,
        startedAt: Date,
        completedAt: Date,
        score: Int,
        maxScore: Int,
        feedback: String
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
    }

    var curriculumValue: Curriculum? { Curriculum(rawValue: curriculum) }
    var modeValue: AttemptMode? { AttemptMode(rawValue: mode) }
}
