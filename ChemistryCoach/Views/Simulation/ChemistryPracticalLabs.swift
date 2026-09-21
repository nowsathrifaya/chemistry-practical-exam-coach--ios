import SwiftUI
import Combine

// MARK: - Titration realism model (Section 2: continuous burette flow,
// rough/accurate titrations, concordance, endpoint decision)

enum TitrationMode: String, CaseIterable, Identifiable, Hashable {
    case rough = "Rough"
    case accurate = "Accurate"
    var id: String { rawValue }
}

/// One completed titration attempt: the student opened the tap, watched the
/// flask, and decided when to stop. Recorded exactly as performed — the app
/// never edits a titre after the fact.
struct TitrationRecord: Identifiable, Hashable {
    let id = UUID()
    let attemptNumber: Int
    let mode: TitrationMode
    let initialReading: Double
    let finalReading: Double
    let outcome: String
    let timeTakenSeconds: Double
    var titre: Double { finalReading - initialReading }
}

/// One student-taken gas-volume reading during a rate-of-reaction run.
struct RateReading: Identifiable, Hashable {
    let id = UUID()
    let time: Double
    let volume: Double
}

enum SeparationMixture: String, CaseIterable {
    case saltAndSand = "Sand and salt dissolved in water"
    case immiscibleLiquids = "Two immiscible liquids (oil and water)"
}

@MainActor
final class ChemistryLabViewModel: ObservableObject {
    let type: SimulationType
    let curriculum: Curriculum
    let recorder: LabAttemptRecorder
    @Published var readings: [LabReading] = []
    @Published var result: LabRunResult?
    @Published var input = ""
    @Published var choice = ""
    @Published var electrolysisElectrolyte = "Copper sulfate solution"
    @Published var electrolysisCathode = ""
    @Published var electrolysisAnode = ""
    @Published var electrolysisCircuitOn = false
    @Published var electrolysisCathodeEquation = ""
    @Published var electrolysisAnodeEquation = ""
    @Published var electrolysisHasSwitchedOn = false
    @Published var control: Double = 0.5
    @Published var startedAt: Date?
    @Published var elapsed: Double = 0
    @Published var phase = 0
    @Published var actionState: VirtualLabActionState = .idle
    @Published var observedChanges: [String] = []
    @Published var reactionProgress: Double = 0
    @Published var buretteReading: Double = 0
    @Published var flaskColourProgress: Double = 0
    @Published var lastDropwise: Bool = false
    // Titration realism state (Section 2)
    @Published var titrationMode: TitrationMode = .rough
    @Published var titrationTapOpen: Bool = false
    @Published var titrationInitialReading: Double = 0
    @Published var titrationRecords: [TitrationRecord] = []
    @Published var titrationFlowStartedAt: Date?
    @Published var titrationLastOutcome: String?
    @Published var titrationConcentrationInput: String = ""
    @Published var titrationHCl_M: Double = 0.100
    /// Set when the student chooses to move on despite non-concordant titres.
    @Published var titrationProceedAnyway: Bool = false
    @Published var rateConcentration: Double = 0.5
    @Published var rateTemperature: Double = 0.5
    @Published var rateSurfaceArea: Double = 0.5
    @Published var rateData: [(time: Double, volume: Double)] = []
    // Rate of reaction realism state (Section 5)
    @Published var rateCatalystAdded: Bool = false
    @Published var rateStudentReadings: [RateReading] = []
    @Published var rateTotalSubReadings: Int = 0
    @Published var rateMultipleVariablesChangedCount: Int = 0
    private var lastRateTrialSettings: (concentration: Double, temperature: Double, surfaceArea: Double, catalyst: Bool)?
    @Published var qualitativeReagent = ""
    @Published var reagentBottleOpen = false
    @Published var reagentDispensed = false
    @Published var qualitativeObservation = ""
    @Published var qualitativeStep = 0
    // Separation techniques realism state (Section 8)
    @Published var separationMixtureType: SeparationMixture = .saltAndSand
    @Published var filterPrepared: Bool = false
    @Published var pourRate: Double = 0.4
    @Published var filtered: Bool = false
    @Published var pouredTooFast: Bool = false
    @Published var evaporationChoice: String = ""
    @Published var crystalsObtained: Bool = false
    @Published var funnelDraining: Bool = false
    @Published var funnelDrainedAmount: Double = 0
    @Published var funnelOutcome: String?
    @Published var distillateReady: Bool = false
    // Solubility / crystallisation realism state (Section 9): the student decides when the
    // solution is saturated from what they observe, rather than a hidden "correct stage".
    @Published var solubilityAddedMass: Double = 0
    @Published var solubilityLastPortionDissolved: Bool = true
    @Published var solubilityDeclaredSaturated: Bool = false
    @Published var solubilityPrematureDeclarations: Int = 0
    @Published var solubilityExcessPortions: Int = 0
    @Published var solubilityFilteredExcess: Bool = false
    @Published var solubilityCoolingTemp: Double = 20.0
    @Published var chromatographySolventFront: Double = 0

    // MARK: - Derived animation stages
    //
    // LabScenesProcess.swift drives its tweened animations off simple 0...N
    // stage indices, but the actual student-facing state above is tracked as
    // granular per-step flags (there was never a single "step" counter) —
    // these compute the stage index the animation expects from that state.

    /// 0 = filtering/draining, 1 = evaporating/distilling, 2 = complete.
    var separationStep: Int {
        switch separationMixtureType {
        case .saltAndSand:
            if crystalsObtained { return 2 }
            if filtered { return 1 }
            return 0
        case .immiscibleLiquids:
            if distillateReady { return 2 }
            if funnelOutcome != nil { return 1 }
            return 0
        }
    }

    /// 0 = dissolving, 1 = saturated (about to filter), 2 = filtered and
    /// cooling, 3 = crystallisation result recorded.
    var solubilityStep: Int {
        if result != nil { return 3 }
        if solubilityFilteredExcess { return 2 }
        if solubilityDeclaredSaturated { return 1 }
        return 0
    }
    /// Alias so the animation's mass-dependent visuals (grain count, etc.)
    /// read from the same value the student's own UI shows.
    var solubilityDissolvedMass: Double { solubilityAddedMass }
    /// True once the final crystallisation result has been recorded — the
    /// "crystals drying on the filter paper" stage of the animation.
    var solubilityFiltered: Bool { result != nil }
    // Chromatography realism state (Section 7). chromatographySolventFront is the distance
    // (cm) the solvent has risen ABOVE the baseline — matching the renderer's coordinate system.
    @Published var chromatographyBaselineHeight: Double = 1.0
    @Published var chromatographyMaxTravel: Double = 12.0
    @Published var chromatographyBaselineMistake: Bool = false
    @Published var chromatographyBaselineMistakeCount: Int = 0
    @Published var chromatographyStarted: Bool = false
    @Published var chromatographyRemoved: Bool = false
    @Published var chromatographyRemovalOutcome: String?
    private var chromatographyTrueRf: Double = 0.6
    @Published var energeticsMass: Double = 100.0
    @Published var energeticsInitialTemp: Double = 20.0
    @Published var energeticsFinalTemp: Double = 25.8
    // Energetics realism state (Section 6)
    @Published var energeticsStarted: Bool = false
    @Published var energeticsStirring: Bool = true
    @Published var energeticsElapsedRun: Double = 0
    @Published var energeticsRecordedTemp: Double?
    @Published var energeticsRecordOutcome: String?
    let targetTrials = 3
    /// Drives all apparatus animation (see LabMotion / LabScenes).
    let motion = LabMotion()
    private var timerTask: Task<Void, Never>?
    private var target = 0.0
    private var qualitativeExpected = ""

    init(type: SimulationType, curriculum: Curriculum, repository: AttemptRepository) {
        self.type = type; self.curriculum = curriculum
        self.recorder = LabAttemptRecorder(repository: repository, curriculum: curriculum)
        resetTask()
    }

    deinit { timerTask?.cancel() }

    var instruction: String {
        switch type {
        case .titration: return "Rinse and fill the burette with sodium hydroxide and record the initial reading. Do a rough titration first — open the tap and watch the flask. Repeat accurately: the flow slows automatically as you approach the colour change, becoming dropwise right at the endpoint. Decide for yourself when the pale pink colour looks permanent — the app never tells you the target volume in advance. Repeat until two accurate titres agree within 0.10 cm³, then calculate the concentration from the mean."
        case .qualitativeAnalysis: return "Use a clean test tube. Add the sample first, then the correct reagent. Watch for a precipitate, bubbles, colour change or a gas test result. Record exactly what you see before naming the ion or gas."
        case .rateReaction: return "Set one factor at a time. Place the reactants in the flask, fit the bung and delivery tube, then start the timer as mixing begins. Collect gas over water or in a gas syringe and record volume at regular intervals."
        case .electrolysis: return "Fill the beaker with electrolyte, immerse two inert electrodes without touching them, connect the positive and negative terminals, then switch on the supply. Observe bubbles or deposits at each electrode and test the products safely."
        case .chromatography: return "Draw a pencil baseline, place a small sample spot on the paper, stand the paper in shallow solvent below the baseline, and cover the container. Let the solvent rise, remove the paper before the solvent reaches the top, mark the solvent front and measure from the baseline."
        case .energetics: return "Measure the starting temperature, then mix the reactants in an insulated cup and stir continuously. Watch the temperature — it will keep changing, then plateau, then very slowly drift back to room temperature if you wait too long. Decide for yourself when it has peaked (or bottomed out) and record it. Then calculate ΔT = final − initial."
        case .separation: return "Look at the mixture, choose the correct apparatus, and operate it yourself: fold and wet the filter paper (or open the separating-funnel tap) and judge each step by what you actually see happening, not by picking a method name from a list."
        case .solubility: return "Add solid in small portions, stirring after each one. Stop as soon as you see a trace of solid that will not dissolve even after prolonged stirring — that is saturation. Filter off the excess, then cool to crystallise."
        }
    }

    var currentStage: Int {
        switch type {
        case .solubility:
            let progress = (solubilityDeclaredSaturated ? 2 : 0) + (solubilityFilteredExcess ? 1 : 0) + (solubilityAddedMass > 0 && !solubilityDeclaredSaturated ? 1 : 0)
            return min(progress, type.practicalStages.count - 1)
        case .separation:
            let progress: Int
            switch separationMixtureType {
            case .saltAndSand: progress = (filterPrepared ? 1 : 0) + (filtered ? 1 : 0) + (crystalsObtained ? 1 : 0)
            case .immiscibleLiquids: progress = (funnelOutcome != nil ? 2 : 0) + (distillateReady ? 1 : 0)
            }
            return min(progress, type.practicalStages.count - 1)
        case .titration: return min(stageFromState, type.practicalStages.count - 1)
        default: return min(stageFromState, type.practicalStages.count - 1)
        }
    }


    private var stageFromState: Int {
        switch actionState {
        case .idle: return 0
        case .prepared: return 1
        case .addingReagent, .reacting, .observing: return 1
        case .measured: return 2
        case .analysed: return 3
        }
    }

