//
//  ContinueLearningResolver.swift
//  ChemistryCoach
//
//  Port of `domain.stats.ContinueLearningResolver.kt`, extended for the new
//  Lab experiment framework: since Lab sessions (chemistry lab experiments and future
//  drag-and-drop experiment) now record a graded `Attempt` — unlike the old
//  ungraded exploratory simulations — "Continue Learning" needs to be able
//  to route back into a specific Lab experiment too, not just Apparatus,
//  Graph, and ACE practice.
//

import Foundation

enum ContinueTarget: Hashable {
    case apparatus(ApparatusType)
    case graph(GraphCoachType)
    case simulationLab(SimulationType)
    case acePractice
    case none
}

enum ContinueLearningResolver {
    static func resolve(_ attempt: Attempt?) -> ContinueTarget {
        guard let attempt else { return .none }
        switch attempt.mode {
        case AttemptMode.apparatusPractice.rawValue:
            if let type = ApparatusType.allCases.first(where: { $0.label == attempt.target }) {
                return .apparatus(type)
            }
            return .none
        case AttemptMode.graphCoach.rawValue:
            if let type = GraphCoachType.allCases.first(where: { $0.label == attempt.target }) {
                return .graph(type)
            }
            return .none
        case AttemptMode.simulationLab.rawValue:
            if let type = SimulationType.allCases.first(where: { $0.label == attempt.target }) {
                return .simulationLab(type)
            }
            return .none
        case "ACE_PRACTICE", "MOCK_EXAM":
            return .acePractice
        default:
            return .none
        }
    }

    /// Short label for the "Continue Learning: <this>" / "Last: <this>" CTA text.
    static func label(_ attempt: Attempt?) -> String {
        guard let attempt else { return "Start your first experiment" }
        return attempt.target
    }
}
