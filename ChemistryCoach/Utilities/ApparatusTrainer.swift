
import Foundation

struct ApparatusTrainer {
    func question(type: ApparatusType, seed: Int, curriculum: Curriculum = .singapore) -> ApparatusQuestion {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let (reading, tolerance, state, prompt, trap): (Double,Double,ApparatusVisualState,String,String)
        switch type {
        case .balance:
            let value = Double(rng.nextInt(120, 950)) / 10
            reading = value; tolerance = 0.1; state = .balance(massG:value)
            prompt = "Read the balance to the displayed precision. Include the unit."; trap = "Do not report fewer decimal places than the balance display."
        case .burette:
            let value = Double(rng.nextInt(100, 480)) / 10
            reading = value; tolerance = 0.05; state = .burette(readingCm3:value)
            prompt = "Read the bottom of the meniscus. Burette readings increase downwards."; trap = "A burette is read from the top scale downward; record to 0.05 cm³."
        case .pipette:
            reading = 25.0; tolerance = 0.05; state = .pipette
            prompt = "A 25.0 cm³ volumetric pipette is used. What volume is delivered?"; trap = "A volumetric pipette is calibrated to deliver its stated fixed volume."
        case .measuringCylinder:
            let value = Double(rng.nextInt(15, 95))
            reading = value; tolerance = 0.5; state = .measuringCylinder(volumeCm3:value)
            prompt = "Read the bottom of the meniscus at eye level."; trap = "Avoid parallax and read the bottom of the meniscus for aqueous solutions."
        case .thermometer:
            let value = Double(rng.nextInt(180, 780))/10
            reading = value; tolerance = 0.5; state = .thermometer(tempC:value)
            prompt = "Read the thermometer scale and record the temperature with suitable precision."; trap = "Do not overstate the precision of an analogue thermometer."
        case .gasSyringe:
            let value = Double(rng.nextInt(15, 95))
            reading = value; tolerance = 1; state = .gasSyringe(volumeCm3:value)
            prompt = "Read the gas syringe volume at eye level."; trap = "Check the zero and read the scale at eye level."
        case .stopwatch:
            let value = Double(rng.nextInt(50, 950))/10
            reading = value; tolerance = 0.1; state = .stopwatch(seconds:value)
            prompt = "Record the elapsed time shown by the stopwatch."; trap = "For rate experiments, repeat timings where appropriate and use a consistent start/stop method."
        }
        return ApparatusQuestion(apparatusType:type, seed:seed, prompt:prompt, correctReading:reading, tolerance:tolerance, unit:type.unit, visualState:state,
            commonMistakes:[CommonMistake(title:"Precision", explanation:"Use the precision justified by the instrument scale.", examinerPenalty:"May lose measurement/observation marks.")],
            examTrap:trap)
    }
    func mark(question: ApparatusQuestion, studentReading: Double?) -> ApparatusMarkResult {
        guard let v = studentReading else { return ApparatusMarkResult(correct:false,score:0,feedback:["Enter a reading.","Correct: \(fmt(question.correctReading)) \(question.unit)."],mistakeExplanation:"No reading submitted.",examTrap:question.examTrap) }
        let ok = abs(v-question.correctReading)<=question.tolerance
        return ApparatusMarkResult(correct:ok,score:ok ? 100 : 0,
            feedback: ok ? ["Accepted within tolerance.","Correct reading: \(fmt(question.correctReading)) \(question.unit)."] : ["Outside tolerance.","Correct reading: \(fmt(question.correctReading)) \(question.unit).","Review the meniscus, scale direction and instrument precision."],
            mistakeExplanation: ok ? nil : "Your reading differs from the expected reading.",
            examTrap: question.examTrap)
    }
    private func fmt(_ x:Double)->String { String(format:"%.2f",x).replacingOccurrences(of:"0+$",with:"",options:.regularExpression).replacingOccurrences(of:"\\.$",with:"",options:.regularExpression) }
}
