import Foundation

enum ErrorTaxonomy {
    static func infer(from feedback: [String], target: String) -> PracticalErrorType? {
        let text = (feedback + [target]).joined(separator: " ").lowercased()
        if text.contains("meniscus") || text.contains("burette reading") { return .meniscus }
        if text.contains("unit") { return .unit }
        if text.contains("precision") || text.contains("significant figure") { return .precision }
        if text.contains("formula") { return .formula }
        if text.contains("calculation") || text.contains("arithmetic") { return .calculation }
        if text.contains("observation") && text.contains("inference") { return .observationInference }
        if text.contains("scale") && text.contains("graph") { return .graphScale }
        if text.contains("plot") || text.contains("best-fit") { return .graphPlotting }
        if text.contains("conclusion") { return .unsupportedConclusion }
        if text.contains("controlled variable") || text.contains("control variable") { return .controlVariable }
        if text.contains("safety") || text.contains("hazard") { return .safety }
        if text.contains("technique") || text.contains("apparatus") { return .technique }
        return nil
    }
}
