//
//  LabScenesMeasure.swift
//  ChemistryCoach
//
//  Animated scenes built around taking a measurement: paper chromatography
//  (ruler + rising solvent front) and energy changes (thermometer in an
//  insulated cup).
//

import SwiftUI

extension LabScenes {
    // MARK: - Paper chromatography

    static func chromatography(_ c: inout GraphicsContext, _ m: ChemistryLabViewModel) {
        let mo = m.motion
        let t = mo.ambient
        let finalFront = m.chromatographySolventFront
        let frontNow = mo.smooth("front", to: finalFront, rate: 2.2)
        let progress = LabMath.clamp01(frontNow / max(m.chromatographyMaxTravel, 0.1))
        let baselineY: CGFloat = 252
        let pxPerCm: CGFloat = 17
        let paper = CGRect(x: 165, y: 36, width: 60, height: 240)
        let frontY = baselineY - frontNow.cg * pxPerCm
        let spotNow = mo.smooth("spot", to: m.chromatographySpotPosition, rate: 2.2)
        let spotY = baselineY - spotNow.cg * pxPerCm
        let solvent = LabDraw.waterTint
        let purple = Color(red: 0.55, green: 0.2, blue: 0.8)

        LabDraw.bench(&c)
        LabDraw.shadow(&c, x: 195, y: LabCanvas.bench, width: 200)

        // Support rod and paper strip
        LabDraw.segment(&c, CGPoint(x: 120, y: 22), CGPoint(x: 270, y: 22), Color.primary.opacity(0.5), 4)
        c.fill(Path(paper), with: .color(Color(white: 0.98)))
        c.drawLayer { l in
            l.clip(to: Path(paper))
            var wet = Path()
            let steps = 15
            for i in 0...steps {
                let x = paper.minX + paper.width * CGFloat(i) / CGFloat(steps)
                let y = frontY + CGFloat(sin(Double(x) * 0.35 + t * 1.7)) * 1.5
                if i == 0 {
                    wet.move(to: CGPoint(x: x, y: y))
                } else {
                    wet.addLine(to: CGPoint(x: x, y: y))
                }
            }
            let edge = wet
            wet.addLine(to: CGPoint(x: paper.maxX, y: paper.maxY))
            wet.addLine(to: CGPoint(x: paper.minX, y: paper.maxY))
            wet.closeSubpath()
            l.fill(wet, with: .linearGradient(Gradient(colors: [solvent.opacity(0.55), solvent.opacity(0.18)]), startPoint: CGPoint(x: 0, y: frontY), endPoint: CGPoint(x: 0, y: paper.maxY)))
            l.stroke(edge, with: .color(solvent.opacity(0.9)), lineWidth: 1.6)

            LabDraw.segment(&l, CGPoint(x: paper.minX + 6, y: baselineY), CGPoint(x: paper.maxX - 6, y: baselineY), Color(white: 0.3), 1.6)
            let trail = CGRect(x: paper.midX - 3, y: spotY, width: 6, height: max(0, baselineY - spotY))
            l.fill(Path(roundedRect: trail, cornerRadius: 3), with: .color(purple.opacity(0.16)))
            LabDraw.dot(&l, paper.midX, baselineY, 4, purple.opacity(0.3))
            let sr = 6 + 2.5 * progress
            let spotCentre = CGPoint(x: paper.midX, y: spotY)
            let spotRect = CGRect(x: spotCentre.x - sr.cg, y: spotCentre.y - sr.cg, width: sr.cg * 2, height: sr.cg * 2)
            l.fill(Path(ellipseIn: spotRect), with: .radialGradient(Gradient(colors: [purple.opacity(0.95), purple.opacity(0.0)]), center: spotCentre, startRadius: 0, endRadius: sr.cg))
        }
        c.stroke(Path(paper), with: .color(Color.gray.opacity(0.6)), lineWidth: 1)
        c.fill(Path(roundedRect: CGRect(x: paper.minX - 2, y: 30, width: paper.width + 4, height: 9), cornerRadius: 2), with: .color(Color(white: 0.45)))

        // Ruler measured from the baseline
        let rulerTop = baselineY - 13 * pxPerCm
        let ruler = CGRect(x: 46, y: rulerTop, width: 32, height: baselineY + 6 - rulerTop)
        c.fill(Path(roundedRect: ruler, cornerRadius: 3), with: .color(Color.yellow.opacity(0.22)))
        c.stroke(Path(roundedRect: ruler, cornerRadius: 3), with: .color(Color.primary.opacity(0.3)), lineWidth: 1)
        for k in 0...120 {
            let y = baselineY - CGFloat(k) / 10 * pxPerCm
            let whole = k % 10 == 0
            let half = k % 5 == 0
            let len: CGFloat = whole ? 12 : (half ? 8 : 4)
            LabDraw.segment(&c, CGPoint(x: 78, y: y), CGPoint(x: 78 - len, y: y), Color.primary.opacity(whole ? 0.85 : 0.5), whole ? 1.1 : 0.6)
            if whole {
                LabDraw.label(&c, "\(k / 10)", CGPoint(x: 56, y: y), size: 8, weight: .medium)
            }
        }
        LabDraw.label(&c, "cm", CGPoint(x: 62, y: rulerTop - 8), size: 9, weight: .medium, color: Color.secondary)

        // Dashed guides from the ruler to the baseline, spot and solvent front
        let dash = StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 3])
        let guides: [(CGFloat, Color)] = [(baselineY, Color.gray), (spotY, purple), (frontY, Color.blue)]
        for guide in guides {
            var g = Path()
            g.move(to: CGPoint(x: 78, y: guide.0))
            g.addLine(to: CGPoint(x: paper.minX, y: guide.0))
            c.stroke(g, with: .color(guide.1.opacity(0.65)), style: dash)
        }

        // Beaker of solvent in front of the lower part of the paper
        let beaker = LabDraw.beakerPath(left: 100, right: 290, top: 228, bottom: 296, corner: 12)
        c.drawLayer { l in
            l.clip(to: beaker)
            let pool = LabDraw.liquidPath(x0: 96, x1: 294, surface: 268, bottom: 300, amp: 0.9, phase: t * 1.6)
            l.fill(pool, with: .color(solvent.opacity(0.28)))
        }
        LabDraw.strokeGlass(&c, beaker)
        LabDraw.shine(&c, x: 106, y: 236, height: 40)
        let creep = CGRect(x: paper.minX - 3, y: 266, width: paper.width + 6, height: 4)
        c.stroke(Path(ellipseIn: creep), with: .color(solvent.opacity(0.7)), lineWidth: 1)

        LabDraw.label(&c, "solvent front", CGPoint(x: paper.maxX + 8, y: frontY), size: 9, weight: .semibold, color: Color.blue, anchor: .leading)
        LabDraw.label(&c, "baseline", CGPoint(x: paper.maxX + 8, y: baselineY), size: 9, weight: .medium, color: Color.secondary, anchor: .leading)
        LabDraw.label(&c, "Measure from the baseline · zoom in to read the ruler", CGPoint(x: 180, y: 314), size: 9.5, weight: .medium)
    }

    // MARK: - Energy changes

    static func energetics(_ c: inout GraphicsContext, _ m: ChemistryLabViewModel) {
        let mo = m.motion
        let t = mo.ambient
        let initial = m.energeticsInitialTemp
        let temp = mo.smooth("temp", to: m.energeticsFinalTemp, rate: 1.6)
        let dT = temp - initial
        let warm = LabMath.smoothstep(dT / 6)
        let cool = LabMath.smoothstep(-dT / 5)
        let reacting = m.actionState == .reacting || m.actionState == .addingReagent
        let stir = mo.smooth("stir", to: (reacting || m.actionState == .observing) ? 1 : 0, rate: 4)
        let fizz = mo.smooth("fizzE", to: reacting ? 0.8 : 0, rate: 3)

        LabDraw.bench(&c)
        LabDraw.shadow(&c, x: 160, y: LabCanvas.bench, width: 140)

        // Insulated cup (cutaway so the liquid stays visible)
        var outer = Path()
        outer.move(to: CGPoint(x: 96, y: 120))
        outer.addLine(to: CGPoint(x: 224, y: 120))
        outer.addLine(to: CGPoint(x: 208, y: 292))
        outer.addLine(to: CGPoint(x: 112, y: 292))
        outer.closeSubpath()
        var cavity = Path()
        cavity.move(to: CGPoint(x: 105, y: 122))
        cavity.addLine(to: CGPoint(x: 215, y: 122))
        cavity.addLine(to: CGPoint(x: 201, y: 282))
        cavity.addLine(to: CGPoint(x: 119, y: 282))
        cavity.closeSubpath()
        c.fill(outer, with: .color(Color.gray.opacity(0.22)))
        c.stroke(outer, with: .color(Color.primary.opacity(0.4)), lineWidth: 1.5)
        c.fill(cavity, with: .color(Color(.systemBackground)))

        let surface: CGFloat = 176
        c.drawLayer { l in
            l.clip(to: cavity)
            let liquid = LabDraw.liquidPath(x0: 100, x1: 220, surface: surface, bottom: 290, amp: (0.8 + 1.5 * stir).cg, phase: t * 2.2)
            l.fill(liquid, with: .color(Color(red: 0.55, green: 0.75, blue: 0.95).opacity(0.28)))
            l.fill(liquid, with: .color(Color(red: 1.0, green: 0.55, blue: 0.2).opacity(0.38 * warm)))
            l.fill(liquid, with: .color(Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.35 * cool)))
            LabDraw.bubbleStream(&l, t: t, count: 26, intensity: fizz, x0: 124, x1: 196, yStart: 278, yEnd: surface, speed: 70, radius: 2.8, salt: 13)
        }

        // Condensation on the outside when the mixture cools
        if cool > 0.05 {
            for i in 0..<10 {
                let y = 140 + 15 * CGFloat(i)
                let slope = (y - 120) * 0.094
                let drop = 1.4 + 0.8 * LabMath.hash(i, 3).cg
                LabDraw.dot(&c, 96 + slope - 3, y, drop, Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.8 * cool))
                LabDraw.dot(&c, 224 - slope + 3, y + 6, drop, Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.8 * cool))
            }
        }

        // Lid
        c.fill(Path(roundedRect: CGRect(x: 90, y: 112, width: 140, height: 10), cornerRadius: 3), with: .color(Color.gray.opacity(0.55)))

        // Rising heat when the mixture warms up
        if warm > 0.05 {
            for i in 0..<5 {
                let x = 116 + 22 * CGFloat(i)
                let phase = LabMath.fract(t * 0.5 + LabMath.hash(i, 8))
                let y0 = 104 - 30 * CGFloat(phase)
                var wave = Path()
                wave.move(to: CGPoint(x: x, y: y0))
                wave.addQuadCurve(to: CGPoint(x: x, y: y0 - 16), control: CGPoint(x: x + 6 * CGFloat(sin(phase * 6.28 + Double(i))), y: y0 - 8))
                c.stroke(wave, with: .color(Color.orange.opacity(sin(phase * Double.pi) * 0.7 * warm)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }

        // Stirring rod
        let sway = stir * sin(t * 6)
        let topX = 200 + CGFloat(stir * sin(t * 5)) * 4
        let botX = 184 + CGFloat(sway) * 14
        var rod = Path()
        rod.move(to: CGPoint(x: topX, y: 70))
        rod.addLine(to: CGPoint(x: botX, y: 262))
        c.stroke(rod, with: .color(Color.primary.opacity(0.45)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        c.stroke(Path(ellipseIn: CGRect(x: botX - 6, y: 254, width: 12, height: 8)), with: .color(Color.primary.opacity(0.45)), lineWidth: 1.5)

        // Thermometer in the cup
        let miniTop = 250 - CGFloat((temp - 10) / 30) * 190
        let thermX: CGFloat = 148
        c.fill(Path(roundedRect: CGRect(x: thermX - 3.5, y: 56, width: 7, height: 210), cornerRadius: 3.5), with: .color(Color.white.opacity(0.5)))
        c.stroke(Path(roundedRect: CGRect(x: thermX - 3.5, y: 56, width: 7, height: 210), cornerRadius: 3.5), with: .color(Color.primary.opacity(0.45)), lineWidth: 1)
        LabDraw.dot(&c, thermX, 270, 6, Color.red)
        c.fill(Path(CGRect(x: thermX - 1.5, y: min(max(miniTop, 58), 268), width: 3, height: 268 - min(max(miniTop, 58), 268))), with: .color(Color.red))

        // Magnified thermometer for reading the temperature
        let stemX: CGFloat = 300
        func scaleY(_ v: Double) -> CGFloat { 250 - CGFloat((v - 10) / 30) * 200 }
        c.fill(Path(roundedRect: CGRect(x: stemX - 5, y: 40, width: 10, height: 224), cornerRadius: 5), with: .color(Color.white.opacity(0.6)))
        c.stroke(Path(roundedRect: CGRect(x: stemX - 5, y: 40, width: 10, height: 224), cornerRadius: 5), with: .color(Color.primary.opacity(0.5)), lineWidth: 1.2)
        LabDraw.dot(&c, stemX, 268, 10, Color.red)
        let colTop = min(max(scaleY(temp), 44), 268)
        c.fill(Path(CGRect(x: stemX - 2, y: colTop, width: 4, height: 268 - colTop)), with: .color(Color.red))
        for k in 0...60 {
            let v = 10 + Double(k) * 0.5
            let y = scaleY(v)
            let five = k % 10 == 0
            let one = k % 2 == 0
            let len: CGFloat = five ? 12 : (one ? 7 : 4)
            LabDraw.segment(&c, CGPoint(x: stemX - 7, y: y), CGPoint(x: stemX - 7 - len, y: y), Color.primary.opacity(five ? 0.85 : 0.5), five ? 1.1 : 0.6)
            if five {
                LabDraw.label(&c, "\(Int(v))", CGPoint(x: stemX - 28, y: y), size: 8, weight: .medium)
            }
        }
        let startY = scaleY(initial)
        var marker = Path()
        marker.move(to: CGPoint(x: stemX + 7, y: startY))
        marker.addLine(to: CGPoint(x: stemX + 15, y: startY - 4))
        marker.addLine(to: CGPoint(x: stemX + 15, y: startY + 4))
        marker.closeSubpath()
        c.fill(marker, with: .color(Color.blue.opacity(0.8)))
        LabDraw.label(&c, "start", CGPoint(x: stemX + 18, y: startY), size: 8, weight: .medium, color: Color.blue, anchor: .leading)
        LabDraw.label(&c, String(format: "%.1f °C", temp), CGPoint(x: stemX, y: 26), size: 13, weight: .bold)

        LabDraw.label(&c, "Insulated cup + lid", CGPoint(x: 160, y: 312), size: 10, weight: .medium)
        LabDraw.label(&c, "Thermometer", CGPoint(x: stemX, y: 312), size: 10, weight: .medium)
    }
}