    var actionHint: String {
        switch actionState {
        case .idle: return "Begin by preparing the apparatus and selecting the required materials."
        case .prepared: return "Carry out the procedure. Watch the apparatus for a visible change."
        case .addingReagent: return "Add carefully and observe the colour, precipitate, bubbles or temperature change."
        case .reacting: return "The reaction is in progress. Wait for the required observation or reading."
        case .observing: return "Record the observation before moving to measurement."
        case .measured: return "Use the observation and measurement to complete the analysis."
        case .analysed: return "All required stages are complete."
        }
    }

    func prepare() { guard result == nil else { return }; actionState = .prepared; reagentBottleOpen = false; reagentDispensed = false; observedChanges.append("Apparatus and reagents checked") }
    func openReagentBottle(_ reagent: String) {
        guard type == .qualitativeAnalysis, result == nil, actionState != .idle else { return }
        qualitativeReagent = reagent
        reagentBottleOpen = true
        reagentDispensed = false
        actionState = .addingReagent
        observedChanges.append("Opened bottle: \(reagent)")
    }
    func dispenseSelectedReagent() {
        guard type == .qualitativeAnalysis, reagentBottleOpen, !qualitativeReagent.isEmpty else { return }
        reagentDispensed = true
        actionState = .reacting
        qualitativeObservation = qualitativeReagent == "Acidified silver nitrate" ? "White precipitate" : qualitativeReagent == "Lighted splint" ? "Squeaky pop" : "Effervescence; limewater milky"
        observedChanges.append("Reagent added; visible reaction is ready to observe")
    }
    func performInteractiveAction() {
        guard result == nil else { return }
        if actionState == .idle { prepare(); return }
        switch type {
        case .titration:
            if titrationRecords.isEmpty && titrationInitialReading == buretteReading && !titrationTapOpen { beginTitrationAttempt(mode: titrationMode) }
            if titrationTapOpen { stopTap() } else { openTap() }
        case .qualitativeAnalysis:
            if !reagentBottleOpen { openReagentBottle(qualitativeReagent.isEmpty ? "Acidified silver nitrate" : qualitativeReagent) }
            else if !reagentDispensed { dispenseSelectedReagent() }
            else { actionState = .observing; reactionProgress = min(1, reactionProgress + 0.25) }
        case .rateReaction:
            if startedAt == nil { startRate() } else { recordGasReading() }
        case .electrolysis:
            toggleElectrolysisCircuit()
        case .chromatography:
            if chromatographyStarted { removeChromatographyPaper() } else if !chromatographyRemoved { placeBaselineAndStart() }
        case .energetics:
            if energeticsStarted { recordEnergeticsTemperature() } else { startEnergeticsReaction() }
        case .separation:
            switch separationMixtureType {
            case .saltAndSand:
                if !filterPrepared { prepareFilter() }
                else if !filtered { pourMixtureThroughFilter() }
                else if evaporationChoice.isEmpty { chooseEvaporation("Until saturated, then cool") }
            case .immiscibleLiquids:
                if funnelOutcome == nil { funnelDraining ? closeFunnelTap() : openFunnelTap() }
                else if !distillateReady { distillCollectedLiquid() }
            }
        case .solubility:
            if !solubilityDeclaredSaturated { addSolidPortion() } else if !solubilityFilteredExcess { filterExcessSolid() }
        }
    }

    func advanceAction() {
        guard result == nil else { return }
        switch actionState {
        case .idle: prepare()
        case .prepared: actionState = type == .rateReaction ? .reacting : .addingReagent
        case .addingReagent: actionState = .observing
        case .reacting: actionState = .observing
        case .observing: actionState = .measured
        case .measured: actionState = .analysed
        case .analysed: break
        }
    }

    var canRecord: Bool {
        guard result == nil else { return false }
        switch type {
        case .titration: return false // titration uses its own dedicated attempt/finalize controls, not the generic Record button
        case .qualitativeAnalysis: return actionState != .idle && !qualitativeReagent.isEmpty && !qualitativeObservation.isEmpty
        case .electrolysis: return electrolysisHasSwitchedOn && !electrolysisCathode.isEmpty && !electrolysisAnode.isEmpty && !electrolysisCathodeEquation.trimmingCharacters(in: .whitespaces).isEmpty && !electrolysisAnodeEquation.trimmingCharacters(in: .whitespaces).isEmpty
        case .separation:
            switch separationMixtureType {
            case .saltAndSand: return crystalsObtained
            case .immiscibleLiquids: return distillateReady
            }
        case .rateReaction: return false // driven by recordGasReading()/stopRateExperiment(), not the generic Record button
        case .chromatography: return chromatographyRemoved && !input.trimmingCharacters(in: .whitespaces).isEmpty
        case .solubility: return solubilityFilteredExcess && !input.trimmingCharacters(in: .whitespaces).isEmpty
        case .energetics: return energeticsRecordedTemp != nil && !input.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var headline: String {
        switch type {
        case .titration: return "Burette reading: \(String(format: "%.2f", buretteReading)) cm³"
        case .qualitativeAnalysis: return qualitativeObservation.isEmpty ? "Add a reagent and observe" : qualitativeObservation
        case .rateReaction: return "Gas collected: \(Int(gasVolume)) cm³"
        case .electrolysis: return "Current: \(String(format: "%.1f", 0.5 + control * 2.5)) A"
        case .chromatography: return chromatographyRemoved ? "Solvent front: \(String(format: "%.1f", chromatographySolventFront)) cm from baseline" : "Place the baseline, then start the solvent rising"
        case .energetics: return "Temperature: \(String(format: "%.1f", energeticsFinalTemp)) °C · ΔT \(String(format: "%+.1f", energeticsFinalTemp - energeticsInitialTemp)) °C"
        case .separation: return "Mixture: \(separationMixtureType.rawValue)"
        case .solubility: return solubilityDeclaredSaturated ? "Saturated at \(String(format: "%.1f", solubilityAddedMass)) g added" : "Added so far: \(String(format: "%.1f", solubilityAddedMass)) g"
        }
    }

    var gasRateConstant: Double {
        0.035 + rateConcentration * 0.055 + rateTemperature * 0.025 + rateSurfaceArea * 0.020 + (rateCatalystAdded ? 0.045 : 0)
    }

    var gasVolume: Double {
        let t = min(elapsed, 60)
        return 72 * (1 - exp(-gasRateConstant * t))
    }

    /// Instantaneous rate of gas production in cm³/s (0 when the reaction is not running).
    var gasRate: Double {
        guard startedAt != nil else { return 0 }
        let k = gasRateConstant
        return 72 * k * exp(-k * min(elapsed, 60))
    }

    func startRate() {
        guard startedAt == nil else { return }
        let start = Date()
        startedAt = start
        elapsed = 0
        rateStudentReadings = []
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, let start = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(start)
                let v = self.gasVolume
                if self.rateData.last?.time != nil && (self.rateData.last!.time - self.elapsed).magnitude < 0.08 { } else { self.rateData.append((self.elapsed, v)) }
            }
        }
    }

    /// The student reads the gas syringe now and logs it — this is the only way readings
    /// enter the results table; nothing is recorded automatically.
    func recordGasReading() {
        guard type == .rateReaction, startedAt != nil, result == nil else { return }
        rateStudentReadings.append(RateReading(time: (elapsed * 10).rounded() / 10, volume: (gasVolume * 10).rounded() / 10))
        rateTotalSubReadings += 1
    }

    var rateCanStop: Bool { type == .rateReaction && startedAt != nil && rateStudentReadings.count >= 3 }

    /// Steepest early gradient (first two readings) — the *initial* rate.
    var rateInitialRate: Double? {
        let sorted = rateStudentReadings.sorted { $0.time < $1.time }
        guard sorted.count >= 2 else { return nil }
        let dt = sorted[1].time - sorted[0].time
        guard dt > 0 else { return nil }
        return (sorted[1].volume - sorted[0].volume) / dt
    }

    /// Total volume produced divided by total time — the *average* rate over the whole run.
    var rateAverageRate: Double? {
        let sorted = rateStudentReadings.sorted { $0.time < $1.time }
        guard let first = sorted.first, let last = sorted.last, last.time > first.time else { return nil }
        return (last.volume - first.volume) / (last.time - first.time)
    }

    /// Ends the current run: checks whether more than one variable changed since the last
    /// trial (an unfair test), logs the trial's average rate, and resets for the next run.
    func stopRateExperiment() {
        guard rateCanStop else { return }
        let settings = (concentration: rateConcentration, temperature: rateTemperature, surfaceArea: rateSurfaceArea, catalyst: rateCatalystAdded)
        if let last = lastRateTrialSettings {
            var changed = 0
            if abs(last.concentration - settings.concentration) > 0.05 { changed += 1 }
            if abs(last.temperature - settings.temperature) > 0.05 { changed += 1 }
            if abs(last.surfaceArea - settings.surfaceArea) > 0.05 { changed += 1 }
            if last.catalyst != settings.catalyst { changed += 1 }
            if changed > 1 { rateMultipleVariablesChangedCount += 1 }
        }
        lastRateTrialSettings = settings
        let avg = rateAverageRate ?? 0
        readings.append(LabReading(trialNumber: readings.count + 1, label: "Trial \(readings.count + 1) average rate", value: avg, unit: "cm³/s"))
        startedAt = nil; timerTask?.cancel(); timerTask = nil
        rateStudentReadings = []
        if readings.count >= targetTrials { grade() }
    }

    // MARK: - Energetics: continuous temperature curve with a peak-reading decision (Section 6)

    private var energeticsK1: Double { energeticsStirring ? 0.30 : 0.12 }
    private var energeticsTPeak: Double { 3.5 / energeticsK1 }

    /// Modelled flask temperature at time t: rises (or falls) toward the true ΔT, then — since
    /// no calorimeter is perfectly insulated — slowly drifts back toward room temperature if
    /// the student keeps watching past the peak.
    func energeticsTempAt(_ t: Double) -> Double {
        let tPeak = energeticsTPeak
        if t <= tPeak {
            return energeticsInitialTemp + target * (1 - exp(-energeticsK1 * t))
        } else {
            let peakRise = target * (1 - exp(-energeticsK1 * tPeak))
            return energeticsInitialTemp + peakRise * exp(-0.010 * (t - tPeak))
        }
    }

