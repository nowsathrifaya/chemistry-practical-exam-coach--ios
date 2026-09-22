
import Foundation

struct GraphDatasetGenerator {
    /// Extends a straight reference line from `start` at the given `slope`
    /// only until it reaches `targetY` (the observed extreme of the plotted
    /// data) or `maxX`, whichever comes first. Without this, the initial
    /// tangent to an exponential curve (gas volume, concentration,
    /// temperature) shoots far past the plotted y-range almost immediately —
    /// mathematically correct but rendered as a line that vanishes off the
    /// top of the chart. Stopping at the data's own ceiling/floor keeps the
    /// reference visually comparable to the triangle a student would draw.
    private func referenceEnd(from start: GraphPoint, slope: Double, maxX: Double, targetY: Double) -> GraphPoint {
        guard slope != 0 else { return GraphPoint(x: maxX, y: start.y) }
        let xAtTarget = start.x + (targetY - start.y) / slope
        let x = min(maxX, max(start.x, xAtTarget))
        return GraphPoint(x: x, y: start.y + slope * (x - start.x))
    }

    func generate(type: GraphCoachType, seed: Int, curriculum: Curriculum) -> GraphDataset {
        var rng = SeededRandomNumberGenerator(seed: seed)
        var pts: [GraphPoint] = []
        let computed: Double
        let refStart: GraphPoint
        let refEnd: GraphPoint

        switch type {
        case .titrationCurve:
            // Equivalence point (the steep pH jump) is randomised within a
            // sensible window each dataset so the exercise can't just be
            // memorised — the student has to read the curve, not recall a
            // fixed volume. The buffer-region slope before it is illustrative
            // only; see GraphTaskKind's doc comment for why this graph is
            // marked as an end-point read, not a gradient.
            let equivalenceVolume = 12.0 + Double(rng.nextInt(0, 7)) // 12...18 cm3 (nextInt's upper bound is exclusive)
            let bufferSlope = 0.08
            for i in 0..<10 {
                let x = Double(i * 3)
                let y: Double
                if x < equivalenceVolume - 3 {
                    y = 2.8 + x * bufferSlope
                } else if x < equivalenceVolume + 3 {
                    let t = (x - (equivalenceVolume - 3)) / 6.0
                    y = 3.6 + t * 5.6
                } else {
                    y = 9.2 + (x - (equivalenceVolume + 3)) * 0.18
                }
                pts.append(GraphPoint(x: x, y: y + Double(rng.nextInt(-3, 3)) / 10))
            }
            computed = equivalenceVolume
            // Reference "line" here is a vertical marker at the true
            // equivalence point, drawn top-to-bottom of the plotted y-range.
            let ys = pts.map(\.y)
            refStart = GraphPoint(x: equivalenceVolume, y: ys.min() ?? 0)
            refEnd = GraphPoint(x: equivalenceVolume, y: ys.max() ?? 14)

        case .rateGasVolume:
            // Volume vs time: V = Vmax(1 - e^-kt), so the initial rate (the tangent
            // at t = 0, which is what students are asked to read off) is Vmax * k.
            let vMax = 65.0, k = 0.08
            let maxX = 70.0
            for i in 0..<8 {
                let x = Double(i * 10)
                let y = vMax * (1 - exp(-k * x))
                pts.append(GraphPoint(x: x, y: y + Double(rng.nextInt(-5, 5)) / 10))
            }
            computed = vMax * k
            refStart = GraphPoint(x: 0, y: 0)
            refEnd = referenceEnd(from: refStart, slope: computed, maxX: maxX, targetY: pts.map(\.y).max() ?? vMax)

        case .rateConcentration:
            // Concentration vs time: C = C0 * e^-kt; initial rate = -C0 * k.
            let c0 = 0.50, k = 0.06
            let maxX = 70.0
            for i in 0..<8 {
                let x = Double(i * 10)
                let y = c0 * exp(-k * x)
                pts.append(GraphPoint(x: x, y: y + Double(rng.nextInt(-3, 3)) / 100))
            }
            computed = -c0 * k
            refStart = GraphPoint(x: 0, y: c0)
            refEnd = referenceEnd(from: refStart, slope: computed, maxX: maxX, targetY: pts.map(\.y).min() ?? 0)

        case .temperatureChange:
            // Temperature vs time: T = T0 + ΔT(1 - e^-kt); initial rate = ΔT * k.
            // (Previously this used the loop index instead of the actual elapsed
            // time `x` in the exponent, and the expected gradient was a hard-coded
            // 0.2 that didn't match the data's real initial slope — so a student
            // who correctly read the gradient off the plotted points was marked
            // wrong. Both are fixed by computing everything from the same x.)
            let t0 = 24.0, deltaT = 8.0, k = 0.002
            let maxX = 210.0
            for i in 0..<8 {
                let x = Double(i * 30)
                let y = t0 + deltaT * (1 - exp(-k * x))
                pts.append(GraphPoint(x: x, y: y + Double(rng.nextInt(-3, 3)) / 10))
            }
            computed = deltaT * k
            refStart = GraphPoint(x: 0, y: t0)
            refEnd = referenceEnd(from: refStart, slope: computed, maxX: maxX, targetY: pts.map(\.y).max() ?? (t0 + deltaT))

        case .chromatography:
            let slope = 0.62
            let maxX = 6.0
            for i in 0..<6 {
                let x = Double(i + 1)
                pts.append(GraphPoint(x: x, y: slope * x + Double(rng.nextInt(-2, 2)) / 10))
            }
            computed = slope
            refStart = GraphPoint(x: 0, y: 0)
            refEnd = GraphPoint(x: maxX, y: slope * maxX)
        }

        return GraphDataset(type: type, seed: seed, points: pts, expectedGradient: computed, referenceStart: refStart, referenceEnd: refEnd)
    }
}

