
import Foundation

struct GraphDatasetGenerator {
    func generate(type: GraphCoachType, seed: Int, curriculum: Curriculum) -> GraphDataset {
        var rng = SeededRandomNumberGenerator(seed: seed)
        var pts: [GraphPoint] = []
        let computed: Double

        switch type {
        case .titrationCurve:
            // The buffer-region slope before the equivalence point. As noted in
            // GraphGradientMarker's explanation text, a titration curve's gradient
            // isn't a meaningful physical constant the way it is for the other
            // graph types, so this is illustrative rather than something students
            // are drilled to reproduce precisely.
            let bufferSlope = 0.08
            for i in 0..<9 {
                let x = Double(i * 3)
                let y = x < 12 ? 2.8 + x * bufferSlope : x < 18 ? 3.8 + (x - 12) * 0.8 : 8.6 + (x - 18) * 0.18
                pts.append(GraphPoint(x: x, y: y + Double(rng.nextInt(-3, 3)) / 10))
            }
            computed = bufferSlope

        case .rateGasVolume:
            // Volume vs time: V = Vmax(1 - e^-kt), so the initial rate (the tangent
            // at t = 0, which is what students are asked to read off) is Vmax * k.
            let vMax = 65.0, k = 0.08
            for i in 0..<8 {
                let x = Double(i * 10)
                let y = vMax * (1 - exp(-k * x))
                pts.append(GraphPoint(x: x, y: y + Double(rng.nextInt(-5, 5)) / 10))
            }
            computed = vMax * k

        case .rateConcentration:
            // Concentration vs time: C = C0 * e^-kt; initial rate = -C0 * k.
            let c0 = 0.50, k = 0.06
            for i in 0..<8 {
                let x = Double(i * 10)
                let y = c0 * exp(-k * x)
                pts.append(GraphPoint(x: x, y: y + Double(rng.nextInt(-3, 3)) / 100))
            }
            computed = -c0 * k

        case .temperatureChange:
            // Temperature vs time: T = T0 + ΔT(1 - e^-kt); initial rate = ΔT * k.
            // (Previously this used the loop index instead of the actual elapsed
            // time `x` in the exponent, and the expected gradient was a hard-coded
            // 0.2 that didn't match the data's real initial slope — so a student
            // who correctly read the gradient off the plotted points was marked
            // wrong. Both are fixed by computing everything from the same x.)
            let t0 = 24.0, deltaT = 8.0, k = 0.002
            for i in 0..<8 {
                let x = Double(i * 30)
                let y = t0 + deltaT * (1 - exp(-k * x))
                pts.append(GraphPoint(x: x, y: y + Double(rng.nextInt(-3, 3)) / 10))
            }
            computed = deltaT * k

        case .chromatography:
            let slope = 0.62
            for i in 0..<6 {
                let x = Double(i + 1)
                pts.append(GraphPoint(x: x, y: slope * x + Double(rng.nextInt(-2, 2)) / 10))
            }
            computed = slope
        }

        return GraphDataset(type: type, seed: seed, points: pts, expectedGradient: computed)
    }
}
struct GraphGradientMarker {
    func mark(dataset: GraphDataset, studentGradient: Double?, pointsTooClose: Bool = false, pointsExtrapolated: Bool = false, axisChoiceCorrect: Bool = true, curriculum: Curriculum) -> GraphGradientResult {
        guard let s = studentGradient else {
            return GraphGradientResult(correct: false, score: 0, expectedGradient: dataset.expectedGradient, studentGradient: nil, feedback: ["Enter a numerical value."], explanation: "Use two well-separated points on the best-fit line where a gradient is appropriate.")
        }
        let tol = max(abs(dataset.expectedGradient) * 0.12, 0.02)
        let valueOK = abs(s - dataset.expectedGradient) <= tol
        let explanation = dataset.type == .titrationCurve ? "For titration, focus on locating the end-point rather than treating the curve's gradient as a physical constant." : "Use a large triangle and points on the best-fit line. Quote the gradient with correct units."

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
}