    func startEnergeticsReaction() {
        guard type == .energetics, result == nil, !energeticsStarted else { return }
        energeticsStarted = true
        energeticsElapsedRun = 0
        energeticsRecordedTemp = nil
        energeticsRecordOutcome = nil
        energeticsFinalTemp = energeticsInitialTemp
        actionState = .reacting
        observedChanges.append(energeticsStirring ? "Reactants mixed and stirred continuously" : "Reactants mixed without stirring")
        let start = Date()
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(150))
                guard let self, self.energeticsStarted, self.result == nil else { return }
                self.energeticsElapsedRun = Date().timeIntervalSince(start)
                self.energeticsFinalTemp = self.energeticsTempAt(self.energeticsElapsedRun)
            }
        }
    }

    /// The student's decision: "the thermometer looks like it has peaked (or bottomed out) — record it now."
    func recordEnergeticsTemperature() {
        guard type == .energetics, energeticsStarted, result == nil else { return }
        timerTask?.cancel(); timerTask = nil
        energeticsStarted = false
        let recorded = energeticsFinalTemp
        energeticsRecordedTemp = recorded
        let tPeak = energeticsTPeak
        let peakRise = target * (1 - exp(-energeticsK1 * tPeak))
        let peakTemp = energeticsInitialTemp + peakRise
        let deviationFromPeak = abs(recorded - peakTemp)
        let outcome: String
        if energeticsElapsedRun < tPeak * 0.6 {
            outcome = "Recorded too early"
        } else if deviationFromPeak > 0.5 {
            outcome = "Recorded after cooling began"
        } else {
            outcome = target > 0 ? "Peak temperature captured well" : "Lowest temperature captured well"
        }
        energeticsRecordOutcome = outcome
        actionState = .observing
        observedChanges.append("\(outcome): recorded \(String(format: "%.1f", recorded))°C at t = \(String(format: "%.0f", energeticsElapsedRun)) s")
    }

    // MARK: - Chromatography: baseline placement + continuous solvent rise (Section 7)

    /// Position of the substance spot right now (distance above the baseline), worked out
    /// from the true (hidden) Rf value.
    var chromatographySpotPosition: Double {
        chromatographyTrueRf * chromatographySolventFront
    }

    /// The student's setup decision: the baseline must sit above the solvent surface in the
    /// beaker. If it doesn't, the sample washes straight into the solvent instead of being
    /// carried up the paper.
    func placeBaselineAndStart() {
        guard type == .chromatography, result == nil, !chromatographyStarted, !chromatographyRemoved else { return }
        if chromatographyBaselineHeight <= 0.35 {
            chromatographyBaselineMistake = true
            chromatographyBaselineMistakeCount += 1
            observedChanges.append("The baseline touched the solvent — the sample has dissolved directly into the solvent.")
            return
        }
        chromatographyBaselineMistake = false
        chromatographyStarted = true
        chromatographySolventFront = 0
        actionState = .reacting
        observedChanges.append("Paper placed in the solvent chamber; the solvent front begins to rise.")
        let start = Date()
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, self.chromatographyStarted, self.result == nil else { return }
                let t = Date().timeIntervalSince(start)
                self.chromatographySolventFront = min(self.chromatographyMaxTravel, 0.55 * t)
            }
        }
    }

    /// The student's decision: "the solvent front looks close enough to the top — remove it now."
    func removeChromatographyPaper() {
        guard type == .chromatography, chromatographyStarted, result == nil else { return }
        timerTask?.cancel(); timerTask = nil
        chromatographyStarted = false
        chromatographyRemoved = true
        actionState = .observing
        let outcome: String
        if chromatographySolventFront >= chromatographyMaxTravel - 0.1 {
            outcome = "Solvent ran off the top of the paper"
        } else if chromatographySolventFront < 2.0 {
            outcome = "Removed too early — too little separation"
        } else {
            outcome = "Removed at a good time"
        }
        chromatographyRemovalOutcome = outcome
        observedChanges.append("\(outcome). Solvent front marked \(String(format: "%.1f", chromatographySolventFront)) cm above the baseline.")
    }

    // MARK: - Separation techniques: real apparatus operation (Section 8)

    /// Filtration path (sand + salt dissolved in water): fold and wet the paper, then pour.
    func prepareFilter() {
        guard type == .separation, separationMixtureType == .saltAndSand, !filterPrepared else { return }
        filterPrepared = true
        observedChanges.append("Filter paper folded into a cone, wetted, and seated in the funnel.")
    }

    /// Pouring too fast overflows the filter paper and lets solid escape into the filtrate.
    func pourMixtureThroughFilter() {
        guard type == .separation, filterPrepared, !filtered else { return }
        filtered = true
        if pourRate > 0.7 {
            pouredTooFast = true
            observedChanges.append("Poured too quickly — the level rose above the rim of the filter paper and some sand escaped into the filtrate.")
        } else {
            observedChanges.append("Residue (sand) remains in the filter paper; filtrate (salt solution) collects in the beaker below.")
        }
    }

    /// The classic real mistake: evaporating a filtrate fully to dryness instead of stopping
    /// at saturation and letting it cool to crystallise.
    func chooseEvaporation(_ choice: String) {
        guard type == .separation, filtered, evaporationChoice.isEmpty else { return }
        evaporationChoice = choice
        crystalsObtained = true
        if choice == "Until saturated, then cool" {
            observedChanges.append("Crystals form as the saturated solution cools — a good yield of well-formed crystals.")
        } else {
            observedChanges.append("Evaporating to dryness caused spitting and produced small, poor-quality crystals fused to the dish.")
        }
    }

    /// Separating-funnel path: the denser liquid drains from the bottom tap. The student must
    /// close the tap right at the interface — too early wastes yield, too late mixes the layers.
    func openFunnelTap() {
        guard type == .separation, separationMixtureType == .immiscibleLiquids, funnelOutcome == nil, !funnelDraining else { return }
        funnelDraining = true
        actionState = .reacting
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(150))
                guard let self, self.funnelDraining, self.result == nil else { return }
                self.funnelDrainedAmount = min(1.4, self.funnelDrainedAmount + 0.05)
            }
        }
    }

    func closeFunnelTap() {
        guard type == .separation, funnelDraining else { return }
        funnelDraining = false
        timerTask?.cancel(); timerTask = nil
        actionState = .observing
        let outcome: String
        if funnelDrainedAmount < 0.85 {
            outcome = "Closed too early — some of the lower layer was left behind"
        } else if funnelDrainedAmount <= 1.08 {
            outcome = "Closed at the interface — clean separation"
        } else {
            outcome = "Closed too late — the layers mixed together"
        }
        funnelOutcome = outcome
        observedChanges.append(outcome)
    }

    func distillCollectedLiquid() {
        guard type == .separation, funnelOutcome != nil, !distillateReady else { return }
        distillateReady = true
        observedChanges.append("Heated the collected liquid; it boiled at a constant temperature and the distillate was collected past the condenser.")
    }

    // MARK: - Solubility: saturation is a judgement call, not a fixed stage (Section 9)

    /// Adds one small portion of solid, stirs it in, and reports whether it fully dissolved.
    /// The student must read this observation themselves to decide whether to add more.
    func addSolidPortion() {
        guard type == .solubility, !solubilityDeclaredSaturated, result == nil else { return }
        solubilityAddedMass += 1.0
        let dissolvedFully = solubilityAddedMass <= target
        solubilityLastPortionDissolved = dissolvedFully
        if !dissolvedFully { solubilityExcessPortions += 1 }
        observedChanges.append(dissolvedFully ? "Portion dissolved completely on stirring." : "A little solid remains undissolved even after prolonged stirring.")
    }

    /// The student's decision: "I've seen a trace of undissolved solid — this is saturated."
    func declareSaturated() {
        guard type == .solubility, !solubilityDeclaredSaturated, result == nil else { return }
        if solubilityLastPortionDissolved {
            solubilityPrematureDeclarations += 1
            observedChanges.append("Declared saturated while everything was still dissolving — add more solid and check again.")
        } else {
            solubilityDeclaredSaturated = true
            observedChanges.append("Saturation reached: \(String(format: "%.1f", solubilityAddedMass)) g added, a trace of solid remains undissolved.")
        }
    }

    func filterExcessSolid() {
        guard type == .solubility, solubilityDeclaredSaturated, !solubilityFilteredExcess else { return }
        solubilityFilteredExcess = true
        observedChanges.append("Excess undissolved solid filtered off, leaving a clear saturated filtrate.")
    }

    /// Cooling further lowers solubility, so more crystals come out of solution — a simple
    /// physically-motivated model relating the true saturation mass to the cooling temperature.
    var solubilityExpectedYield: Double {
        let coolingFactor = max(0.3, min(0.9, (90.0 - solubilityCoolingTemp) / 90.0))
        return (target * coolingFactor * 10).rounded() / 10
    }

    // MARK: - Titration: continuous burette flow (Section 2)

    /// Signed distance in cm³ from the true (hidden) endpoint. Negative = before, positive = past.
    var titrationDistanceFromTarget: Double { buretteReading - target }

    /// Discrete colour the flask would show right now. Distinct from `flaskColourProgress`
    /// (which still drives the continuous Canvas tint) so wording stays in sync with the model.
    enum TitrationColour: String { case colourless = "Colourless", temporaryPink = "Temporary pale pink", permanentPink = "Faint permanent pink", overshot = "Deep pink (overshot)" }
    var titrationColour: TitrationColour {
        let d = titrationDistanceFromTarget
        if d < -0.15 { return .colourless }
        if d < -0.02 { return .temporaryPink }
        if d <= 0.06 { return .permanentPink }
        return .overshot
    }

    /// Opens the burette tap. Flow is continuous and drop-by-drop; it automatically
    /// slows as the flask approaches the true endpoint colour change, and becomes
    /// dropwise right at the endpoint — the student is never told the target volume.
    func openTap() {
        guard type == .titration, result == nil, titrationLastOutcome == nil else { return }
        if titrationFlowStartedAt == nil { titrationFlowStartedAt = Date() }
        titrationTapOpen = true
        actionState = .addingReagent
        motion.kickSwirl(0.3)
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.titrationTapOpen, self.result == nil else { return }
                let distance = abs(self.titrationDistanceFromTarget)
                let increment: Double
                let sleepMs: UInt64
                if distance > 0.6 {
                    increment = self.titrationMode == .rough ? 0.32 : 0.22
                    sleepMs = 110
                } else if distance > 0.15 {
                    increment = 0.05
                    sleepMs = 240
                } else {
                    increment = 0.02
                    sleepMs = 460
                }
                self.buretteReading = min(50, self.buretteReading + increment)
                self.flaskColourProgress = min(1, max(0, (self.buretteReading - self.target + 0.8) / 1.6))
                try? await Task.sleep(for: .milliseconds(sleepMs))
            }
        }
    }

    /// Stops the tap. This is not a final decision — the student may reopen it and
    /// keep watching for the colour change to become permanent.
    func stopTap() {
        guard type == .titration else { return }
        titrationTapOpen = false
        timerTask?.cancel(); timerTask = nil
        if actionState == .addingReagent { actionState = .observing }
    }

    var titrationCanStartAttempt: Bool { type == .titration && result == nil && !titrationTapOpen && buretteReading == titrationInitialReading }

    /// Starts a fresh titration attempt (rough or accurate) from the current burette level.
    func beginTitrationAttempt(mode: TitrationMode) {
        guard type == .titration, result == nil, !titrationTapOpen else { return }
        titrationMode = mode
        titrationInitialReading = buretteReading
        titrationFlowStartedAt = nil
        titrationLastOutcome = nil
        actionState = .prepared
        observedChanges.append("\(mode.rawValue) titration started at \(String(format: "%.2f", buretteReading)) cm³")
    }

    /// The student's decision: "the colour change looks permanent, stop here."
    /// Grades early/late/on-target without ever having shown the target volume.
    @discardableResult
    func confirmEndpoint() -> String {
        stopTap()
        let d = titrationDistanceFromTarget
        let outcome: String
        if d < -0.05 { outcome = "Endpoint not reached" }
        else if d > 0.08 { outcome = "Overshot endpoint" }
        else { outcome = "Endpoint detected" }
        titrationLastOutcome = outcome
        let timeTaken = titrationFlowStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let record = TitrationRecord(attemptNumber: titrationRecords.count + 1, mode: titrationMode, initialReading: titrationInitialReading, finalReading: buretteReading, outcome: outcome, timeTakenSeconds: timeTaken)
        titrationRecords.append(record)
        readings.append(LabReading(trialNumber: readings.count + 1, label: "\(record.mode.rawValue) titre (\(outcome))", value: record.titre, unit: "cm³"))
        observedChanges.append("\(outcome): titre = \(String(format: "%.2f", record.titre)) cm³")
        // A wrong endpoint is a scored practical mistake, not a dead end.
        // Move the workflow forward so the student can refill and continue with
        // the next attempt / calculation using the reading they actually took.
        actionState = .measured
        return outcome
    }

    /// Refills the burette for the next attempt, keeping the history of past attempts.
    func refillBurette() {
        guard type == .titration, result == nil, !titrationTapOpen else { return }
        buretteReading = 0
        titrationInitialReading = 0
        flaskColourProgress = 0
        titrationLastOutcome = nil
        titrationFlowStartedAt = nil
        actionState = .prepared
    }

    var titrationAccurateRecords: [TitrationRecord] { titrationRecords.filter { $0.mode == .accurate } }

    /// Two accurate titres within 0.10 cm³ of each other, as O-Level practice requires.
    var titrationConcordantPair: (TitrationRecord, TitrationRecord)? {
        let accurate = titrationAccurateRecords
        for i in 0..<accurate.count {
            for j in (i + 1)..<accurate.count where accurate.indices.contains(j) {
                if abs(accurate[i].titre - accurate[j].titre) <= 0.10 { return (accurate[i], accurate[j]) }
            }
        }
        return nil
    }
    var titrationIsConcordant: Bool { titrationConcordantPair != nil }

    /// The two most recent accurate titres, whether or not they're concordant — used as a
    /// fallback so the student isn't stuck forever if their technique never converges.
    var titrationLastTwoAccurate: (TitrationRecord, TitrationRecord)? {
        let accurate = titrationAccurateRecords
        guard accurate.count >= 2 else { return nil }
        return (accurate[accurate.count - 2], accurate[accurate.count - 1])
    }
    /// True once there are at least two accurate titres to work with, even if they don't
    /// yet agree — this is what unlocks the "proceed anyway" option.
    var titrationCanProceedWithoutConcordance: Bool { !titrationIsConcordant && titrationLastTwoAccurate != nil && !titrationTapOpen }

    /// The student's own decision to move on despite non-concordant titres. Like the
    /// water-of-crystallisation "declare constant mass" call, this doesn't block progress —
    /// it just carries a scoring penalty and a warning, since the app already told them their
    /// titres don't agree.
    @discardableResult
    func proceedWithoutConcordantTitres() -> Bool {
        guard titrationCanProceedWithoutConcordance else { return false }
        titrationProceedAnyway = true
        return true
    }

    var titrationMeanConcordantTitre: Double? {
        if let pair = titrationConcordantPair { return (pair.0.titre + pair.1.titre) / 2 }
        if titrationProceedAnyway, let pair = titrationLastTwoAccurate { return (pair.0.titre + pair.1.titre) / 2 }
        return nil
    }
    var titrationExpectedConcentration: Double? {
        guard let mean = titrationMeanConcordantTitre, mean > 0 else { return nil }
        // 25.0 cm³ of standard HCl is pipetted into the flask; NaOH is titrated from the burette (1:1 reaction).
        let molesHCl = titrationHCl_M * 25.0 / 1000
        return molesHCl / (mean / 1000)
    }
    var titrationCanFinalize: Bool { titrationMeanConcordantTitre != nil && !titrationTapOpen }

    /// Completes the titration: checks the student's concentration calculation,
    /// builds a per-skill mark breakdown, and records the attempt.
    func finalizeTitration() {
        guard type == .titration, titrationCanFinalize, result == nil else { return }
        let mean = titrationMeanConcordantTitre ?? 0
        let expected = titrationExpectedConcentration ?? 0
        let studentValue = Double(titrationConcentrationInput.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
        let calcCorrect = studentValue.map { abs($0 - expected) <= max(expected * 0.05, 0.002) } ?? false

        var mistakes: [PracticalMistake] = []
        let overshoots = titrationRecords.filter { $0.outcome == "Overshot endpoint" }
        let earlyStops = titrationRecords.filter { $0.outcome == "Endpoint not reached" }
        let didRoughFirst = titrationRecords.first?.mode == .rough
        if !overshoots.isEmpty { mistakes.append(PracticalMistake(title: "Overshot the endpoint \(overshoots.count) time(s)", consequence: "Adding titrant too quickly near the colour change gives a titre that is too high, which increases the calculated concentration.")) }
        if !earlyStops.isEmpty { mistakes.append(PracticalMistake(title: "Stopped before the colour became permanent \(earlyStops.count) time(s)", consequence: "Stopping too early gives a titre that is too low, which decreases the calculated concentration.")) }
        if !didRoughFirst { mistakes.append(PracticalMistake(title: "Skipped the rough titration", consequence: "Without a rough titre to estimate the endpoint, it is easy to overshoot on the first accurate run.")) }
        let usedConcordantPair = titrationConcordantPair
        if usedConcordantPair == nil, let pair = titrationLastTwoAccurate {
            let diff = abs(pair.0.titre - pair.1.titre)
            mistakes.append(PracticalMistake(title: "Proceeded without concordant titres", consequence: "Your two most recent accurate titres differed by \(String(format: "%.2f", diff)) cm³ — more than the 0.10 cm³ required for concordance — so the mean used for the calculation is less reliable than it should be."))
        }

        let endpointSkill = overshoots.isEmpty && earlyStops.isEmpty ? 10 : max(4, 10 - (overshoots.count + earlyStops.count) * 2)
        let apparatusSkill = didRoughFirst ? 10 : 6
        let concordanceSkill = usedConcordantPair != nil ? 10 : 3
        let measurementSkill = 8
        let calcSkill = calcCorrect ? 10 : (studentValue == nil ? 0 : 4)
        let totalOutOf = 50
        let totalScored = endpointSkill + apparatusSkill + concordanceSkill + measurementSkill + calcSkill
        let percentScore = Int((Double(totalScored) / Double(totalOutOf)) * 100)

        let pairForFeedback = usedConcordantPair ?? titrationLastTwoAccurate
        var feedback: [String] = [
            usedConcordantPair != nil
                ? "Concordant titres: \(String(format: "%.2f", pairForFeedback?.0.titre ?? 0)) cm³ and \(String(format: "%.2f", pairForFeedback?.1.titre ?? 0)) cm³ (within 0.10 cm³)."
                : "Non-concordant titres used: \(String(format: "%.2f", pairForFeedback?.0.titre ?? 0)) cm³ and \(String(format: "%.2f", pairForFeedback?.1.titre ?? 0)) cm³ (not within 0.10 cm³).",
            "Mean titre used for calculation: \(String(format: "%.2f", mean)) cm³.",
            calcCorrect ? "Your calculated concentration of \(studentValue.map { String(format: "%.3f", $0) } ?? "-") mol/dm³ matches the expected value within tolerance." : "Expected concentration ≈ \(String(format: "%.3f", expected)) mol/dm³ from moles HCl = moles NaOH at the end-point."
        ]
        if overshoots.isEmpty && earlyStops.isEmpty { feedback.append("Every recorded endpoint was detected correctly — well judged.") }

        let outcome = LabRunResult(
            correct: percentScore >= 80,
            score: percentScore,
            feedback: feedback,
            examTip: examTrap,
            skillMarks: [
                PracticalSkillMark(skill: "Endpoint recognition", scored: endpointSkill, outOf: 10),
                PracticalSkillMark(skill: "Apparatus technique (rough first)", scored: apparatusSkill, outOf: 10),
                PracticalSkillMark(skill: "Concordance", scored: concordanceSkill, outOf: 10),
                PracticalSkillMark(skill: "Measurement", scored: measurementSkill, outOf: 10),
                PracticalSkillMark(skill: "Calculation", scored: calcSkill, outOf: 10)
            ],
            mistakes: mistakes
        )
        result = outcome
        recorder.record(experimentTitle: type.label, result: outcome)
    }

    func record() {
        guard canRecord else { return }
        switch type {
        case .titration:
            break // handled by confirmEndpoint()/finalizeTitration(); canRecord is always false here
        case .qualitativeAnalysis:
            let correct = qualitativeCorrect
            readings.append(LabReading(trialNumber: readings.count + 1, label: qualitativeReagent, value: correct ? 1 : 0, unit: correct ? "correct" : "review"))
        case .rateReaction:
            break // driven by recordGasReading()/stopRateExperiment(); canRecord is always false here
        case .electrolysis:
            let score = electrolysisCorrect ? 1.0 : 0.0
            readings.append(LabReading(trialNumber: readings.count + 1, label: "Electrode products", value: score, unit: score == 1 ? "correct" : "review"))
        case .chromatography:
            let spot = Double(input.replacingOccurrences(of: ",", with: ".")) ?? -1
            let solvent = chromatographySolventFront
            readings.append(LabReading(trialNumber: readings.count + 1, label: "Spot distance", value: spot, unit: "cm", derivedLabel: "Rf", derivedValue: solvent > 0 ? spot / solvent : nil, derivedUnit: ""))
        case .energetics:
            let studentDelta = Double(input.replacingOccurrences(of: ",", with: ".")) ?? 0
            let measuredDelta = (energeticsRecordedTemp ?? energeticsFinalTemp) - energeticsInitialTemp
            readings.append(LabReading(trialNumber: readings.count + 1, label: "ΔT (your calculation)", value: studentDelta, unit: "°C", derivedLabel: "Measured ΔT", derivedValue: measuredDelta, derivedUnit: "°C"))
        case .separation:
            let complete: Bool
            switch separationMixtureType {
            case .saltAndSand: complete = !pouredTooFast && evaporationChoice == "Until saturated, then cool"
            case .immiscibleLiquids: complete = funnelOutcome == "Closed at the interface — clean separation"
            }
            readings.append(LabReading(trialNumber: readings.count + 1, label: "Separation technique", value: complete ? 1 : 0, unit: complete ? "correct" : "review"))
        case .solubility:
            let mass = Double(input.replacingOccurrences(of: ",", with: ".")) ?? 0
            readings.append(LabReading(trialNumber: readings.count + 1, label: "Crystals recovered", value: mass, unit: "g", derivedLabel: "Expected yield", derivedValue: solubilityExpectedYield, derivedUnit: "g"))
        }
        let requiredTrials = (type == .electrolysis) ? 1 : targetTrials
        let shouldGrade = readings.count >= requiredTrials
        if shouldGrade { grade() }
        input = ""
        choice = ""
        electrolysisCathode = ""; electrolysisAnode = ""
        qualitativeReagent = ""; qualitativeObservation = ""; reagentBottleOpen = false; reagentDispensed = false; qualitativeStep = 0; solubilityCoolingTemp = 20.0
        solubilityAddedMass = 0; solubilityLastPortionDissolved = true; solubilityDeclaredSaturated = false; solubilityFilteredExcess = false
        filterPrepared = false; pourRate = 0.4; filtered = false; pouredTooFast = false; evaporationChoice = ""; crystalsObtained = false; funnelDraining = false; funnelDrainedAmount = 0; funnelOutcome = nil; distillateReady = false
        control = 0.5
        chromatographySolventFront = 0; chromatographyBaselineHeight = 1.0; chromatographyBaselineMistake = false; chromatographyStarted = false; chromatographyRemoved = false; chromatographyRemovalOutcome = nil
        energeticsMass = 100.0; energeticsInitialTemp = 20.0; energeticsFinalTemp = 25.8; energeticsStarted = false; energeticsElapsedRun = 0; energeticsRecordedTemp = nil; energeticsRecordOutcome = nil
        rateConcentration = 0.5; rateTemperature = 0.5; rateSurfaceArea = 0.5; rateData = []
        buretteReading = 0
        flaskColourProgress = 0
        lastDropwise = false
    }

    func grade() {
        guard readings.count > 0 else { return }
        var score = 0
        var feedback: [String] = []
        var resultSkillMarks: [PracticalSkillMark] = []
        var resultMistakes: [PracticalMistake] = []
        switch type {
        case .titration:
            let values = readings.map(\.value)
            let avg = values.reduce(0, +) / Double(values.count)
            let concordant = values.contains { abs($0 - avg) <= 0.20 }
            let accurate = abs(avg - target) <= 0.20
            score = accurate ? (concordant ? 100 : 85) : 55
            feedback += ["Mean titre: \(String(format: "%.2f", avg)) cm³. Target endpoint: \(String(format: "%.2f", target)) cm³.", concordant ? "Your titres show acceptable concordance." : "Aim for two titres within 0.20 cm³ before using a mean.", accurate ? "The endpoint is within coaching tolerance." : "Approach the colour change dropwise near the endpoint."]
        case .qualitativeAnalysis:
            let correct = readings.filter { $0.value == 1 }.count
            score = correct == readings.count ? 100 : Int(Double(correct) / Double(readings.count) * 100)
            feedback = ["You completed \(readings.count) qualitative test(s).", "Write colour, precipitate, solubility and gas-test observations before naming the ion."]
        case .rateReaction:
            let avgReadingsPerTrial = readings.isEmpty ? 0 : Double(rateTotalSubReadings) / Double(readings.count)
            let fairTest = rateMultipleVariablesChangedCount == 0
            let techniqueGood = avgReadingsPerTrial >= 4
            let fairTestSkill = fairTest ? 10 : max(2, 10 - rateMultipleVariablesChangedCount * 4)
            let techniqueSkill = techniqueGood ? 10 : 5
            score = Int((Double(fairTestSkill + techniqueSkill) / 20.0) * 100)
            feedback = [
                "You took an average of \(String(format: "%.1f", avgReadingsPerTrial)) volume readings per trial.",
                fairTest ? "You changed only one variable between trials — a fair test." : "You changed more than one variable between some trials, which makes the comparison invalid.",
                "Initial rate (steepest early gradient) is usually higher than the average rate over the whole run, because the reaction slows as reactants are used up."
            ]
            resultSkillMarks = [
                PracticalSkillMark(skill: "Fair testing", scored: fairTestSkill, outOf: 10),
                PracticalSkillMark(skill: "Measurement technique", scored: techniqueSkill, outOf: 10)
            ]
            if !fairTest { resultMistakes.append(PracticalMistake(title: "Changed more than one variable between trials", consequence: "If concentration and temperature both change at once, you cannot tell which one caused the difference in rate.")) }
            if !techniqueGood { resultMistakes.append(PracticalMistake(title: "Too few readings per trial", consequence: "With only a couple of points you cannot see how the rate changes over time or plot a reliable graph.")) }
        case .electrolysis:
            let productsRight = electrolysisCorrect
            let cathodeEqRight = electrolysisCathodeEquationCorrect
            let anodeEqRight = electrolysisAnodeEquationCorrect
            let productsSkill = productsRight ? 10 : 3
            let cathodeEqSkill = cathodeEqRight ? 10 : 3
            let anodeEqSkill = anodeEqRight ? 10 : 3
            let switchSkill = electrolysisHasSwitchedOn ? 10 : 0
            score = Int((Double(productsSkill + cathodeEqSkill + anodeEqSkill + switchSkill) / 40.0) * 100)
            feedback = [
                productsRight ? "Cathode and anode products are consistent with \(electrolysisElectrolyte.lowercased())." : "Re-check ion discharge for \(electrolysisElectrolyte.lowercased()): \(electrolysisIonCompetitionNote)",
                cathodeEqRight ? "Cathode half-equation looks right." : "Check the cathode half-equation — it should show the species gaining electrons (reduction).",
                anodeEqRight ? "Anode half-equation looks right." : "Check the anode half-equation — it should show the species losing electrons (oxidation)."
            ]
            resultSkillMarks = [
                PracticalSkillMark(skill: "Electrode products", scored: productsSkill, outOf: 10),
                PracticalSkillMark(skill: "Cathode half-equation", scored: cathodeEqSkill, outOf: 10),
                PracticalSkillMark(skill: "Anode half-equation", scored: anodeEqSkill, outOf: 10),
                PracticalSkillMark(skill: "Apparatus technique (switched on, observed)", scored: switchSkill, outOf: 10)
            ]
            if !productsRight { resultMistakes.append(PracticalMistake(title: "Predicted the wrong electrode products", consequence: "Ion discharge depends on reactivity/concentration, not on which ion is written first in the formula.")) }
        case .chromatography:
            let rfs = readings.compactMap(\.derivedValue); let mean = rfs.reduce(0,+)/Double(max(rfs.count,1))
            let calcOK = abs(mean - chromatographyTrueRf) <= 0.06
            let outcome = chromatographyRemovalOutcome ?? "Removed at a good time"
            let timingGood = outcome == "Removed at a good time"
            let baselineGood = chromatographyBaselineMistakeCount == 0
            let baselineSkill = baselineGood ? 10 : 3
            let timingSkill = timingGood ? 10 : 4
            let calcSkill = calcOK ? 10 : 4
            score = Int((Double(baselineSkill + timingSkill + calcSkill) / 30.0) * 100)
            feedback = [
                "Mean Rf: \(String(format: "%.2f", mean)) (Rf has no unit).",
                "Rf = distance travelled by the substance ÷ distance travelled by the solvent front, both measured from the baseline.",
                timingGood ? "You removed the paper at a good time." : "Removal timing needs work — see the note below."
            ]
            resultSkillMarks = [
                PracticalSkillMark(skill: "Baseline placement", scored: baselineSkill, outOf: 10),
                PracticalSkillMark(skill: "Removal timing", scored: timingSkill, outOf: 10),
                PracticalSkillMark(skill: "Rf calculation", scored: calcSkill, outOf: 10)
            ]
            if !baselineGood { resultMistakes.append(PracticalMistake(title: "Baseline touched the solvent \(chromatographyBaselineMistakeCount) time(s)", consequence: "The sample dissolved into the solvent instead of being carried up the paper, so no spot can be measured.")) }
            if outcome == "Solvent ran off the top of the paper" { resultMistakes.append(PracticalMistake(title: "Solvent ran off the top of the paper", consequence: "Once the front runs past the edge of the paper, the solvent-front distance is no longer well defined, so Rf becomes unreliable.")) }
            if outcome == "Removed too early — too little separation" { resultMistakes.append(PracticalMistake(title: "Removed the paper too early", consequence: "With very little separation, small measurement errors have a much bigger effect on the calculated Rf.")) }
            if !calcOK { resultMistakes.append(PracticalMistake(title: "Measured Rf did not match the true separation", consequence: "Check that both the spot distance and the solvent-front distance were measured from the same baseline.")) }
        case .energetics:
            let calcErrors = readings.filter { r in guard let measured = r.derivedValue else { return true }; return abs(r.value - measured) > 0.4 }.count
            let calcSkill = max(0, 10 - calcErrors * 4)
            let technique = energeticsRecordOutcome ?? "Peak temperature captured well"
            let techniqueGood = technique.contains("captured well")
            let techniqueSkill = techniqueGood ? 10 : 4
            let stirSkill = energeticsStirring ? 10 : 5
            score = Int((Double(calcSkill + techniqueSkill + stirSkill) / 30.0) * 100)
            let meanMeasured = (readings.compactMap(\.derivedValue).reduce(0, +)) / Double(max(readings.count, 1))
            feedback = [
                "Mean measured ΔT: \(String(format: "%.1f", meanMeasured)) °C.",
                target > 0 ? "A temperature rise supports an exothermic interpretation." : "A temperature fall supports an endothermic interpretation.",
                techniqueGood ? "You captured the true peak/trough temperature well." : "Reading technique needs work — see the note on timing below.",
                calcErrors == 0 ? "Your ΔT calculations matched what was actually measured." : "Some of your ΔT calculations did not match the temperature you actually recorded."
            ]
            resultSkillMarks = [
                PracticalSkillMark(skill: "Reading the peak/trough temperature", scored: techniqueSkill, outOf: 10),
                PracticalSkillMark(skill: "Stirring technique", scored: stirSkill, outOf: 10),
                PracticalSkillMark(skill: "Calculation", scored: calcSkill, outOf: 10)
            ]
            if !techniqueGood { resultMistakes.append(PracticalMistake(title: technique, consequence: technique == "Recorded too early" ? "Stopping before the temperature has finished changing gives a ΔT that is too small." : "Waiting too long lets heat escape to the surroundings, so the recorded ΔT is smaller than the true value.")) }
            if !energeticsStirring { resultMistakes.append(PracticalMistake(title: "Did not stir continuously", consequence: "Without stirring, heat is not distributed evenly, so the thermometer reading lags behind the true temperature and the measured ΔT is unreliable.")) }
            if calcErrors > 0 { resultMistakes.append(PracticalMistake(title: "Calculated ΔT did not match the recorded temperatures", consequence: "ΔT = final temperature − initial temperature. Recheck the subtraction against your own readings.")) }
        case .separation:
            switch separationMixtureType {
            case .saltAndSand:
                let pourSkill = pouredTooFast ? 4 : 10
                let decisionSkill = evaporationChoice == "Until saturated, then cool" ? 10 : 3
                score = Int((Double(pourSkill + decisionSkill) / 20.0) * 100)
                feedback = [
                    pouredTooFast ? "Pouring too fast let solid escape into the filtrate." : "Filtration technique was good — the filtrate came through clear.",
                    evaporationChoice == "Until saturated, then cool" ? "Evaporating to saturation then cooling gives good, well-formed crystals." : "Evaporating fully to dryness spoils the crystals and can decompose the salt."
                ]
                resultSkillMarks = [
                    PracticalSkillMark(skill: "Filtration technique", scored: pourSkill, outOf: 10),
                    PracticalSkillMark(skill: "Crystallisation decision", scored: decisionSkill, outOf: 10)
                ]
                if pouredTooFast { resultMistakes.append(PracticalMistake(title: "Poured too quickly", consequence: "The mixture rose above the rim of the filter paper, letting some solid pass through into the filtrate — the residue is no longer pure.")) }
                if evaporationChoice != "Until saturated, then cool" { resultMistakes.append(PracticalMistake(title: "Evaporated to dryness", consequence: "Taking the solution fully to dryness causes spitting and gives small, poor-quality crystals instead of large well-formed ones.")) }
            case .immiscibleLiquids:
                let outcome = funnelOutcome ?? "Closed too late — the layers mixed together"
                let funnelSkill = outcome == "Closed at the interface — clean separation" ? 10 : 3
                score = Int((Double(funnelSkill + (distillateReady ? 10 : 0)) / 20.0) * 100)
                feedback = [
                    outcome,
                    "The denser liquid sits below and drains first through the tap; closing right at the interface keeps the two layers pure.",
                    "Distillation then separates the collected liquid further by boiling point."
                ]
                resultSkillMarks = [
                    PracticalSkillMark(skill: "Separating funnel timing", scored: funnelSkill, outOf: 10),
                    PracticalSkillMark(skill: "Distillation", scored: distillateReady ? 10 : 0, outOf: 10)
                ]
                if outcome != "Closed at the interface — clean separation" { resultMistakes.append(PracticalMistake(title: outcome, consequence: outcome.contains("early") ? "Closing too early leaves useful product behind in the funnel, reducing yield." : "Closing too late lets both layers mix together, contaminating the sample you meant to collect.")) }
            }
        case .solubility:
            let vals = readings.map(\.value); let mean = vals.reduce(0,+)/Double(max(vals.count, 1))
            let expected = readings.compactMap(\.derivedValue).reduce(0,+) / Double(max(readings.count, 1))
            let calcOK = abs(mean - expected) <= 1.0
            let saturationGood = solubilityPrematureDeclarations == 0 && solubilityExcessPortions <= 1
            let saturationSkill = saturationGood ? 10 : max(2, 10 - (solubilityPrematureDeclarations + max(0, solubilityExcessPortions - 1)) * 3)
            let filterSkill = solubilityFilteredExcess ? 10 : 0
            let calcSkill = calcOK ? 10 : 4
            score = Int((Double(saturationSkill + filterSkill + calcSkill) / 30.0) * 100)
            feedback = [
                "Mean recovered mass: \(String(format: "%.1f", mean)) g against an expected \(String(format: "%.1f", expected)) g for this cooling temperature.",
                saturationGood ? "You judged saturation well — stopping as soon as a trace of solid remained undissolved." : "Saturation judgement needs work — see the note below.",
                "Cooling further lowers solubility, so a lower cooling temperature recovers more crystals."
            ]
            resultSkillMarks = [
                PracticalSkillMark(skill: "Judging saturation", scored: saturationSkill, outOf: 10),
                PracticalSkillMark(skill: "Filtering off excess solid", scored: filterSkill, outOf: 10),
                PracticalSkillMark(skill: "Calculation", scored: calcSkill, outOf: 10)
            ]
            if solubilityPrematureDeclarations > 0 { resultMistakes.append(PracticalMistake(title: "Declared saturation before any solid remained undissolved", consequence: "Without seeing excess solid, the solution wasn't actually saturated, so the measured solubility is too low.")) }
            if solubilityExcessPortions > 1 { resultMistakes.append(PracticalMistake(title: "Added several portions past the point of saturation", consequence: "Adding much more than needed makes the mass added an overestimate of the true solubility.")) }
        }
        let outcome = LabRunResult(correct: score >= 80, score: score, feedback: feedback, examTip: examTip, skillMarks: resultSkillMarks, mistakes: resultMistakes)
        result = outcome
        recorder.record(experimentTitle: type.label, result: outcome)
    }

    func resetTask() {
        motion.reset()
        timerTask?.cancel(); timerTask = nil; startedAt = nil; elapsed = 0
        readings = []; result = nil; actionState = .idle; observedChanges = []; reactionProgress = 0; input = ""; choice = ""; electrolysisElectrolyte = "Copper sulfate solution"; electrolysisCathode = ""; electrolysisAnode = ""; electrolysisCircuitOn = false; electrolysisCathodeEquation = ""; electrolysisAnodeEquation = ""; electrolysisHasSwitchedOn = false; qualitativeReagent = ""; qualitativeObservation = ""; reagentBottleOpen = false; reagentDispensed = false; qualitativeStep = 0; solubilityCoolingTemp = 20.0; control = 0.5; energeticsMass = 100.0; energeticsInitialTemp = 20.0; energeticsFinalTemp = 25.8; energeticsStarted = false; energeticsElapsedRun = 0; energeticsRecordedTemp = nil; energeticsRecordOutcome = nil; buretteReading = 0; flaskColourProgress = 0; lastDropwise = false
        solubilityAddedMass = 0; solubilityLastPortionDissolved = true; solubilityDeclaredSaturated = false; solubilityFilteredExcess = false; solubilityPrematureDeclarations = 0; solubilityExcessPortions = 0
        filterPrepared = false; pourRate = 0.4; filtered = false; pouredTooFast = false; evaporationChoice = ""; crystalsObtained = false; funnelDraining = false; funnelDrainedAmount = 0; funnelOutcome = nil; distillateReady = false
        chromatographySolventFront = 0; chromatographyBaselineHeight = 1.0; chromatographyBaselineMistake = false; chromatographyStarted = false; chromatographyRemoved = false; chromatographyRemovalOutcome = nil
        titrationMode = .rough; titrationTapOpen = false; titrationInitialReading = 0; titrationRecords = []; titrationFlowStartedAt = nil; titrationLastOutcome = nil; titrationConcentrationInput = ""; titrationProceedAnyway = false
        rateConcentration = 0.5; rateTemperature = 0.5; rateSurfaceArea = 0.5; rateData = []; rateCatalystAdded = false; rateStudentReadings = []; rateTotalSubReadings = 0; rateMultipleVariablesChangedCount = 0; lastRateTrialSettings = nil
        energeticsStirring = true
        chromatographyBaselineMistakeCount = 0
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        target = (rng.nextDouble(23.8, 25.2) * 100).rounded() / 100
        qualitativeExpected = rng.randomElement(["chloride_obs", "hydrogen_obs", "carbonate_obs"])
        if type == .separation { separationMixtureType = rng.nextBoolean() ? .saltAndSand : .immiscibleLiquids }
        if type == .energetics { target = rng.nextBoolean() ? 5.8 : -4.8 }
        if type == .solubility { target = rng.nextDouble(6.0, 11.0) }
        if type == .chromatography { chromatographyTrueRf = (rng.nextDouble(0.35, 0.78) * 100).rounded() / 100 }
    }

    var qualitativeCorrect: Bool {
        switch qualitativeExpected {
        case "chloride_obs": return qualitativeReagent == "Acidified silver nitrate" && qualitativeObservation == "White precipitate"
        case "hydrogen_obs": return qualitativeReagent == "Lighted splint" && qualitativeObservation == "Squeaky pop"
        default: return qualitativeReagent == "Dilute acid + limewater" && qualitativeObservation == "Effervescence; limewater milky"
        }
    }
    var qualitativeTestLabel: String {
        switch qualitativeExpected {
        case "chloride_obs": return "Chloride ion test"
        case "hydrogen_obs": return "Hydrogen gas test"
        default: return "Carbonate ion test"
        }
    }
    var electrolysisCorrect: Bool {
        switch electrolysisElectrolyte {
        case "Copper sulfate solution": return electrolysisCathode == "Copper" && electrolysisAnode == "Oxygen"
        case "Sodium chloride solution": return electrolysisCathode == "Hydrogen" && electrolysisAnode == "Chlorine"
        case "Dilute sulfuric acid": return electrolysisCathode == "Hydrogen" && electrolysisAnode == "Oxygen"
        default: return false
        }
    }
    /// The "which ion actually gets discharged" reasoning the student should apply before choosing products.
    var electrolysisIonCompetitionNote: String {
        switch electrolysisElectrolyte {
        case "Copper sulfate solution": return "Cations present: Cu²⁺, H⁺ (trace). Cu²⁺ is discharged in preference to H⁺ because it is lower in the reactivity series. Anions present: SO₄²⁻, OH⁻ (trace). OH⁻ is discharged in preference to SO₄²⁻."
        case "Sodium chloride solution": return "This is concentrated brine. Cations present: Na⁺, H⁺. H⁺ is discharged in preference to Na⁺ (Na is very reactive), giving hydrogen at the cathode. Anions present: Cl⁻ (high concentration), OH⁻. With Cl⁻ concentrated, chlorine is discharged at the anode instead of oxygen."
        default: return "Cations present: H⁺ only (from the acid), so hydrogen forms at the cathode. Anions present: SO₄²⁻, OH⁻ (from water). OH⁻ is discharged in preference to SO₄²⁻, so oxygen forms at the anode."
        }
    }
    func toggleElectrolysisCircuit() {
        guard type == .electrolysis, result == nil else { return }
        electrolysisCircuitOn.toggle()
        if electrolysisCircuitOn {
            electrolysisHasSwitchedOn = true
            actionState = .reacting
            observedChanges.append("Circuit switched ON — bubbles begin forming at both electrodes")
        } else {
            actionState = .observing
            observedChanges.append("Circuit switched OFF")
        }
    }
    private func equationLooksRight(_ equation: String, mustContain tokens: [String]) -> Bool {
        let normalised = equation.lowercased().replacingOccurrences(of: " ", with: "")
        guard normalised.contains("e") else { return false } // must mention electrons
        return tokens.allSatisfy { normalised.contains($0.lowercased().replacingOccurrences(of: " ", with: "")) }
    }
    var electrolysisCathodeEquationCorrect: Bool {
        switch electrolysisElectrolyte {
        case "Copper sulfate solution": return equationLooksRight(electrolysisCathodeEquation, mustContain: ["cu"])
        default: return equationLooksRight(electrolysisCathodeEquation, mustContain: ["h2"])
        }
    }
    var electrolysisAnodeEquationCorrect: Bool {
        switch electrolysisElectrolyte {
        case "Sodium chloride solution": return equationLooksRight(electrolysisAnodeEquation, mustContain: ["cl2"])
        default: return equationLooksRight(electrolysisAnodeEquation, mustContain: ["o2"])
        }
    }
    var mixtureLabel: String { separationMixtureType.rawValue }
    var targetTemperatureChange: Double { target }
    var examTrap: String {
        switch type {
        case .titration: return "Do not use a rough titre as a concordant result. Near the endpoint, add titrant slowly while swirling."
        case .qualitativeAnalysis: return "Do not write an inference as an observation. Record what you actually see first."
        case .rateReaction: return "Changing more than one variable at once makes a fair comparison impossible."
        case .electrolysis: return "Anode = oxidation; cathode = reduction. Do not reverse the two."
        case .chromatography: return "The Rf denominator is the distance travelled by the solvent front, not the paper length."
        case .energetics: return "State the sign/direction of temperature change and connect it to the heat transfer conclusion."
        case .separation: return "State the physical property each step depends on (particle size for filtration, density for a separating funnel, boiling point for distillation)."
        case .solubility: return "Crystallisation is not simply evaporating to dryness; retain some solvent to avoid decomposing/contaminating the product."
        }
    }

    private var examTip: String { examTrap }
}

