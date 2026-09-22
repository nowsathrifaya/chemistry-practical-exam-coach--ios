
import Foundation

enum Curriculum: String, CaseIterable, Codable, Identifiable {
    case singapore = "SINGAPORE"
    // Kept only for backwards compatibility with older saved preferences.
    // It is intentionally not offered as a selectable curriculum because the
    // app does not contain a separate General curriculum implementation.
    case general = "GENERAL"
    var id: String { rawValue }
    var label: String { self == .singapore ? "Singapore O-Level" : "Legacy / unsupported" }
}

enum PracticalSkill: String, CaseIterable, Codable, Identifiable {
    case planning = "PLANNING"
    case mmo = "MMO"
    case pdo = "PDO"
    case ace = "ACE"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .planning: return "Planning"
        case .mmo: return "Manipulation, Measurement & Observation"
        case .pdo: return "Presentation of Data & Observations"
        case .ace: return "Analysis, Conclusions & Evaluation"
        }
    }
    var shortLabel: String {
        switch self {
        case .planning: return "Planning"
        case .mmo: return "MMO"
        case .pdo: return "PDO"
        case .ace: return "ACE"
        }
    }
}

enum PracticalErrorType: String, CaseIterable, Codable, Identifiable {
    case meniscus = "MENISCUS"
    case unit = "UNIT"
    case precision = "PRECISION"
    case formula = "FORMULA"
    case calculation = "CALCULATION"
    case observationInference = "OBSERVATION_INFERENCE"
    case graphScale = "GRAPH_SCALE"
    case graphPlotting = "GRAPH_PLOTTING"
    case unsupportedConclusion = "UNSUPPORTED_CONCLUSION"
    case controlVariable = "CONTROL_VARIABLE"
    case safety = "SAFETY"
    case technique = "TECHNIQUE"
    case unknown = "UNKNOWN"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .meniscus: return "Meniscus / scale reading"
        case .unit: return "Units"
        case .precision: return "Precision / significant figures"
        case .formula: return "Formula selection"
        case .calculation: return "Calculation"
        case .observationInference: return "Observation vs inference"
        case .graphScale: return "Graph scale"
        case .graphPlotting: return "Graph plotting"
        case .unsupportedConclusion: return "Conclusion not supported by data"
        case .controlVariable: return "Control variables"
        case .safety: return "Safety"
        case .technique: return "Experimental technique"
        case .unknown: return "General"
        }
    }
}

enum ApparatusType: String, CaseIterable, Codable, Identifiable {
    case balance = "BALANCE"
    case burette = "BURETTE"
    case pipette = "PIPETTE"
    case measuringCylinder = "MEASURING_CYLINDER"
    case thermometer = "THERMOMETER"
    case gasSyringe = "GAS_SYRINGE"
    case stopwatch = "STOPWATCH"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .balance: return "Electronic balance"
        case .burette: return "Burette"
        case .pipette: return "Pipette"
        case .measuringCylinder: return "Measuring cylinder"
        case .thermometer: return "Thermometer"
        case .gasSyringe: return "Gas syringe"
        case .stopwatch: return "Stopwatch"
        }
    }
    var unit: String {
        switch self {
        case .balance: return "g"
        case .burette, .pipette, .measuringCylinder: return "cm³"
        case .thermometer: return "°C"
        case .gasSyringe: return "cm³"
        case .stopwatch: return "s"
        }
    }
    static let mvpTypes = Array(ApparatusType.allCases)
}

/// What a Graph Coach dataset is actually marked on. Titration is its own
/// kind rather than a `.gradient` task because a titration curve's slope
/// isn't a meaningful physical constant the way it is for the other graph
/// types — the real skill being tested is locating the equivalence point
/// (the volume at the steepest part of the pH jump), so it gets its own
/// single-tap "mark the end-point" interaction instead of a two-point
/// gradient triangle. See `GraphCoachPracticeView` for how the two modes
/// diverge in the UI.
enum GraphTaskKind {
    case gradient
    case equivalencePoint
}

enum GraphCoachType: String, CaseIterable, Codable, Identifiable {
    case titrationCurve = "TITRATION_CURVE"
    case rateGasVolume = "RATE_GAS_VOLUME"
    case rateConcentration = "RATE_CONCENTRATION"
    case temperatureChange = "TEMPERATURE_CHANGE"
    case chromatography = "CHROMATOGRAPHY"
    var id: String { rawValue }
    struct Definition {
        let label: String
        let xLabel: String
        let xUnit: String
        let yLabel: String
        let yUnit: String
        let gradientMeaning: String
        let taskKind: GraphTaskKind
        /// Shown in a collapsible "Technique tip" card before the student
        /// attempts the graph — exam-technique guidance, not the answer.
        let techniqueTip: String
    }
    var definition: Definition {
        switch self {
        case .titrationCurve:
            return Definition(label:"Titration data", xLabel:"Volume added", xUnit:"cm³", yLabel:"pH / indicator observation", yUnit:"", gradientMeaning:"Identify the end-point from the sharp change in pH or indicator colour.", taskKind: .equivalencePoint, techniqueTip: "The equivalence point is where the curve is steepest, not necessarily where it's highest. Look for the middle of the near-vertical section of the jump, not just the top of the curve.")
        case .rateGasVolume:
            return Definition(label:"Volume of gas vs time", xLabel:"Time", xUnit:"s", yLabel:"Volume of gas", yUnit:"cm³", gradientMeaning:"Gradient represents the rate of reaction at that point.", taskKind: .gradient, techniqueTip: "The initial rate is the tangent right at t = 0, where the curve is steepest — use the first part of the curve, not the flatter section where the reaction is finishing.")
        case .rateConcentration:
            return Definition(label:"Concentration vs time", xLabel:"Time", xUnit:"s", yLabel:"Concentration", yUnit:"mol/dm³", gradientMeaning:"The magnitude of the gradient gives the rate of disappearance or formation, depending on the plotted species.", taskKind: .gradient, techniqueTip: "This curve falls, so your gradient should come out negative. Pick two points well apart on the steep early section for the initial rate.")
        case .temperatureChange:
            return Definition(label:"Temperature change", xLabel:"Time", xUnit:"s", yLabel:"Temperature", yUnit:"°C", gradientMeaning:"Use the temperature-time data to identify the maximum/minimum temperature change.", taskKind: .gradient, techniqueTip: "Draw your gradient triangle across the steepest part of the curve, as close to the start as you can, since that's where the initial rate of temperature change is read.")
        case .chromatography:
            return Definition(label:"Chromatography data", xLabel:"Distance travelled by solvent", xUnit:"cm", yLabel:"Distance travelled by spot", yUnit:"cm", gradientMeaning:"Use the distances to calculate Rf = distance travelled by substance / distance travelled by solvent.", taskKind: .gradient, techniqueTip: "Rf is a ratio, so it has no units — pick two points spread far apart along the line for an accurate gradient, since Rf equals that gradient here.")
        }
    }
    var label: String { definition.label }
}

