//
//  LabScenesGasAndCell.swift
//  ChemistryCoach
//
//  Animated scenes: rate of reaction (gas collection over water) and electrolysis.
//

import SwiftUI

extension LabScenes {
    // MARK: - Rate of reaction

    static func rate(_ c: inout GraphicsContext, _ m: ChemistryLabViewModel) {
        let mo = m.motion
        let t = mo.ambient
        let fx: CGFloat = 78
        let intensity = mo.smooth("fizz", to: LabMath.clamp01(m.gasRate / 9.0), rate: 4)
        let shownVolume = mo.smooth("gas", to: m.gasVolume, rate: 12)
        let frac = LabMath.clamp01(m.gasVolume / 72)
        let water = LabDraw.waterTint

        LabDraw.bench(&c)
        LabDraw.shadow(&c, x: fx, y: LabCanvas.bench, width: 124)

        // Trough of water
        let troughLeft: CGFloat = 186
        let troughRight: CGFloat = 346
        let trough = LabDraw.beakerPath(left: troughLeft, right: troughRight, top: 244, bottom: 296, corner: 8)
        let waterTop: CGFloat = 252
        c.drawLayer { l in
            l.clip(to: trough)
            let waves = LabDraw.liquidPath(x0: troughLeft - 4, x1: troughRight + 4, surface: waterTop, bottom: 300, amp: 1.2, phase: t * 1.8)
            l.fill(waves, with: .color(water.opacity(0.28)))
        }

        // Inverted measuring cylinder: 0 cm³ at the closed top, 80 cm³ near the mouth
        let cylX: CGFloat = 250
        let cylTop: CGFloat = 124
        let cylBottom: CGFloat = 272
        let cylHalf: CGFloat = 18
        let scaleTop: CGFloat = 130
        let scaleHeight: CGFloat = 120
        let levelY = scaleTop + scaleHeight * CGFloat(min(shownVolume, 80) / 80)
        let cylinder = LabDraw.invertedTubePath(cx: cylX, top: cylTop, bottom: cylBottom, halfWidth: cylHalf)
        c.drawLayer { l in
            l.clip(to: cylinder)
            l.fill(Path(CGRect(x: cylX - cylHalf, y: cylTop, width: cylHalf * 2, height: levelY - cylTop)), with: .color(Color.white.opacity(0.22)))
            let inner = LabDraw.liquidPath(x0: cylX - cylHalf, x1: cylX + cylHalf, surface: levelY, bottom: cylBottom + 4, amp: 0.8, phase: t * 2)
            l.fill(inner, with: .color(water.opacity(0.30)))
            LabDraw.segment(&l, CGPoint(x: cylX - cylHalf, y: levelY), CGPoint(x: cylX + cylHalf, y: levelY), Color.primary.opacity(0.35), 1)
            LabDraw.bubbleStream(&l, t: t, count: 16, intensity: intensity, x0: cylX - 4, x1: cylX + 4, yStart: 266, yEnd: levelY, speed: 70, radius: 2.4, salt: 5)
        }
        LabDraw.strokeGlass(&c, cylinder)
        LabDraw.shine(&c, x: cylX - cylHalf + 3, y: cylTop + 12, height: 80)
        for v in stride(from: 0, through: 80, by: 5) {
            let y = scaleTop + scaleHeight * CGFloat(v) / 80
            let major = v % 20 == 0
            let len: CGFloat = major ? 10 : 6
            LabDraw.segment(&c, CGPoint(x: cylX - cylHalf, y: y), CGPoint(x: cylX - cylHalf - len, y: y), Color.primary.opacity(0.7), major ? 1.2 : 0.8)
            if major {
                LabDraw.label(&c, "\(v)", CGPoint(x: cylX - cylHalf - 20, y: y), size: 9, weight: .medium)
            }
        }
        LabDraw.label(&c, String(format: "%.0f cm³", shownVolume), CGPoint(x: cylX + cylHalf + 6, y: levelY), size: 10, weight: .bold, color: Color.accentColor, anchor: .leading)

        // Trough glass in front of the water
        LabDraw.strokeGlass(&c, trough)

        // Delivery tube (over the trough wall, under the water, up into the cylinder)
        let tubePts: [CGPoint] = [CGPoint(x: fx, y: 170), CGPoint(x: fx, y: 112), CGPoint(x: 318, y: 112), CGPoint(x: 318, y: 284), CGPoint(x: cylX, y: 284), CGPoint(x: cylX, y: 268)]
        LabDraw.glassTube(&c, tubePts, width: 5)
        if intensity > 0.05 {
            for k in 0..<10 {
                let f = LabMath.fract(t * 0.35 + Double(k) / 10)
                let p = LabDraw.point(on: tubePts, at: f)
                LabDraw.dot(&c, p.x, p.y, 1.7, Color.gray.opacity(0.7 * intensity))
            }
        }

        // Flask
        let flask = LabDraw.flaskPath(cx: fx, top: 176, shoulder: 200, base: 292, neckHalf: 11, baseHalf: 60)
        let surface: CGFloat = 246
        let conc = m.rateConcentration
        let area = m.rateSurfaceArea
        let chipCount = 3 + Int(area * 9)
        let chipSize = (12 - area * 7) * (1 - 0.35 * frac)
        c.drawLayer { l in
            l.clip(to: flask)
            let acid = LabDraw.liquidPath(x0: fx - 70, x1: fx + 70, surface: surface, bottom: 300, amp: (0.8 + 1.5 * intensity).cg, phase: t * 2.4)
            l.fill(acid, with: .color(Color(red: 0.95, green: 0.88, blue: 0.45).opacity(0.14 + 0.32 * conc)))
            for i in 0..<chipCount {
                let px = fx - 34 + 68 * LabMath.hash(i, 21).cg
                let lift: CGFloat = i % 3 == 0 ? 6 : 0
                let py = 286 - 8 * LabMath.hash(i, 22).cg - lift
                let s = chipSize.cg * (0.7 + 0.6 * LabMath.hash(i, 23)).cg
                var chip = Path()
                chip.move(to: CGPoint(x: px - s, y: py))
                chip.addLine(to: CGPoint(x: px - s * 0.3, y: py - s * 0.9))
                chip.addLine(to: CGPoint(x: px + s * 0.8, y: py - s * 0.5))
                chip.addLine(to: CGPoint(x: px + s, y: py))
                chip.closeSubpath()
                l.fill(chip, with: .color(Color(white: 0.86)))
                l.stroke(chip, with: .color(Color.gray.opacity(0.7)), lineWidth: 0.7)
            }
            LabDraw.bubbleStream(&l, t: t, count: 34, intensity: intensity, x0: fx - 40, x1: fx + 40, yStart: 284, yEnd: surface, speed: 75, radius: 3.2, salt: 15)
        }
        LabDraw.strokeGlass(&c, flask)
        LabDraw.shine(&c, x: fx - 10, y: 206, height: 12)
        var bung = Path()
        bung.move(to: CGPoint(x: fx - 15, y: 168))
        bung.addLine(to: CGPoint(x: fx + 15, y: 168))
        bung.addLine(to: CGPoint(x: fx + 11, y: 184))
        bung.addLine(to: CGPoint(x: fx - 11, y: 184))
        bung.closeSubpath()
        c.fill(bung, with: .color(Color(red: 0.62, green: 0.42, blue: 0.26)))

        // Stopwatch
        let watch = CGRect(x: 14, y: 12, width: 96, height: 36)
        c.fill(Path(roundedRect: watch, cornerRadius: 8), with: .color(Color.black.opacity(0.82)))
        LabDraw.label(&c, String(format: "%.1f s", m.elapsed), CGPoint(x: watch.midX, y: watch.midY), size: 17, weight: .bold, design: .monospaced, color: Color(red: 0.35, green: 1.0, blue: 0.55))

        // Live volume–time graph
        let panel = CGRect(x: 206, y: 8, width: 142, height: 92)
        c.fill(Path(roundedRect: panel, cornerRadius: 10), with: .color(Color(.secondarySystemBackground)))
        let plot = CGRect(x: panel.minX + 26, y: panel.minY + 12, width: panel.width - 36, height: panel.height - 32)
        LabDraw.segment(&c, CGPoint(x: plot.minX, y: plot.minY), CGPoint(x: plot.minX, y: plot.maxY), Color.primary.opacity(0.5), 1)
        LabDraw.segment(&c, CGPoint(x: plot.minX, y: plot.maxY), CGPoint(x: plot.maxX, y: plot.maxY), Color.primary.opacity(0.5), 1)
        LabDraw.label(&c, "V / cm³", CGPoint(x: panel.minX + 4, y: panel.minY + 8), size: 8, weight: .medium, color: Color.secondary, anchor: .leading)
        LabDraw.label(&c, "time / s", CGPoint(x: plot.midX, y: panel.maxY - 8), size: 8, weight: .medium, color: Color.secondary)
        let samples = m.rateData
        if samples.count > 1 {
            let step = max(1, samples.count / 120)
            var curve = Path()
            var lastPoint = CGPoint.zero
            var first = true
            for i in stride(from: 0, to: samples.count, by: step) {
                let sample = samples[i]
                let px = plot.minX + plot.width * CGFloat(min(sample.time, 60) / 60)
                let py = plot.maxY - plot.height * CGFloat(min(sample.volume, 80) / 80)
                lastPoint = CGPoint(x: px, y: py)
                if first {
                    curve.move(to: lastPoint)
                    first = false
                } else {
                    curve.addLine(to: lastPoint)
                }
            }
            c.stroke(curve, with: .color(Color.accentColor), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            LabDraw.dot(&c, lastPoint.x, lastPoint.y, 3.2, Color.accentColor)
        }

        let temperature = Int(20 + m.rateTemperature * 60)
        LabDraw.label(&c, "Acid \(Int(conc * 100))% · \(temperature) °C · chips \(Int(20 + area * 80))%", CGPoint(x: fx, y: 312), size: 9.5, weight: .medium)
        LabDraw.label(&c, "Gas collected over water", CGPoint(x: 266, y: 312), size: 9.5, weight: .medium)
    }

    // MARK: - Electrolysis

    static func electrolysis(_ c: inout GraphicsContext, _ m: ChemistryLabViewModel) {
        let mo = m.motion
        let t = mo.ambient
        let isCu = m.electrolysisElectrolyte == "Copper sulfate solution"
        let cu = mo.smooth("cu", to: isCu ? 1 : 0, rate: 5)
        let amps = 0.5 + m.control * 2.5
        let on = m.electrolysisCircuitOn
        let cur = mo.smooth("current", to: on ? 1 : 0, rate: 4)
        let intensity = cur * (0.3 + 0.7 * (amps - 0.5) / 2.5)
        if !on { mo.clearAccumulator("cu") }
        var dep = mo.accumulated("cu")
        if on && isCu {
            dep = mo.accumulate("cu", perSecond: 0.012 * amps, cap: 1)
        }

        let anodeX: CGFloat = 150
        let cathodeX: CGFloat = 210
        let surface: CGFloat = 172

        LabDraw.bench(&c)
        LabDraw.shadow(&c, x: 180, y: LabCanvas.bench, width: 250)

        // Power supply
        let supply = CGRect(x: 96, y: 6, width: 168, height: 38)
        c.fill(Path(roundedRect: supply, cornerRadius: 8), with: .color(Color.gray.opacity(0.35)))
        c.stroke(Path(roundedRect: supply, cornerRadius: 8), with: .color(Color.primary.opacity(0.35)), lineWidth: 1)
        let screen = CGRect(x: 150, y: 11, width: 60, height: 22)
        c.fill(Path(roundedRect: screen, cornerRadius: 4), with: .color(Color.black.opacity(0.85)))
        LabDraw.label(&c, String(format: "%.1f A", amps), CGPoint(x: screen.midX, y: screen.midY), size: 13, weight: .bold, design: .monospaced, color: Color(red: 0.35, green: 1.0, blue: 0.55).opacity(0.4 + 0.6 * cur))
        LabDraw.dot(&c, 246, 22, 4, on ? Color.green : Color.red.opacity(0.6))
        LabDraw.dot(&c, 130, 44, 5, Color(red: 0.85, green: 0.2, blue: 0.2))
        LabDraw.dot(&c, 230, 44, 5, Color(white: 0.15))
        LabDraw.label(&c, "+", CGPoint(x: 130, y: 30), size: 13, weight: .bold)
        LabDraw.label(&c, "−", CGPoint(x: 230, y: 30), size: 13, weight: .bold)

        // Wires with electrons flowing (supply − → cathode, anode → supply +)
        let anodeWire: [CGPoint] = [CGPoint(x: anodeX, y: 100), CGPoint(x: anodeX, y: 60), CGPoint(x: 130, y: 60), CGPoint(x: 130, y: 44)]
        let cathodeWire: [CGPoint] = [CGPoint(x: 230, y: 44), CGPoint(x: 230, y: 60), CGPoint(x: cathodeX, y: 60), CGPoint(x: cathodeX, y: 100)]
        c.stroke(LabDraw.polyline(anodeWire), with: .color(Color(red: 0.85, green: 0.2, blue: 0.2)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        c.stroke(LabDraw.polyline(cathodeWire), with: .color(Color.primary.opacity(0.85)), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        if cur > 0.05 {
            let speed = 0.3 + 0.5 * intensity
            for k in 0..<5 {
                let f = LabMath.fract(t * speed + Double(k) / 5)
                let pa = LabDraw.point(on: anodeWire, at: f)
                let pc = LabDraw.point(on: cathodeWire, at: f)
                LabDraw.dot(&c, pa.x, pa.y, 2.4, Color(red: 0.3, green: 0.6, blue: 1.0).opacity(cur))
                LabDraw.dot(&c, pc.x, pc.y, 2.4, Color(red: 0.3, green: 0.6, blue: 1.0).opacity(cur))
            }
        }

        // Electrodes (copper plating builds up on the cathode)
        let graphite = Color(white: 0.28)
        c.fill(Path(roundedRect: CGRect(x: anodeX - 7, y: 96, width: 14, height: 166), cornerRadius: 3), with: .color(graphite))
        c.fill(Path(roundedRect: CGRect(x: cathodeX - 7, y: 96, width: 14, height: 166), cornerRadius: 3), with: .color(graphite))
        if cu > 0.02 && dep > 0.01 {
            let thick = CGFloat(1 + 4 * dep)
            let plate = CGRect(x: cathodeX - 7 - thick, y: surface, width: 14 + thick * 2, height: 262 - surface)
            c.fill(Path(roundedRect: plate, cornerRadius: 3), with: .color(Color(red: 0.75, green: 0.42, blue: 0.22).opacity(cu)))
        }

        // Beaker, electrolyte, ions and gas bubbles
        let beaker = LabDraw.beakerPath(left: 60, right: 300, top: 122, bottom: 292, corner: 14)
        c.drawLayer { l in
            l.clip(to: beaker)
            let liquid = LabDraw.liquidPath(x0: 50, x1: 310, surface: surface, bottom: 300, amp: (0.8 + 1.4 * intensity).cg, phase: t * 2.0)
            l.fill(liquid, with: .color(Color.cyan.opacity(0.10 * (1 - cu))))
            l.fill(liquid, with: .color(Color(red: 0.2, green: 0.5, blue: 0.95).opacity(0.30 * cu * (1 - 0.35 * dep))))
            if cur > 0.05 {
                for i in 0..<9 {
                    let f = LabMath.fract(t * 0.22 + LabMath.hash(i, 61))
                    let y = 192 + 56 * LabMath.hash(i, 62).cg + CGFloat(sin(t * 2 + Double(i)) * 3)
                    let fade = sin(f * Double.pi) * 0.85 * cur
                    let sxC = 74 + 110 * LabMath.hash(i, 63).cg
                    let cx = sxC + (cathodeX - sxC) * f.cg
                    LabDraw.dot(&l, cx, y, 3, Color(red: 1.0, green: 0.55, blue: 0.2).opacity(fade))
                    let sxA = 176 + 114 * LabMath.hash(i, 64).cg
                    let ax = sxA + (anodeX - sxA) * f.cg
                    LabDraw.dot(&l, ax, y + 8, 3, Color(red: 0.55, green: 0.35, blue: 0.95).opacity(fade))
                }
            }
            LabDraw.bubbleStream(&l, t: t, count: 20, intensity: intensity * cu, x0: anodeX - 8, x1: anodeX + 8, yStart: 254, yEnd: surface, speed: 55, radius: 2.8, salt: 31)
            LabDraw.bubbleStream(&l, t: t, count: 20, intensity: intensity * (1 - cu), x0: anodeX - 8, x1: anodeX + 8, yStart: 254, yEnd: surface, speed: 55, radius: 3.4, salt: 41, tint: Color(red: 0.7, green: 0.92, blue: 0.2), fill: 0.6)
            LabDraw.bubbleStream(&l, t: t, count: 32, intensity: intensity * (1 - cu), x0: cathodeX - 8, x1: cathodeX + 8, yStart: 254, yEnd: surface, speed: 60, radius: 2.6, salt: 51)
        }
        LabDraw.strokeGlass(&c, beaker)
        LabDraw.shine(&c, x: 66, y: 134, height: 100)

        // Clamp bar
        c.fill(Path(roundedRect: CGRect(x: 96, y: 112, width: 168, height: 8), cornerRadius: 3), with: .color(Color(red: 0.62, green: 0.45, blue: 0.28)))

        LabDraw.label(&c, "ANODE (+)", CGPoint(x: 140, y: 88), size: 10, weight: .bold, anchor: .trailing)
        LabDraw.label(&c, "CATHODE (−)", CGPoint(x: 220, y: 88), size: 10, weight: .bold, anchor: .leading)
        LabDraw.dot(&c, 16, 64, 3, Color(red: 1.0, green: 0.55, blue: 0.2))
        LabDraw.label(&c, "cations → cathode", CGPoint(x: 24, y: 64), size: 9, weight: .regular, color: Color.secondary, anchor: .leading)
        LabDraw.dot(&c, 16, 78, 3, Color(red: 0.55, green: 0.35, blue: 0.95))
        LabDraw.label(&c, "anions → anode", CGPoint(x: 24, y: 78), size: 9, weight: .regular, color: Color.secondary, anchor: .leading)
        LabDraw.label(&c, m.electrolysisElectrolyte, CGPoint(x: 180, y: 312), size: 10, weight: .medium)
    }
}
