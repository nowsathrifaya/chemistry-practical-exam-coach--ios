//
//  UserStatsCalculator.swift
//  ChemistryCoach
//
//  Port of `domain.stats.UserStatsCalculator.kt`. All numbers are computed
//  directly from the attempts table — nothing here is a placeholder or
//  hard-coded demo value. If the student hasn't practiced yet, these come
//  back as zero rather than showing fabricated progress.
//

import Foundation

enum UserStatsCalculator {

    static func compute(attempts: [Attempt], profile: CurriculumProfile) -> UserStats {
        let curriculumAttempts = attempts.filter { $0.curriculumValue == profile.curriculum }

        let totalPoints = curriculumAttempts.reduce(0) { $0 + $1.score }

        let accuracyPercent: Int
        if curriculumAttempts.isEmpty {
            accuracyPercent = 0
        } else {
            let ratios = curriculumAttempts
                .filter { $0.maxScore > 0 }
                .map { Double($0.score) / Double($0.maxScore) }
            accuracyPercent = ratios.isEmpty ? 0 : Int(( ratios.reduce(0, +) / Double(ratios.count)) * 100)
        }

        let streakDays = computeStreak(attempts)

        // "Topics" = every distinct apparatus/graph/simulation this curriculum covers,
        // plus every distinct ACE topic relevant to it. "Mastered" = a target the
        // student has attempted with an average score ratio of 70% or better.
        let aceTopicsForCurriculum = Set(
            AceQuestionBank.forCurriculum(profile.curriculum).map(\.topic)
        ).count
        let totalTopics = profile.apparatus.count + profile.graphTypes.count
            + profile.simulations.count + aceTopicsForCurriculum

        let byTarget = Dictionary(grouping: curriculumAttempts, by: \.target)
        let topicsMastered = byTarget.values.filter { list in
            let ratios = list.filter { $0.maxScore > 0 }.map { Double($0.score) / Double($0.maxScore) }
            guard !ratios.isEmpty else { return false }
            return (ratios.reduce(0, +) / Double(ratios.count)) >= 0.7
        }.count

        let badges = computeBadges(curriculumAttempts, streakDays: streakDays, accuracyPercent: accuracyPercent)
        let lastAttempt = attempts.max(by: { $0.completedAt < $1.completedAt })

        return UserStats(
            streakDays: streakDays,
            totalPoints: totalPoints,
            accuracyPercent: accuracyPercent,
            badges: badges,
            topicsMastered: topicsMastered,
            totalTopics: totalTopics,
            lastAttempt: lastAttempt
        )
    }

    private static func computeBadges(_ attempts: [Attempt], streakDays: Int, accuracyPercent: Int) -> [Badge] {
        let count = attempts.count
        let distinctTargets = Set(attempts.map(\.target)).count
        return [
            Badge(id: "first_steps", label: "First Steps", emoji: "\u{1F463}", unlocked: count >= 1),
            Badge(id: "getting_started", label: "10 Attempts", emoji: "\u{1F525}", unlocked: count >= 10),
            Badge(id: "dedicated", label: "50 Attempts", emoji: "\u{1F3C5}", unlocked: count >= 50),
            Badge(id: "explorer", label: "5 Different Topics", emoji: "\u{1F9ED}", unlocked: distinctTargets >= 5),
            Badge(id: "sharpshooter", label: "80% Accuracy", emoji: "\u{1F3AF}", unlocked: accuracyPercent >= 80 && count >= 5),
            Badge(id: "streak_3", label: "3-Day Streak", emoji: "\u{1F525}", unlocked: streakDays >= 3),
            Badge(id: "streak_7", label: "7-Day Streak", emoji: "\u{26A1}", unlocked: streakDays >= 7)
        ]
    }

    /// Consecutive days (ending today or yesterday, so the streak doesn't reset
    /// to 0 the moment the clock rolls past midnight before the student has had
    /// a chance to practice today).
    private static func computeStreak(_ attempts: [Attempt]) -> Int {
        guard !attempts.isEmpty else { return 0 }
        let calendar = Calendar.current
        let daySet = Set(attempts.map { calendar.startOfDay(for: $0.completedAt) })

        var cursor = calendar.startOfDay(for: Date())
        if !daySet.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            if !daySet.contains(cursor) { return 0 }
        }
        var streak = 0
        while daySet.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    /// True if there is at least one attempt recorded today (used for the Daily
    /// Challenge check-mark).
    static func hasAttemptToday(_ attempts: [Attempt]) -> Bool {
        guard !attempts.isEmpty else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return attempts.contains { calendar.startOfDay(for: $0.completedAt) == today }
    }
}
