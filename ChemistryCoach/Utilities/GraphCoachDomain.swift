
import Foundation

struct GraphDatasetGenerator {
    func generate(type: GraphCoachType, seed: Int, curriculum: Curriculum) -> GraphDataset {
        var rng=SeededRandomNumberGenerator(seed:seed)
        let slope:Double
        var pts:[GraphPoint]=[]
        switch type {
        case .titrationCurve:
            slope=1
            for i in 0..<9 { let x=Double(i*3); let y=x < 12 ? 2.8 + x*0.08 : x < 18 ? 3.8 + (x-12)*0.8 : 8.6 + (x-18)*0.18; pts.append(GraphPoint(x:x,y:y+Double(rng.nextInt(-3,3))/10)) }
        case .rateGasVolume:
            slope=2.4
            for i in 0..<8 { let x=Double(i*10); let y=65*(1-exp(-0.08*x)); pts.append(GraphPoint(x:x,y:y+Double(rng.nextInt(-5,5))/10)) }
        case .rateConcentration:
            slope = -0.03
            for i in 0..<8 { let x=Double(i*10); let y=0.50*exp(-0.06*x); pts.append(GraphPoint(x:x,y:y+Double(rng.nextInt(-3,3))/100)) }
        case .temperatureChange:
            slope=0.2
            for i in 0..<8 { let x=Double(i*30); let y=24+8*(1-exp(-0.06*Double(i))); pts.append(GraphPoint(x:x,y:y+Double(rng.nextInt(-3,3))/10)) }
        case .chromatography:
            slope=0.62
            for i in 0..<6 { let x=Double(i+1); pts.append(GraphPoint(x:x,y:slope*x+Double(rng.nextInt(-2,2))/10)) }
        }
        let computed:Double
        if type == .chromatography { computed=slope } else if type == .rateGasVolume { computed=slope } else if type == .rateConcentration { computed=slope } else { computed=slope }
        return GraphDataset(type:type,seed:seed,points:pts,expectedGradient:computed)
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
