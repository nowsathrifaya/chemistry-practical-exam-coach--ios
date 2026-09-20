import Foundation

struct RevisionMaterial: Identifiable, Hashable {
    let id: String
    let title: String
    let fileName: String
}

enum RevisionMaterialCatalog {
    static let materials: [RevisionMaterial] = [
        .init(id: "qa", title: "Qualitative Analysis", fileName: "01_qualitative_analysis"),
        .init(id: "salts", title: "Solubility and Salts", fileName: "02_solubility_and_salts"),
        .init(id: "titration", title: "Titration Calculations", fileName: "03_titration_calculations"),
        .init(id: "electrolysis", title: "Electrolysis", fileName: "04_electrolysis"),
        .init(id: "energy", title: "Energy Changes", fileName: "05_energy_changes"),
        .init(id: "rate", title: "Rate of Reaction", fileName: "06_rate_of_reaction"),
        .init(id: "yield", title: "Yield, Purity and Water of Crystallisation", fileName: "07_yield_purity_water_crystallisation"),
        .init(id: "separation", title: "Separation Techniques", fileName: "08_separation_techniques"),
        .init(id: "mock", title: "Mock Exam Questions", fileName: "09_mock_exam_questions"),
        .init(id: "expanded", title: "Expanded Study Notes", fileName: "10_study_notes_expanded")
    ]
}
