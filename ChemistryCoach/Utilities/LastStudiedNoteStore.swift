//
//  LastStudiedNoteStore.swift
//  ChemistryCoach
//
//  Tracks the single most recently opened Study Notes page, so the Learn
//  tab can offer "Continue reading: <title>" and jump straight back to
//  that page, instead of always starting from the category list.
//  Deliberately a tiny standalone UserDefaults-backed store — separate
//  from `UserPreferences` (curriculum/onboarding), since this is
//  opportunistic, non-critical state that's fine to be absent, not a
//  value every screen needs injected.
//

import Foundation

enum LastStudiedNoteStore {
    private static let categoryKey = "last_studied_note_category"
    private static let pageIndexKey = "last_studied_note_page_index"

    static func record(category: StudyNoteCategory, pageIndex: Int) {
        UserDefaults.standard.set(category.rawValue, forKey: categoryKey)
        UserDefaults.standard.set(pageIndex, forKey: pageIndexKey)
    }

    /// Resolves the persisted position back into a concrete note. Defensive
    /// against the note bank having changed shape since, by simply
    /// returning `nil` rather than resuming at an out-of-range page.
    static func resolve() -> (category: StudyNoteCategory, pageIndex: Int, note: StudyNote)? {
        guard
            let rawCategory = UserDefaults.standard.string(forKey: categoryKey),
            let category = StudyNoteCategory(rawValue: rawCategory)
        else { return nil }
        let pageIndex = UserDefaults.standard.integer(forKey: pageIndexKey)
        let notes = StudyNotesBank.forCategory(category)
        guard notes.indices.contains(pageIndex) else { return nil }
        return (category, pageIndex, notes[pageIndex])
    }
}