struct GraphGradientMarker {
    /// Marks a `.gradient`-kind dataset (everything except titration).
    func mark(dataset: GraphDataset, studentGradient: Double?, pointsTooClose: Bool = false, pointsExtrapolated: Bool = false, axisChoiceCorrect: Bool = true, curriculum: Curriculum) -> GraphGradientResult {
        guard let s = studentGradient else {
            return GraphGradientResult(correct: false, score: 0, expectedGradient: dataset.expectedGradient, studentGradient: nil, feedback: ["Enter a numerical value."], explanation: "Use two well-separated points on the best-fit line where a gradient is appropriate.")
        }
        let tol = max(abs(dataset.expectedGradient) * 0.12, 0.02)
        let valueOK = abs(s - dataset.expectedGradient) <= tol
        let explanation = "Use a large triangle and points on the best-fit line. Quote the gradient with correct units."

        let axisSkill = axisChoiceCorrect ? 10 : 3
        let techniqueSkill = (pointsTooClose || pointsExtrapolated) ? 4 : 10
        let calcSkill = valueOK ? 10 : 3
        let score = Int((Double(axisSkill + techniqueSkill + calcSkill) / 30.0) * 100)

        var feedback: [String] = [valueOK ? "Gradient accepted within the coaching tolerance." : "Outside the coaching tolerance — check your axes, scale and two points on the best-fit line."]
        if pointsTooClose { feedback.append("Your two points were close together — a small triangle magnifies reading error.") }
        if pointsExtrapolated { feedback.append("One of your points fell outside the plotted data range.") }
        if !axisChoiceCorrect { feedback.append("The independent variable (the one you controlled) normally goes on the x-axis.") }

        var mistakes: [PracticalMistake] = []
        if pointsTooClose { mistakes.append(PracticalMistake(title: "Gradient triangle too small", consequence: "Points close together make the gradient very sensitive to small reading errors — use a large triangle spanning most of the line.")) }
        if pointsExtrapolated { mistakes.append(PracticalMistake(title: "Extrapolated beyond the data", consequence: "Estimating from a point beyond the range of measured data is unreliable, since the trend may not continue in the same way.")) }
        if !axisChoiceCorrect { mistakes.append(PracticalMistake(title: "Axes reversed", consequence: "Convention places the independent variable you controlled on the x-axis and the measured response on the y-axis.")) }

        return GraphGradientResult(
            correct: valueOK && !pointsTooClose && !pointsExtrapolated && axisChoiceCorrect,
            score: score, expectedGradient: dataset.expectedGradient, studentGradient: s, feedback: feedback, explanation: explanation,
            skillMarks: [
                PracticalSkillMark(skill: "Axis choice", scored: axisSkill, outOf: 10),
                PracticalSkillMark(skill: "Point selection technique", scored: techniqueSkill, outOf: 10),
                PracticalSkillMark(skill: "Gradient calculation", scored: calcSkill, outOf: 10)
            ],
            mistakes: mistakes
        )
    }

    /// Marks the titration `.equivalencePoint` task: the student taps a
    /// single volume on the curve, rather than forming a gradient triangle.
    func markEquivalencePoint(dataset: GraphDataset, studentVolume: Double?, pointExtrapolated: Bool = false, axisChoiceCorrect: Bool = true, curriculum: Curriculum) -> GraphGradientResult {
        guard let s = studentVolume else {
            return GraphGradientResult(correct: false, score: 0, expectedGradient: dataset.expectedGradient, studentGradient: nil, feedback: ["Tap the curve at the equivalence point, or enter a volume."], explanation: "The equivalence point sits in the middle of the steepest part of the pH jump.")
        }
        let tol = 1.5 // cm3 — generous enough to allow reading precision, tight enough to require locating the jump
        let valueOK = abs(s - dataset.expectedGradient) <= tol
        let explanation = "The equivalence point is the volume at the midpoint of the steepest section of the curve, not the highest point plotted."

        let axisSkill = axisChoiceCorrect ? 10 : 3
        let techniqueSkill = pointExtrapolated ? 4 : 10
        let calcSkill = valueOK ? 10 : 3
        let score = Int((Double(axisSkill + techniqueSkill + calcSkill) / 30.0) * 100)

        var feedback: [String] = [valueOK ? "End-point accepted within the coaching tolerance." : "Outside the coaching tolerance — look for the middle of the steepest section of the jump, not the top of the curve."]
        if pointExtrapolated { feedback.append("Your estimate fell outside the plotted volume range.") }
        if !axisChoiceCorrect { feedback.append("Volume added is the variable you controlled, so it belongs on the x-axis.") }

        var mistakes: [PracticalMistake] = []
        if pointExtrapolated { mistakes.append(PracticalMistake(title: "Estimate outside plotted range", consequence: "The equivalence point must lie within the volumes actually measured.")) }
        if !axisChoiceCorrect { mistakes.append(PracticalMistake(title: "Axes reversed", consequence: "Convention places the independent variable you controlled on the x-axis and the measured response on the y-axis.")) }

        return GraphGradientResult(
            correct: valueOK && !pointExtrapolated && axisChoiceCorrect,
            score: score, expectedGradient: dataset.expectedGradient, studentGradient: s, feedback: feedback, explanation: explanation,
            skillMarks: [
                PracticalSkillMark(skill: "Axis choice", scored: axisSkill, outOf: 10),
                PracticalSkillMark(skill: "Reading precision", scored: techniqueSkill, outOf: 10),
                PracticalSkillMark(skill: "End-point identification", scored: calcSkill, outOf: 10)
            ],
            mistakes: mistakes
        )
    }
}
