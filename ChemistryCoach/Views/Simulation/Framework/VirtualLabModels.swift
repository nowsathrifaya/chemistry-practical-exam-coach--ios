import Foundation

enum VirtualLabActionState: String, CaseIterable, Codable {
    case idle, prepared, addingReagent, reacting, observing, measured, analysed
}

struct VirtualLabStage: Identifiable, Hashable {
    let id: String
    let title: String
    let instruction: String
    let skill: String
}

struct VirtualLabSession: Identifiable {
    let id = UUID()
    let type: SimulationType
    var stageIndex: Int = 0
    var completedStages: Set<String> = []
    var measurements: [LabReading] = []
    var actionState: VirtualLabActionState = .idle
    var observedChanges: [String] = []
    var startedAt = Date()
    var finishedAt: Date?

    var isComplete: Bool { completedStages.count >= 4 }
    var progress: Double { min(Double(completedStages.count) / 4.0, 1.0) }
}

extension SimulationType {
    var practicalStages: [VirtualLabStage] {
        [
            .init(id: "prepare", title: "Prepare", instruction: "Select and check the apparatus, reagents, and safety equipment before starting.", skill: "Planning and safety"),
            .init(id: "perform", title: "Perform", instruction: "Carry out the procedure carefully. Use the controls to model realistic laboratory actions.", skill: "Experimental technique"),
            .init(id: "measure", title: "Measure", instruction: "Record observations and measurements with appropriate units and precision.", skill: "Measurement"),
            .init(id: "analyse", title: "Analyse", instruction: "Interpret the evidence, calculate derived values, and state a conclusion.", skill: "Data analysis")
        ]
    }
}
