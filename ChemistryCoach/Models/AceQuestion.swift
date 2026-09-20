//
//  AceQuestion.swift
//  ChemistryCoach
//
//  Port of `core.model.AceQuestion.kt`. A single ACE/Planning written
//  question in the style of Singapore O-Level Paper 3.
//
//  Skill area tags match the four SEAB assessment objectives:
//    P   = Planning (identify variables, describe procedure, assess risks)
//    MMO = Manipulation, Measurement and Observation
//    PDO = Presentation of Data and Observations
//    ACE = Analysis, Conclusions and Evaluation
//

import Foundation
import SwiftUI

enum AceSkillArea: String, CaseIterable, Codable {
    case planning = "PLANNING"
    case mmo = "MMO"
    case pdo = "PDO"
    case ace = "ACE"

    var label: String {
        switch self {
        case .planning: return "Planning (P)"
        case .mmo: return "Measurement (MMO)"
        case .pdo: return "Data Presentation (PDO)"
        case .ace: return "Analysis & Evaluation (ACE)"
        }
    }

    /// Hex string preserved from Android; `colour` (a SwiftUI Color) is the
    /// convenience accessor views should use.
    var hex: String {
        switch self {
        case .planning: return "#2980B9"
        case .mmo: return "#27AE60"
        case .pdo: return "#8E44AD"
        case .ace: return "#D98B36"
        }
    }

    var colour: Color { Color(hex: hex) }
}

enum AceTopic: String, CaseIterable, Codable, Hashable {
    case experimental = "EXPERIMENTAL"
    case particulate = "PARTICULATE"
    case bonding = "BONDING"
    case calculations = "CALCULATIONS"
    case acidBase = "ACID_BASE"
    case qualitative = "QUALITATIVE"
    case redox = "REDOX"
    case periodic = "PERIODIC"
    case energetics = "ENERGETICS"
    case rate = "RATE"
    case organic = "ORGANIC"
    case airQuality = "AIR_QUALITY"
    case salts = "SALTS"
    case ammonia = "AMMONIA"
    case dataBased = "DATA_BASED"
    case safety = "SAFETY"
    case generalMeasurement = "GENERAL_MEASUREMENT"
    case generalGraph = "GENERAL_GRAPH"
    case generalPlanning = "GENERAL_PLANNING"
    var label: String {
        switch self {
        case .experimental: return "Experimental Chemistry"
        case .particulate: return "Particulate Nature of Matter"
        case .bonding: return "Chemical Bonding & Structure"
        case .calculations: return "Chemical Calculations"
        case .acidBase: return "Acid–Base Chemistry"
        case .qualitative: return "Qualitative Analysis"
        case .redox: return "Redox Chemistry"
        case .periodic: return "Patterns in the Periodic Table"
        case .energetics: return "Chemical Energetics"
        case .rate: return "Rate of Reactions"
        case .organic: return "Organic Chemistry"
        case .airQuality: return "Maintaining Air Quality"
        case .salts: return "Salts"
        case .ammonia: return "Ammonia & Haber Process"
        case .dataBased: return "Data-Based Questions"
        case .safety: return "Laboratory Safety"
        case .generalMeasurement: return "Measurement Skills"
        case .generalGraph: return "Graph & Data Skills"
        case .generalPlanning: return "Planning Skills"
        }
    }
}

enum AceDifficulty: String, CaseIterable, Codable {
    case basic = "BASIC"
    case standard = "STANDARD"
    case challenging = "CHALLENGING"
}

struct AceQuestion: Identifiable, Hashable {
    let id: String
    let topic: AceTopic
    let skillArea: AceSkillArea
    let difficulty: AceDifficulty
    let marks: Int
    /// Which exam boards this question is relevant to. Empty set = applies to
    /// ALL curricula (universal question).
    let curricula: Set<Curriculum>
    /// The question as it would appear on the exam paper.
    let questionText: String
    /// What the mark scheme awards, written as bullet points the student can self-check.
    let modelAnswer: String
    /// What students commonly write that scores zero.
    let commonMistakes: String
    /// Examiner report tip — the single most important thing to remember.
    let examinerTip: String

    init(
        id: String, topic: AceTopic, skillArea: AceSkillArea, difficulty: AceDifficulty,
        marks: Int, curricula: Set<Curriculum> = [], questionText: String,
        modelAnswer: String, commonMistakes: String, examinerTip: String
    ) {
        self.id = id
        self.topic = topic
        self.skillArea = skillArea
        self.difficulty = difficulty
        self.marks = marks
        self.curricula = curricula
        self.questionText = questionText
        self.modelAnswer = modelAnswer
        self.commonMistakes = commonMistakes
        self.examinerTip = examinerTip
    }
}

extension Color {
    /// Minimal `#RRGGBB` hex initialiser so `AceSkillArea.hex` values from the
    /// Android design system can be reused as-is.
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
