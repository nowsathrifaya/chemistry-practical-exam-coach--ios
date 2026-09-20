//
//  ExamDateStore.swift
//  ChemistryCoach
//
//  Persists the student's own exam date locally, so Home can show a
//  "X days to go" countdown. Same pattern as `LastStudiedNoteStore` — a
//  small standalone UserDefaults-backed store, kept out of the
//  `UserPreferences` protocol since this is optional, student-set state
//  rather than app-level configuration.
//

import Foundation

enum ExamDateStore {
    private static let key = "chemistry_practical_exam_date"

    static func get() -> Date? {
        UserDefaults.standard.object(forKey: key) as? Date
    }

    static func set(_ date: Date?) {
        if let date {
            UserDefaults.standard.set(date, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    /// Whole days remaining until the exam date, counting today as day 0
    /// so "the exam is today" reads as 0, not -1 or 1 depending on time of
    /// day. Negative once the date has passed.
    static func daysRemaining(from now: Date = Date()) -> Int? {
        guard let examDate = get() else { return nil }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfExamDay = calendar.startOfDay(for: examDate)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfExamDay).day
    }
}
