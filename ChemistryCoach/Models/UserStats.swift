//
//  UserStats.swift
//  ChemistryCoach
//
//  Port of `domain.stats.UserStats.kt`.
//

import Foundation

struct Badge: Identifiable, Hashable {
    let id: String
    let label: String
    let emoji: String
    let unlocked: Bool
}

struct UserStats {
    let streakDays: Int
    let totalPoints: Int
    let accuracyPercent: Int
    let badges: [Badge]
    let topicsMastered: Int
    let totalTopics: Int
    let lastAttempt: Attempt?

    var unlockedBadgeCount: Int { badges.filter(\.unlocked).count }
    var masteryPercent: Int { totalTopics == 0 ? 0 : (topicsMastered * 100) / totalTopics }

    static let empty = UserStats(
        streakDays: 0, totalPoints: 0, accuracyPercent: 0,
        badges: [], topicsMastered: 0, totalTopics: 0, lastAttempt: nil
    )
}
