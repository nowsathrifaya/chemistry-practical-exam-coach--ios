//
//  AdaptiveCoach.swift
//  ChemistryCoach
//
//  v5 adaptive mastery layer. Converts persistent attempt history into a
//  focused next action without replacing the existing scoring systems.
//

import Foundation

struct AdaptiveRecommendation: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let accuracy: Int
    let attempts: Int
    let action: AdaptiveAction
    let commonError: String?
}

enum AdaptiveAction: Hashable {
    case qualitative
    case calculation
    case aceTopic(AceTopic)
    case aceSkill(AceSkillArea)
    case simulation(SimulationType)
    case apparatus(ApparatusType)
    case graph(GraphCoachType)
}

enum AdaptiveCoach {
    static func recommendations(from attempts: [Attempt], limit: Int = 3) -> [AdaptiveRecommendation] {
        let scored = attempts.filter { $0.maxScore > 0 }
        guard !scored.isEmpty else {
            return [AdaptiveRecommendation(
                id: "starter",
                title: "Start with Qualitative Analysis",
                subtitle: "Build practical observation skills",
                detail: "Run an unknown-sample test, record observations, then identify the ion.",
                accuracy: 0,
                attempts: 0,
                action: .qualitative,
                commonError: nil
            )]
        }

        var candidates: [AdaptiveRecommendation] = []
        var seen = Set<String>()

        for attempt in scored {
            guard let action = action(for: attempt.target) else { continue }
            let key = key(for: action)
            if seen.contains(key) { continue }
            seen.insert(key)

            let related = scored.filter { relatedTarget($0.target, to: action) }
            guard !related.isEmpty else { continue }
            let accuracy = Int((related.reduce(0.0) { $0 + ratio($1) } / Double(related.count) * 100).rounded())
            let title = title(for: action)
            let commonError = mostCommonError(in: related)
            candidates.append(AdaptiveRecommendation(
                id: key,
                title: title,
                subtitle: accuracy < 70 ? "Priority review" : "Keep building mastery",
                detail: detail(for: action, accuracy: accuracy),
                accuracy: accuracy,
                attempts: related.count,
                action: action,
                commonError: commonError
            ))
        }

        // Always expose known curriculum weaknesses first, but avoid ranking
        // otherwise equal areas with arbitrary ordering.
        return candidates
            .sorted { lhs, rhs in
                if lhs.accuracy != rhs.accuracy { return lhs.accuracy < rhs.accuracy }
                return lhs.attempts > rhs.attempts
            }
            .prefix(limit)
            .map { $0 }
    }

    /// Maps a saved `Attempt.target` string back to the feature it came from.
    /// Several features legitimately share the words "qualitative" and
    /// "calculation" in their target strings (the integrated Qualitative
    /// Analysis lab, the standalone Unknown Sample Laboratory, and the ACE
    /// "Qualitative Analysis" / "Chemical Calculations" topics all do), so
    /// the more specific, more precisely-anchored checks must run BEFORE the
    /// generic substring checks — otherwise every one of those get
    /// mis-recommended into the standalone qualitative/calculation actions,
    /// regardless of which feature the student actually practised in.
    static func action(for target: String) -> AdaptiveAction? {
        let lower = target.lowercased()

        // Standalone features use a distinctive " · " separator followed by
        // a specific sample/topic name — check these exact prefixes first.
        if lower.hasPrefix("qualitative analysis · ") {
            return .qualitative
        }
        if lower.hasPrefix("calculation practice · ") {
            return .calculation
        }

        // The integrated practical labs save their target as exactly
        // `SimulationType.label` (no separator), so an exact match here
        // correctly catches the integrated "Qualitative Analysis" lab
        // before it could fall through to the generic checks below.
        for simulation in SimulationType.allCases where lower == simulation.label.lowercased() {
            return .simulation(simulation)
        }

        for topic in AceTopic.allCases where lower.contains(topic.label.lowercased()) || lower.contains(topic.rawValue.lowercased()) {
            return .aceTopic(topic)
        }
        for skill in AceSkillArea.allCases where lower.contains(skill.label.lowercased()) || lower.contains(skill.rawValue.lowercased()) {
            return .aceSkill(skill)
        }
        for simulation in SimulationType.allCases where lower.contains(simulation.label.lowercased()) {
            return .simulation(simulation)
        }
        for apparatus in ApparatusType.allCases where lower.contains(apparatus.label.lowercased()) {
            return .apparatus(apparatus)
        }
        for graph in GraphCoachType.allCases where lower.contains(graph.label.lowercased()) {
            return .graph(graph)
        }
        return nil
    }

    static func relatedTarget(_ target: String, to action: AdaptiveAction) -> Bool {
        guard let targetAction = AdaptiveCoach.action(for: target) else { return false }
        return key(for: targetAction) == key(for: action)
    }

    static func ratio(_ attempt: Attempt) -> Double {
        guard attempt.maxScore > 0 else { return 0 }
        return max(0, min(1, Double(attempt.score) / Double(attempt.maxScore)))
    }

    private static func mostCommonError(in attempts: [Attempt]) -> String? {
        let errors = attempts.compactMap(\.errorTypeValue)
        guard !errors.isEmpty else { return nil }
        let grouped = Dictionary(grouping: errors, by: { $0 })
        return grouped.max { lhs, rhs in lhs.value.count < rhs.value.count }?.key.label
    }

    private static func key(for action: AdaptiveAction) -> String {
        switch action {
        case .qualitative: return "qualitative"
        case .calculation: return "calculation"
        case .aceTopic(let topic): return "ace-topic-\(topic.rawValue)"
        case .aceSkill(let skill): return "ace-skill-\(skill.rawValue)"
        case .simulation(let simulation): return "simulation-\(simulation.rawValue)"
        case .apparatus(let apparatus): return "apparatus-\(apparatus.rawValue)"
        case .graph(let graph): return "graph-\(graph.rawValue)"
        }
    }

    private static func title(for action: AdaptiveAction) -> String {
        switch action {
        case .qualitative: return "Qualitative Analysis"
        case .calculation: return "Calculation Practice"
        case .aceTopic(let topic): return topic.label
        case .aceSkill(let skill): return skill.label
        case .simulation(let simulation): return simulation.label
        case .apparatus(let apparatus): return apparatus.label
        case .graph(let graph): return graph.label
        }
    }

    private static func detail(for action: AdaptiveAction, accuracy: Int) -> String {
        let prefix = accuracy < 70 ? "Your recent accuracy is below 70%." : "Your recent results are improving."
        switch action {
        case .qualitative:
            return "\(prefix) Repeat an unknown-sample investigation and practise observation → inference → conclusion."
        case .calculation:
            return "\(prefix) Work through a calculation with units and a step-by-step check."
        case .aceTopic(let topic):
            return "\(prefix) Complete three targeted \(topic.label.lowercased()) questions and review the model answers."
        case .aceSkill(let skill):
            return "\(prefix) Complete targeted \(skill.label.lowercased()) questions before returning to mixed practice."
        case .simulation(let simulation):
            return "\(prefix) Repeat the \(simulation.label.lowercased()) lab and focus on the step where marks were lost."
        case .apparatus(let apparatus):
            return "\(prefix) Re-read the scale and complete another \(apparatus.label.lowercased()) measurement."
        case .graph(let graph):
            return "\(prefix) Rework a \(graph.label.lowercased()) task and check axis labels, plotting and interpretation."
        }
    }
}