enum SimulationType: String, CaseIterable, Codable, Identifiable {
    case titration = "TITRATION"
    case qualitativeAnalysis = "QUALITATIVE_ANALYSIS"
    case rateReaction = "RATE_REACTION"
    case electrolysis = "ELECTROLYSIS"
    case chromatography = "CHROMATOGRAPHY"
    case energetics = "ENERGETICS"
    case separation = "SEPARATION"
    case solubility = "SOLUBILITY"
    var id: String { rawValue }

    /// Only Acid–Base Titration is free; every other integrated practical
    /// lab requires the "All Experiments" one-time purchase. Don't check
    /// this directly to decide whether to show a lab — route through
    /// `integratedLabDestination(for:curriculum:repository:purchases:)` in
    /// PremiumGating.swift instead, which is the single place that combines
    /// this with the user's purchase state.
    var isFree: Bool { self == .titration }
    var label: String {
        switch self {
        case .titration: return "Acid–Base Titration"
        case .qualitativeAnalysis: return "Qualitative Analysis"
        case .rateReaction: return "Rate of Reaction"
        case .electrolysis: return "Electrolysis"
        case .chromatography: return "Paper Chromatography"
        case .energetics: return "Energy Changes"
        case .separation: return "Separation & Purification"
        case .solubility: return "Solubility & Crystallisation"
        }
    }
    var descriptionText: String {
        switch self {
        case .titration: return "Practise burette readings, concordant titres, end-points and mole calculations."
        case .qualitativeAnalysis: return "Identify ions and gases from observations, precipitates and confirmatory tests."
        case .rateReaction: return "Change concentration, temperature or surface area and observe how reaction rate changes."
        case .electrolysis: return "Explore electrode products, ion movement and oxidation/reduction at electrodes."
        case .chromatography: return "Separate a mixture and calculate Rf from measured distances."
        case .energetics: return "Compare exothermic and endothermic temperature changes."
        case .separation: return "Choose filtration, crystallisation, distillation, chromatography or a separating funnel."
        case .solubility: return "Explore solubility, saturated solutions and crystallisation."
        }
    }
}

enum AttemptMode: String, Codable {
    case apparatusPractice = "APPARATUS_PRACTICE"
    case graphCoach = "GRAPH_COACH"
    case acePractice = "ACE_PRACTICE"
    case simulationLab = "SIMULATION_LAB"
    case calculationPractice = "CALCULATION_PRACTICE"
}

struct CommonMistake: Identifiable, Codable, Hashable {
    var id: String { title }
    let title: String
    let explanation: String
    let examinerPenalty: String
}

enum ApparatusVisualState: Codable, Hashable {
    case generic
    case burette(readingCm3: Double)
    case thermometer(tempC: Double)
    case measuringCylinder(volumeCm3: Double)
    case balance(massG: Double)
    case gasSyringe(volumeCm3: Double)
    case stopwatch(seconds: Double)
    case pipette
}

struct ApparatusQuestion: Identifiable, Hashable {
    var id: String { "\(apparatusType.rawValue)-\(seed)" }
    let apparatusType: ApparatusType
    let seed: Int
    let prompt: String
    let correctReading: Double
    let tolerance: Double
    let unit: String
    let visualState: ApparatusVisualState
    let commonMistakes: [CommonMistake]
    let examTrap: String
}
struct ApparatusMarkResult {
    let correct: Bool
    let score: Int
    let feedback: [String]
    let mistakeExplanation: String?
    let examTrap: String
}
struct GraphPoint: Hashable, Codable { let x: Double; let y: Double }
struct GraphDataset {
    let type: GraphCoachType
    let seed: Int
    let points: [GraphPoint]
    /// For `.gradient` types: the true underlying gradient. For
    /// `.equivalencePoint` (titration): the true equivalence volume.
    let expectedGradient: Double
    /// Two clean (noise-free) points along the true underlying trend,
    /// spanning the plotted x-range — used only to draw the reference line
    /// shown after marking, so a student can compare their picked triangle
    /// against the real trend. Not shown to the student before they submit.
    let referenceStart: GraphPoint
    let referenceEnd: GraphPoint
}
struct GraphGradientResult {
    let correct: Bool
    let score: Int
    let expectedGradient: Double
    let studentGradient: Double?
    let feedback: [String]
    let explanation: String
    var skillMarks: [PracticalSkillMark] = []
    var mistakes: [PracticalMistake] = []
}
