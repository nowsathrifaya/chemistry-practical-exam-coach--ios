
import Foundation

struct CurriculumProfile {
    let curriculum: Curriculum
    let examBoard: String
    let paperName: String
    let paperCode: String
    let totalMarks: Int
    let durationMinutes: Int
    let weightPercent: Int
    let paperSummary: String
    let apparatus: [ApparatusType]
    let simulations: [SimulationType]
    let graphTypes: [GraphCoachType]
    let keyTopics: [String]
    let markingScheme: String
    let toleranceNote: String
    let flagEmoji: String
    let levelTag: String
    let homeHeadlineLine1: String
    let homeHeadlineLine2: String
}

enum CurriculumProfiles {
    static let singapore = CurriculumProfile(
        curriculum: .singapore,
        examBoard: "SEAB",
        paperName: "Paper 3 — Practical",
        paperCode: "6092",
        totalMarks: 40,
        durationMinutes: 110,
        weightPercent: 20,
        paperSummary: "SEAB 6092 · Paper 3 · 40 marks · 1 h 50 min",
        apparatus: ApparatusType.allCases,
        simulations: SimulationType.allCases,
        graphTypes: GraphCoachType.allCases,
        keyTopics: [
            "Experimental Chemistry — apparatus, purification and experimental design",
            "Chemical calculations — mole concept, formulae and stoichiometry",
            "Acid–base chemistry — titration, salts and ammonia",
            "Qualitative analysis — cations, anions and gases",
            "Redox chemistry — oxidation, reduction and electrolysis",
            "Patterns in the Periodic Table",
            "Chemical energetics",
            "Rate of reactions",
            "Organic chemistry",
            "Maintaining air quality"
        ],
        markingScheme: "Paper 3: 40 marks, 1 h 50 min. Planning (P) carries 15% of the practical assessment; MMO, PDO and ACE together carry 85%. Practical questions may combine practical work, calculations and data analysis.",
        toleranceNote: "SEAB 6092 practical guidance: burette readings are normally recorded to the nearest 0.05 cm³; in a good end-point experiment, two titres should be concordant within 0.20 cm³.",
        flagEmoji: "🇸🇬",
        levelTag: "O-LEVEL",
        homeHeadlineLine1: "O-Level Chemistry",
        homeHeadlineLine2: "Paper 3 Practical Coach"
    )
    static let general = singapore
    static func forCurriculum(_ curriculum: Curriculum) -> CurriculumProfile {
        // GENERAL is a legacy stored value only. Until a separate General
        // syllabus is implemented, always resolve it to the real Singapore
        // profile instead of presenting duplicate curriculum choices.
        singapore
    }
}