@MainActor
struct ChemistryPracticalLabView: View {
    let curriculum: Curriculum
    @StateObject private var model: ChemistryLabViewModel
    let onFinished: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(type: SimulationType, curriculum: Curriculum, repository: AttemptRepository, onFinished: (() -> Void)? = nil) {
        self.curriculum = curriculum; self.onFinished = onFinished
        _model = StateObject(wrappedValue: ChemistryLabViewModel(type: type, curriculum: curriculum, repository: repository))
    }

    var body: some View {
        ChemistryLabScaffold(title: model.type.label, instructionText: model.instruction, readings: model.readings, stages: model.type.practicalStages, stageIndex: model.currentStage, result: model.result, apparatus: { apparatus }, controls: { controls })
            .onChange(of: model.result != nil) { _, finished in if finished { onFinished?() } }
    }

    private var dragEnabled: Bool {
        switch model.type {
        case .titration, .electrolysis: return true
        default: return false
        }
    }

    private var apparatus: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
                Canvas { context, size in
                    LabScenes.render(&context, size: size, model: model, date: timeline.date)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Animated \(model.type.label) apparatus")
            .contentShape(Rectangle())
            .highPriorityGesture(DragGesture(minimumDistance: 0).onChanged { value in
                switch model.type {
                case .titration: model.motion.kickSwirl(0.05)
                case .electrolysis: model.control = min(max(value.location.x / max(geo.size.width, 1), 0), 1)
                default: break
                }
            }, including: dragEnabled ? GestureMask.all : GestureMask.none)
        }
        .onAppear { model.motion.reduceMotion = reduceMotion }
        .onChange(of: reduceMotion) { _, newValue in model.motion.reduceMotion = newValue }
    }

    @ViewBuilder private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Practical procedure").font(.headline)
                Text(model.instruction).font(.caption)
            }.padding(10).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10))
            Label("Action state: \(model.actionState.rawValue.capitalized)", systemImage: "waveform.path.ecg").font(.caption.weight(.semibold))
            Text(model.actionHint).font(.caption).foregroundStyle(.secondary)
            HStack {
                Button(model.actionState == .idle ? "Prepare apparatus" : "Advance action") { model.advanceAction() }.buttonStyle(.borderedProminent).disabled(model.actionState == .analysed || model.result != nil)
                Button("Perform lab action") { model.performInteractiveAction() }.buttonStyle(.bordered).disabled(model.result != nil)
                Spacer()
                if !model.observedChanges.isEmpty { Text("\(model.observedChanges.last!)").font(.caption2).foregroundStyle(.green) }
            }
        }.padding(10).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        TrialProgressView(completed: model.readings.count, target: model.targetTrials)
        switch model.type {
        case .titration:
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("25.0 cm³ of standard HCl + phenolphthalein is in the flask. NaOH is in the burette. Do a rough titration first, then repeat accurately until two titres agree within 0.10 cm³.").font(.caption)
                }
                Picker("Attempt type", selection: $model.titrationMode) { ForEach(TitrationMode.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).disabled(model.titrationTapOpen)

                HStack { Text("Initial reading"); Spacer(); Text(String(format: "%.2f cm³", model.titrationInitialReading)).monospacedDigit() }.font(.caption)
                HStack { Text("Current reading"); Spacer(); Text(String(format: "%.2f cm³", model.buretteReading)).font(.headline.monospacedDigit()).contentTransition(.numericText()).animation(.smooth(duration: 0.25), value: model.buretteReading) }
                ProgressView(value: model.flaskColourProgress).tint(.pink).animation(.smooth(duration: 0.5), value: model.flaskColourProgress)
                Text("Flask: \(model.titrationColour.rawValue)").font(.caption.weight(.semibold)).foregroundStyle(model.titrationColour == .overshot ? Color.red : model.titrationColour == .permanentPink ? Color.green : Color.secondary)

                if !model.titrationTapOpen && model.buretteReading == model.titrationInitialReading {
                    Button("Start \(model.titrationMode.rawValue.lowercased()) titration from here") { model.beginTitrationAttempt(mode: model.titrationMode) }
                        .buttonStyle(.bordered)
                }
                HStack {
                    Button(model.titrationTapOpen ? "STOP" : "OPEN TAP") { model.titrationTapOpen ? model.stopTap() : model.openTap() }
                        .buttonStyle(.borderedProminent).tint(model.titrationTapOpen ? .red : .accentColor)
                        .disabled(model.titrationLastOutcome != nil)
                    Button("This is the endpoint") { _ = model.confirmEndpoint() }
                        .buttonStyle(.bordered).disabled(model.buretteReading == model.titrationInitialReading || model.titrationLastOutcome != nil)
                    Button(model.titrationLastOutcome == nil ? "Refill burette" : "Continue to next attempt") { model.refillBurette() }
                        .buttonStyle(.bordered)
                        .disabled(model.titrationTapOpen)
                }
                if let outcome = model.titrationLastOutcome {
                    Text(outcome).font(.caption.weight(.semibold)).foregroundStyle(outcome == "Endpoint detected" ? .green : .orange)
                }

                if !model.titrationRecords.isEmpty {
                    Divider()
                    Text("Attempts so far").font(.caption.bold())
                    ForEach(model.titrationRecords) { r in
                        HStack {
                            Text("#\(r.attemptNumber) · \(r.mode.rawValue)").font(.caption2)
                            Spacer()
                            Text(String(format: "%.2f cm³", r.titre)).font(.caption2.monospacedDigit())
                            Text(r.outcome).font(.caption2).foregroundStyle(r.outcome == "Endpoint detected" ? .green : .orange)
                        }
                    }
                    if model.titrationIsConcordant {
                        Text("✓ Concordant titres achieved.").font(.caption).foregroundStyle(.green)
                    } else if model.titrationProceedAnyway {
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                            Text("Proceeding without concordant titres — repeating would give a more reliable mean, but you can calculate from these two anyway.")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    } else {
                        Text("Repeat the accurate titration until two titres are within 0.10 cm³.").font(.caption).foregroundStyle(.secondary)
                        if model.titrationCanProceedWithoutConcordance {
                            Button("Proceed without concordant titres") { model.proceedWithoutConcordantTitres() }
                                .buttonStyle(.bordered).tint(.orange)
                        }
                    }
                }

                if model.titrationIsConcordant || model.titrationProceedAnyway {
                    Divider()
                    Text("Calculate the concentration of NaOH (mol/dm³)").font(.caption.bold())
                    Text("moles HCl = moles NaOH at the end-point; 25.0 cm³ of \(String(format: "%.3f", model.titrationHCl_M)) mol/dm³ HCl was used.").font(.caption2).foregroundStyle(.secondary)
                    TextField("Concentration (mol/dm³)", text: $model.titrationConcentrationInput).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    Button("Finish titration & get feedback") { model.finalizeTitration() }.buttonStyle(.borderedProminent).disabled(model.titrationConcentrationInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        case .qualitativeAnalysis:
            VStack(alignment: .leading, spacing: 8) { Text("Run the test: choose a reagent, then record what you observe.").font(.headline); HStack { Button("Silver nitrate") { model.openReagentBottle("Acidified silver nitrate") }.buttonStyle(.bordered); Button("Splint") { model.openReagentBottle("Lighted splint") }.buttonStyle(.bordered); Button("Acid + limewater") { model.openReagentBottle("Dilute acid + limewater") }.buttonStyle(.bordered) }; if !model.qualitativeReagent.isEmpty { Text("Bottle: \(model.qualitativeReagent) · \(model.reagentBottleOpen ? "open" : "closed")").font(.caption); Button(model.reagentDispensed ? "Reagent dispensed" : "Dispense reagent") { model.dispenseSelectedReagent() }.buttonStyle(.borderedProminent).disabled(!model.reagentBottleOpen || model.reagentDispensed) }; Picker("Observation", selection: $model.qualitativeObservation) { Text("Select observation…").tag(""); Text("White precipitate").tag("White precipitate"); Text("Squeaky pop").tag("Squeaky pop"); Text("Effervescence; limewater milky").tag("Effervescence; limewater milky"); Text("No visible change").tag("No visible change") }.pickerStyle(.menu); Text("Evidence first; inference second. The hidden sample is revealed after recording.").font(.caption).foregroundStyle(.secondary); Button("Record observation") { model.record() }.buttonStyle(.borderedProminent).disabled(!model.canRecord) }
        case .rateReaction:
            VStack(alignment: .leading, spacing: 10) {
                Text("Set your variables, start the reaction, then read the gas syringe yourself at intervals you choose.").font(.caption)
                Text("Control variables").font(.subheadline.bold()).disabled(model.startedAt != nil)
                Slider(value: $model.rateConcentration, in: 0...1) { Text("Concentration") }.disabled(model.startedAt != nil)
                Text("Concentration: \(Int(model.rateConcentration * 100))%").font(.caption)
                Slider(value: $model.rateTemperature, in: 0...1).disabled(model.startedAt != nil)
                Text("Temperature: \(Int(20 + model.rateTemperature * 60)) °C").font(.caption)
                Slider(value: $model.rateSurfaceArea, in: 0...1).disabled(model.startedAt != nil)
                Text("Surface area: \(Int(20 + model.rateSurfaceArea * 80))%").font(.caption)
                Toggle("Catalyst added", isOn: $model.rateCatalystAdded).disabled(model.startedAt != nil)
                Text("Change only ONE of these between trials for a fair test.").font(.caption2).foregroundStyle(.secondary)

                Divider()
                if model.startedAt == nil {
                    Button("Start reaction & timer") { model.startRate() }.buttonStyle(.borderedProminent)
                } else {
                    HStack {
                        Text("Elapsed: \(String(format: "%.1f", model.elapsed)) s").font(.headline.monospacedDigit())
                        Spacer()
                        Text("Gas syringe: \(String(format: "%.1f", model.gasVolume)) cm³").font(.headline.monospacedDigit())
                    }
                    Button("Read gas syringe now") { model.recordGasReading() }.buttonStyle(.bordered)
                    Button("Stop experiment") { model.stopRateExperiment() }.buttonStyle(.borderedProminent).tint(.red).disabled(!model.rateCanStop)
                    if !model.rateCanStop { Text("Take at least 3 readings before stopping.").font(.caption2).foregroundStyle(.secondary) }
                }

                if !model.rateStudentReadings.isEmpty {
                    Divider()
                    Text("Time / s        Gas volume / cm³").font(.caption.bold())
                    ForEach(model.rateStudentReadings) { r in
                        HStack {
                            Text(String(format: "%.1f", r.time)).font(.caption.monospacedDigit())
                            Spacer()
                            Text(String(format: "%.1f", r.volume)).font(.caption.monospacedDigit())
                        }
                    }
                    if let initial = model.rateInitialRate, let avg = model.rateAverageRate {
                        Divider()
                        Text("Initial rate (first interval): \(String(format: "%.2f", initial)) cm³/s").font(.caption)
                        Text("Average rate (whole run): \(String(format: "%.2f", avg)) cm³/s").font(.caption)
                    }
                }
                if !model.readings.isEmpty {
                    Divider()
                    Text("Completed trials").font(.caption.bold())
                    ForEach(model.readings) { r in
                        HStack { Text(r.label).font(.caption2); Spacer(); Text(String(format: "%.2f %@", r.value, r.unit)).font(.caption2.monospacedDigit()) }
                    }
                }
            }
        case .electrolysis:
            VStack(alignment: .leading, spacing: 10) {
                Text("Prepare the electrolyte, insert the electrodes, then switch the circuit on and watch what forms at each electrode.").font(.caption)
                Picker("Electrolyte", selection: $model.electrolysisElectrolyte) {
                    Text("Copper sulfate solution").tag("Copper sulfate solution")
                    Text("Sodium chloride solution").tag("Sodium chloride solution")
                    Text("Dilute sulfuric acid").tag("Dilute sulfuric acid")
                }.pickerStyle(.menu).disabled(model.electrolysisCircuitOn)
                Text("Current: \(String(format: "%.1f", 0.5 + model.control * 2.5)) A").font(.caption).foregroundStyle(.secondary)
                Button(model.electrolysisCircuitOn ? "SWITCH OFF" : "SWITCH ON") { model.toggleElectrolysisCircuit() }
                    .buttonStyle(.borderedProminent).tint(model.electrolysisCircuitOn ? .red : .accentColor)
                if model.electrolysisHasSwitchedOn {
                    Text(model.electrolysisCircuitOn ? "Bubbles are forming at both electrodes." : "Circuit is off. Bubble/deposit formation has stopped.").font(.caption).foregroundStyle(.secondary)
                    Divider()
                    Text("Which ion is actually discharged?").font(.caption.bold())
                    Text(model.electrolysisIonCompetitionNote).font(.caption2).foregroundStyle(.secondary)
                    Picker("Cathode product", selection: $model.electrolysisCathode) { Text("Select…").tag(""); Text("Copper").tag("Copper"); Text("Hydrogen").tag("Hydrogen") }.pickerStyle(.segmented)
                    TextField("Cathode half-equation, e.g. Cu²⁺ + 2e⁻ → Cu", text: $model.electrolysisCathodeEquation).textFieldStyle(.roundedBorder).font(.caption)
                    Picker("Anode product", selection: $model.electrolysisAnode) { Text("Select…").tag(""); Text("Oxygen").tag("Oxygen"); Text("Chlorine").tag("Chlorine") }.pickerStyle(.segmented)
                    TextField("Anode half-equation, e.g. 4OH⁻ - 4e⁻ → 2H₂O + O₂", text: $model.electrolysisAnodeEquation).textFieldStyle(.roundedBorder).font(.caption)
                    Button("Conclude & get feedback") { model.record() }.buttonStyle(.borderedProminent).disabled(!model.canRecord)
                } else {
                    Text("Switch the circuit on first to observe the electrodes.").font(.caption2).foregroundStyle(.secondary)
                }
            }
        case .chromatography:
            VStack(alignment: .leading, spacing: 10) {
                Text("Draw the baseline above the solvent surface, then place the paper in the solvent and watch it rise.").font(.caption)
                if !model.chromatographyStarted && !model.chromatographyRemoved {
                    HStack { Text("Baseline height above solvent"); Slider(value: $model.chromatographyBaselineHeight, in: 0.1...2.0, step: 0.1); Text("\(String(format: "%.1f", model.chromatographyBaselineHeight)) cm").monospacedDigit() }
                    Button("Draw baseline & place paper in solvent") { model.placeBaselineAndStart() }.buttonStyle(.borderedProminent)
                    if model.chromatographyBaselineMistake { Text("The baseline touched the solvent — raise it above the solvent surface and try again.").font(.caption).foregroundStyle(.orange) }
                } else if model.chromatographyStarted {
                    HStack {
                        Text("Solvent front").font(.caption)
                        Spacer()
                        Text("\(String(format: "%.1f", model.chromatographySolventFront)) cm above baseline").font(.headline.monospacedDigit()).contentTransition(.numericText()).animation(.smooth(duration: 0.3), value: model.chromatographySolventFront)
                    }
                    ProgressView(value: model.chromatographySolventFront, total: model.chromatographyMaxTravel).tint(.purple)
                    Button("Remove paper now") { model.removeChromatographyPaper() }.buttonStyle(.bordered)
                    Text("Remove it before the solvent reaches the top of the paper.").font(.caption2).foregroundStyle(.secondary)
                }
                if model.chromatographyRemoved {
                    if let outcome = model.chromatographyRemovalOutcome {
                        Text(outcome).font(.caption.weight(.semibold)).foregroundStyle(outcome == "Removed at a good time" ? .green : .orange)
                    }
                    Text("Solvent front travelled: \(String(format: "%.1f", model.chromatographySolventFront)) cm from the baseline.").font(.caption)
                    TextField("Spot distance from baseline (cm)", text: $model.input).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    if let spot = Double(model.input.replacingOccurrences(of: ",", with: ".")), model.chromatographySolventFront > 0 {
                        Text("Your Rf: \(String(format: "%.2f", spot / model.chromatographySolventFront))").font(.headline)
                    }
                    Button("Record chromatogram") { model.record() }.buttonStyle(.borderedProminent).disabled(!model.canRecord)
                }
            }
        case .energetics:
            VStack(alignment: .leading, spacing: 10) {
                Text("Initial temperature (measured before mixing): \(String(format: "%.1f", model.energeticsInitialTemp))°C").font(.caption)
                Toggle("Stirring continuously", isOn: $model.energeticsStirring).disabled(model.energeticsStarted)
                Divider()
                if !model.energeticsStarted && model.energeticsRecordedTemp == nil {
                    Button("Mix reactants & start") { model.startEnergeticsReaction() }.buttonStyle(.borderedProminent)
                } else if model.energeticsStarted {
                    HStack {
                        Text("t = \(String(format: "%.0f", model.energeticsElapsedRun)) s").font(.caption)
                        Spacer()
                        Text("\(String(format: "%.1f", model.energeticsFinalTemp))°C").font(.title2.monospacedDigit()).contentTransition(.numericText()).animation(.smooth(duration: 0.3), value: model.energeticsFinalTemp)
                    }
                    Button("This looks like the peak — record it") { model.recordEnergeticsTemperature() }.buttonStyle(.bordered)
                    Text("Keep watching — if you wait too long after the peak, heat will start escaping to the surroundings.").font(.caption2).foregroundStyle(.secondary)
                }
                if let recorded = model.energeticsRecordedTemp {
                    Text("Recorded temperature: \(String(format: "%.1f", recorded))°C").font(.caption)
                    if let outcome = model.energeticsRecordOutcome {
                        Text(outcome).font(.caption.weight(.semibold)).foregroundStyle(outcome.contains("well") ? .green : .orange)
                    }
                    Text("Measured ΔT: \(String(format: "%+.1f", recorded - model.energeticsInitialTemp)) °C").font(.headline)
                    TextField("Enter your calculated ΔT", text: $model.input).keyboardType(.numbersAndPunctuation).textFieldStyle(.roundedBorder)
                    Button("Record temperature change") { model.record() }.buttonStyle(.borderedProminent).disabled(!model.canRecord)
                }
            }
        case .separation:
            VStack(alignment: .leading, spacing: 10) {
                Text("Mixture: \(model.mixtureLabel)").font(.subheadline.bold())
                switch model.separationMixtureType {
                case .saltAndSand:
                    if !model.filterPrepared {
                        Text("Fold the filter paper into a cone, wet it, and seat it in the funnel.").font(.caption)
                        Button("Fold & wet filter paper, place in funnel") { model.prepareFilter() }.buttonStyle(.borderedProminent)
                    } else if !model.filtered {
                        HStack { Text("Pour rate"); Slider(value: $model.pourRate, in: 0...1); Text(model.pourRate > 0.7 ? "Fast" : "Steady").font(.caption) }
                        Button("Pour mixture through the filter") { model.pourMixtureThroughFilter() }.buttonStyle(.borderedProminent)
                    } else {
                        Text(model.pouredTooFast ? "Some solid escaped into the filtrate — it overflowed the paper." : "Residue (sand) is in the filter paper; filtrate (salt solution) is in the beaker.").font(.caption).foregroundStyle(model.pouredTooFast ? Color.orange : Color.secondary)
                        if model.evaporationChoice.isEmpty {
                            Text("How do you recover the salt from the filtrate?").font(.caption.bold())
                            Button("Evaporate until saturated, then cool") { model.chooseEvaporation("Until saturated, then cool") }.buttonStyle(.borderedProminent)
                            Button("Evaporate to complete dryness") { model.chooseEvaporation("To dryness") }.buttonStyle(.bordered)
                        } else {
                            Text(model.evaporationChoice == "Until saturated, then cool" ? "Good crystals formed on cooling." : "Evaporating to dryness spoiled the crystals.").font(.caption.weight(.semibold)).foregroundStyle(model.evaporationChoice == "Until saturated, then cool" ? .green : .orange)
                            Button("Finish & get feedback") { model.record() }.buttonStyle(.borderedProminent).disabled(!model.canRecord)
                        }
                    }
                case .immiscibleLiquids:
                    if model.funnelOutcome == nil {
                        Text("The denser liquid settles at the bottom. Open the tap and close it right at the interface between the two layers.").font(.caption)
                        ProgressView(value: min(model.funnelDrainedAmount, 1.4), total: 1.4).tint(.blue)
                        HStack {
                            Button(model.funnelDraining ? "CLOSE TAP" : "OPEN TAP") { model.funnelDraining ? model.closeFunnelTap() : model.openFunnelTap() }
                                .buttonStyle(.borderedProminent).tint(model.funnelDraining ? .red : .accentColor)
                        }
                    } else {
                        Text(model.funnelOutcome ?? "").font(.caption.weight(.semibold)).foregroundStyle(model.funnelOutcome == "Closed at the interface — clean separation" ? .green : .orange)
                        if !model.distillateReady {
                            Button("Heat & distil the collected liquid") { model.distillCollectedLiquid() }.buttonStyle(.borderedProminent)
                        } else {
                            Text("Distillate collected once the temperature stayed constant at the boiling point.").font(.caption).foregroundStyle(.secondary)
                            Button("Finish & get feedback") { model.record() }.buttonStyle(.borderedProminent).disabled(!model.canRecord)
                        }
                    }
                }
            }
        case .solubility:
            VStack(alignment: .leading, spacing: 10) {
                Text("Add solid in small portions and stir. Watch what actually happens after each portion.").font(.caption)
                Text("Added so far: \(String(format: "%.1f", model.solubilityAddedMass)) g").font(.headline.monospacedDigit())
                if !model.solubilityDeclaredSaturated {
                    Button("Add a portion & stir") { model.addSolidPortion() }.buttonStyle(.borderedProminent)
                    if model.solubilityAddedMass > 0 {
                        Text(model.solubilityLastPortionDissolved ? "Dissolved completely." : "A little solid remains undissolved even after stirring.").font(.caption).foregroundStyle(model.solubilityLastPortionDissolved ? Color.secondary : Color.orange)
                    }
                    Button("This looks saturated — stop here") { model.declareSaturated() }.buttonStyle(.bordered).disabled(model.solubilityAddedMass == 0)
                } else {
                    Text("Saturated at \(String(format: "%.1f", model.solubilityAddedMass)) g.").font(.caption.weight(.semibold)).foregroundStyle(.green)
                    if !model.solubilityFilteredExcess {
                        Button("Filter off the excess solid") { model.filterExcessSolid() }.buttonStyle(.borderedProminent)
                    } else {
                        Divider()
                        HStack { Text("Cool to"); Slider(value: $model.solubilityCoolingTemp, in: 5...90, step: 1); Text("\(Int(model.solubilityCoolingTemp)) °C").monospacedDigit() }
                        Text("Cooling further lowers solubility, so more crystals come out of solution.").font(.caption2).foregroundStyle(.secondary)
                        TextField("Crystals recovered (g)", text: $model.input).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                        Button("Record crystallisation result") { model.record() }.buttonStyle(.borderedProminent).disabled(!model.canRecord)
                    }
                }
            }
        }
        if model.result != nil { Button("New practical task") { model.resetTask() }.buttonStyle(.bordered).frame(maxWidth: .infinity) }
    }
}
