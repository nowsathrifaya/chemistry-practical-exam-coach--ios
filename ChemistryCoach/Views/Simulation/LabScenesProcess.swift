//
//  LabScenesProcess.swift
//  ChemistryCoach
//
//  Animated multi-step scenes. The lab's step index drives a timed tween, so
//  pressing "Complete stage" plays that stage as an animation:
//    • Separation: filtration → evaporation (sand + salt), or
//                  separating funnel → distillation (immiscible liquids).
//    • Solubility: dissolve → concentrate → cool and crystallise → filter and dry.
//

import SwiftUI

extension LabScenes {
    // MARK: - Separation & purification

    static func separation(_ c: inout GraphicsContext, _ m: ChemistryLabViewModel) {
        let mo = m.motion
        let t = mo.ambient
        let p = mo.tween("sep", to: Double(m.separationStep), duration: 3.4)
        let q1 = LabMath.clamp01(p)
        let pan = LabMath.smoothstep((p - 1.0) / 0.35)
        let q2 = LabMath.clamp01((p - 1.3) / 0.7)
        let liquids = m.mixtureLabel == "two immiscible liquids"

        c.clip(to: Path(CGRect(x: 0, y: 0, width: LabCanvas.width, height: LabCanvas.height)))
        LabDraw.bench(&c)

        let shift = -LabCanvas.width * CGFloat(pan)
        c.drawLayer { l in
            l.translateBy(x: shift, y: 0)
            if liquids {
                separatingFunnelPanel(&l, t: t, q: q1)
                l.translateBy(x: LabCanvas.width, y: 0)
                distillationPanel(&l, t: t, q: q2)
            } else {
                filtrationPanel(&l, t: t, q: q1)
                l.translateBy(x: LabCanvas.width, y: 0)
                evaporationPanel(&l, t: t, q: q2)
            }
        }
    }

    private static var mud: Color { Color(red: 0.70, green: 0.60, blue: 0.42) }

    private static func filtrationPanel(_ c: inout GraphicsContext, t: Double, q: Double) {
        LabDraw.label(&c, "Filtration: the sand stays in the filter paper", CGPoint(x: 180, y: 16), size: 11, weight: .bold)
        let pour = LabMath.smoothstep(q / 0.15) * (1 - LabMath.smoothstep((q - 0.72) / 0.2))
        let drain = LabMath.smoothstep((q - 0.15) / 0.55)
        let filtered = LabMath.smoothstep((q - 0.2) / 0.75)
        let funnelLevel = LabMath.smoothstep((q - 0.15) / 0.2) * (1 - LabMath.smoothstep((q - 0.72) / 0.25))

        // Retort stand holding the funnel
        LabDraw.segment(&c, CGPoint(x: 322, y: 60), CGPoint(x: 322, y: 296), Color.primary.opacity(0.5), 4)
        LabDraw.segment(&c, CGPoint(x: 322, y: 146), CGPoint(x: 296, y: 146), Color.primary.opacity(0.5), 3)
        c.fill(Path(roundedRect: CGRect(x: 296, y: 290, width: 50, height: 6), cornerRadius: 2), with: .color(Color.primary.opacity(0.4)))

        // Receiving flask
        let fx: CGFloat = 250
        let flask = LabDraw.flaskPath(cx: fx, top: 236, shoulder: 256, base: 296, neckHalf: 9, baseHalf: 46)
        let filtrateH = 26 * CGFloat(filtered)
        c.drawLayer { l in
            l.clip(to: flask)
            if filtrateH > 0.5 {
                let pool = LabDraw.liquidPath(x0: fx - 60, x1: fx + 60, surface: 293 - filtrateH, bottom: 300, amp: 0.8, phase: t * 2)
                l.fill(pool, with: .color(LabDraw.waterTint.opacity(0.32)))
            }
        }
        LabDraw.strokeGlass(&c, flask)

        // Funnel with filter paper
        var glass = Path()
        glass.move(to: CGPoint(x: 204, y: 148))
        glass.addLine(to: CGPoint(x: 296, y: 148))
        glass.addLine(to: CGPoint(x: 256, y: 204))
        glass.addLine(to: CGPoint(x: 256, y: 228))
        glass.addLine(to: CGPoint(x: 244, y: 228))
        glass.addLine(to: CGPoint(x: 244, y: 204))
        glass.closeSubpath()
        var paper = Path()
        paper.move(to: CGPoint(x: 211, y: 152))
        paper.addLine(to: CGPoint(x: 289, y: 152))
        paper.addLine(to: CGPoint(x: 250, y: 208))
        paper.closeSubpath()
        c.fill(paper, with: .color(Color(white: 0.97).opacity(0.9)))
        c.stroke(paper, with: .color(Color.gray.opacity(0.6)), lineWidth: 1)
        if funnelLevel > 0.02 {
            let yL = 208 - 42 * CGFloat(funnelLevel)
            let hw = 38 * (208 - yL) / 56
            var liquid = Path()
            liquid.move(to: CGPoint(x: 250 - hw, y: yL))
            liquid.addLine(to: CGPoint(x: 250 + hw, y: yL))
            liquid.addLine(to: CGPoint(x: 250, y: 208))
            liquid.closeSubpath()
            c.fill(liquid, with: .color(mud.opacity(0.5)))
        }
        if drain > 0.02 {
            let yS = 208 - 18 * CGFloat(drain)
            let hw = 38 * (208 - yS) / 56
            var sand = Path()
            sand.move(to: CGPoint(x: 250 - hw, y: yS))
            sand.addLine(to: CGPoint(x: 250 + hw, y: yS))
            sand.addLine(to: CGPoint(x: 250, y: 208))
            sand.closeSubpath()
            c.fill(sand, with: .color(Color(red: 0.76, green: 0.62, blue: 0.38)))
            for i in 0..<10 {
                let gx = 250 + (LabMath.hash(i, 31).cg - 0.5) * hw * 1.5
                let gy = yS + 2 + LabMath.hash(i, 32).cg * 6
                LabDraw.dot(&c, gx, gy, 1.2, Color(red: 0.55, green: 0.42, blue: 0.22))
            }
        }
        LabDraw.strokeGlass(&c, glass)

        // Filtrate drips
        if q > 0.2 && q < 0.97 {
            let ph = LabMath.fract(t * 1.8)
            let dropY = 232 + (293 - filtrateH - 232) * (ph * ph).cg
            LabDraw.dot(&c, 250, dropY, 2.2, LabDraw.waterTint.opacity(0.85))
        }

        // Source beaker: rests on a block, then tilts and pours into the funnel
        c.fill(Path(roundedRect: CGRect(x: 44, y: 208, width: 90, height: 88), cornerRadius: 4), with: .color(Color(red: 0.62, green: 0.45, blue: 0.28).opacity(0.85)))
        let px = 118 + 100 * CGFloat(pour)
        let py = 136 - 14 * CGFloat(pour)
        let angle = 30 * pour
        let flow = pour * (1 - LabMath.smoothstep((drain - 0.93) / 0.06))
        if flow > 0.05 {
            var stream = Path()
            stream.move(to: CGPoint(x: px + 1, y: py + 2))
            stream.addQuadCurve(to: CGPoint(x: 246, y: 176), control: CGPoint(x: px + 24, y: py + 4))
            c.stroke(stream, with: .color(mud.opacity(0.75 * flow)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        c.drawLayer { g in
            g.translateBy(x: px, y: py)
            g.rotate(by: .degrees(angle))
            let body = LabDraw.beakerPath(left: -56, right: 0, top: 0, bottom: 72, corner: 8)
            g.drawLayer { inner in
                inner.clip(to: body)
                let sandAlpha = 1 - drain
                inner.fill(Path(ellipseIn: CGRect(x: -48, y: 60, width: 40, height: 12)), with: .color(Color(red: 0.76, green: 0.62, blue: 0.38).opacity(sandAlpha)))
                inner.rotate(by: .degrees(-angle))
                let level = 26 + 46 * CGFloat(drain)
                inner.fill(Path(CGRect(x: -140, y: level, width: 220, height: 220)), with: .color(mud.opacity(0.35)))
            }
            LabDraw.strokeGlass(&g, body)
        }
        LabDraw.label(&c, "Mixture: sand + salt in water", CGPoint(x: 88, y: 312), size: 9.5, weight: .medium)
        LabDraw.label(&c, "Filtrate: salt solution", CGPoint(x: 250, y: 312), size: 9.5, weight: .medium)
    }

    private static func evaporationPanel(_ c: inout GraphicsContext, t: Double, q: Double) {
        LabDraw.label(&c, "Evaporation: water leaves and salt crystallises", CGPoint(x: 180, y: 16), size: 11, weight: .bold)
        let cx: CGFloat = 180
        let remaining = 1 - LabMath.smoothstep(q / 0.9)
        let flameOn = 1 - LabMath.smoothstep((q - 0.88) / 0.1)

        // Tripod, gauze and burner
        LabDraw.segment(&c, CGPoint(x: cx - 62, y: 200), CGPoint(x: cx - 74, y: 296), Color.primary.opacity(0.55), 3)
        LabDraw.segment(&c, CGPoint(x: cx + 62, y: 200), CGPoint(x: cx + 74, y: 296), Color.primary.opacity(0.55), 3)
        c.fill(Path(roundedRect: CGRect(x: cx - 66, y: 198, width: 132, height: 4), cornerRadius: 2), with: .color(Color.primary.opacity(0.55)))
        c.fill(Path(roundedRect: CGRect(x: cx - 58, y: 194, width: 116, height: 4), cornerRadius: 2), with: .color(Color.gray.opacity(0.7)))
        c.fill(Path(roundedRect: CGRect(x: cx - 22, y: 286, width: 44, height: 10), cornerRadius: 3), with: .color(Color(white: 0.3)))
        c.fill(Path(roundedRect: CGRect(x: cx - 4, y: 240, width: 8, height: 46), cornerRadius: 2), with: .color(Color(white: 0.4)))
        LabDraw.flame(&c, x: cx, y: 240, height: 40 * CGFloat(flameOn), width: 16, t: t, seed: 5, blue: true)

        // Evaporating basin
        var bowl = Path()
        bowl.move(to: CGPoint(x: cx - 52, y: 166))
        bowl.addLine(to: CGPoint(x: cx + 52, y: 166))
        bowl.addQuadCurve(to: CGPoint(x: cx - 52, y: 166), control: CGPoint(x: cx, y: 222))
        let surface = 170 + 24 * CGFloat(1 - remaining)
        c.drawLayer { l in
            l.clip(to: bowl)
            if remaining > 0.02 {
                let liquid = LabDraw.liquidPath(x0: cx - 60, x1: cx + 60, surface: surface, bottom: 230, amp: 0.9, phase: t * 2.4)
                l.fill(liquid, with: .color(LabDraw.waterTint.opacity(0.36)))
            }
        }
        LabDraw.strokeGlass(&c, bowl, width: 2)

        let count = Int(LabMath.smoothstep((q - 0.4) / 0.5) * 24)
        if count > 0 {
            for i in 0..<count {
                let s = 0.15 + 0.7 * LabMath.hash(i, 41)
                let x = cx - 52 + 104 * s.cg
                let bowlY = 166 + 112 * s.cg * (1 - s.cg)
                let y = bowlY - 3 - 3 * LabMath.hash(i, 42).cg
                LabDraw.crystal(&c, x, y, (2.4 + 2.0 * LabMath.hash(i, 43)).cg, rotation: LabMath.hash(i, 44) * 1.5)
            }
        }
        let steamLevel = LabMath.smoothstep(q / 0.1) * (1 - LabMath.smoothstep((q - 0.85) / 0.12))
        LabDraw.steam(&c, t: t, x0: cx - 40, x1: cx + 40, y: 160, height: 80, intensity: steamLevel, salt: 6)
        LabDraw.label(&c, "Heat gently and stop before the basin dries out", CGPoint(x: 180, y: 314), size: 9.5, weight: .medium)
    }

    private static func separatingFunnelPanel(_ c: inout GraphicsContext, t: Double, q: Double) {
        LabDraw.label(&c, "Separating funnel: run off the denser lower layer", CGPoint(x: 180, y: 16), size: 11, weight: .bold)
        let cx: CGFloat = 180
        let drainP = LabMath.smoothstep((q - 0.12) / 0.62)
        let tapOpen = LabMath.smoothstep((q - 0.08) / 0.05) * (1 - LabMath.smoothstep((q - 0.75) / 0.05))

        // Stand and ring
        LabDraw.segment(&c, CGPoint(x: 112, y: 30), CGPoint(x: 112, y: 296), Color.primary.opacity(0.5), 4)
        LabDraw.segment(&c, CGPoint(x: 112, y: 112), CGPoint(x: cx - 46, y: 112), Color.primary.opacity(0.5), 3)
        c.fill(Path(roundedRect: CGRect(x: 80, y: 290, width: 70, height: 6), cornerRadius: 2), with: .color(Color.primary.opacity(0.4)))

        // Funnel
        var glass = Path()
        glass.move(to: CGPoint(x: cx - 7, y: 40))
        glass.addLine(to: CGPoint(x: cx - 7, y: 72))
        glass.addCurve(to: CGPoint(x: cx - 50, y: 132), control1: CGPoint(x: cx - 24, y: 74), control2: CGPoint(x: cx - 50, y: 100))
        glass.addCurve(to: CGPoint(x: cx - 3, y: 206), control1: CGPoint(x: cx - 50, y: 168), control2: CGPoint(x: cx - 14, y: 188))
        glass.addLine(to: CGPoint(x: cx - 3, y: 232))
        glass.addLine(to: CGPoint(x: cx + 3, y: 232))
        glass.addLine(to: CGPoint(x: cx + 3, y: 206))
        glass.addCurve(to: CGPoint(x: cx + 50, y: 132), control1: CGPoint(x: cx + 14, y: 188), control2: CGPoint(x: cx + 50, y: 168))
        glass.addCurve(to: CGPoint(x: cx + 7, y: 72), control1: CGPoint(x: cx + 50, y: 100), control2: CGPoint(x: cx + 24, y: 74))
        glass.addLine(to: CGPoint(x: cx + 7, y: 40))

        let waterH = 84 * CGFloat(1 - drainP)
        let interface = 232 - waterH
        let oilTop = interface - 60
        c.drawLayer { l in
            l.clip(to: glass)
            let oil = LabDraw.liquidPath(x0: cx - 60, x1: cx + 60, surface: oilTop, bottom: interface, amp: 0.6, phase: t * 1.6)
            l.fill(oil, with: .color(Color(red: 0.95, green: 0.82, blue: 0.25).opacity(0.5)))
            if waterH > 0.5 {
                l.fill(Path(CGRect(x: cx - 60, y: interface, width: 120, height: waterH + 10)), with: .color(LabDraw.waterTint.opacity(0.42)))
                LabDraw.segment(&l, CGPoint(x: cx - 60, y: interface), CGPoint(x: cx + 60, y: interface), Color.primary.opacity(0.25), 1)
            }
        }
        LabDraw.strokeGlass(&c, glass)
        c.fill(Path(roundedRect: CGRect(x: cx - 9, y: 30, width: 18, height: 12), cornerRadius: 3), with: .color(Color(red: 0.7, green: 0.5, blue: 0.3)))

        // Tap and outflow into the beaker
        let handle = tapOpen * Double.pi / 2
        let hx = CGFloat(cos(handle)) * 12
        let hy = CGFloat(sin(handle)) * 12
        LabDraw.segment(&c, CGPoint(x: cx - hx, y: 214 - hy), CGPoint(x: cx + hx, y: 214 + hy), Color.primary.opacity(0.75), 4)
        LabDraw.dot(&c, cx, 214, 4, Color.gray)

        let beaker = LabDraw.beakerPath(left: cx - 40, right: cx + 40, top: 262, bottom: 296, corner: 8)
        let beakerSurface = 294 - 30 * CGFloat(drainP)
        if tapOpen > 0.4 {
            LabDraw.segment(&c, CGPoint(x: cx, y: 232), CGPoint(x: cx, y: beakerSurface), LabDraw.waterTint.opacity(0.85), 3)
        }
        c.drawLayer { l in
            l.clip(to: beaker)
            if drainP > 0.01 {
                let pool = LabDraw.liquidPath(x0: cx - 50, x1: cx + 50, surface: beakerSurface, bottom: 300, amp: 0.8, phase: t * 2.2)
                l.fill(pool, with: .color(LabDraw.waterTint.opacity(0.42)))
            }
        }
        LabDraw.strokeGlass(&c, beaker)

        LabDraw.label(&c, "Upper layer (oil)", CGPoint(x: cx + 58, y: (oilTop + interface) / 2), size: 9, weight: .medium, color: Color.secondary, anchor: .leading)
        if waterH > 14 {
            LabDraw.label(&c, "Lower layer (water)", CGPoint(x: cx + 58, y: (interface + 232) / 2), size: 9, weight: .medium, color: Color.secondary, anchor: .leading)
        }
        LabDraw.label(&c, "Collect the lower layer, then close the tap", CGPoint(x: 180, y: 314), size: 9.5, weight: .medium)
    }

    private static func distillationPanel(_ c: inout GraphicsContext, t: Double, q: Double) {
        LabDraw.label(&c, "Distillation: boil, then condense the vapour", CGPoint(x: 180, y: 16), size: 11, weight: .bold)
        let boil = LabMath.smoothstep(q / 0.12) * (1 - LabMath.smoothstep((q - 0.9) / 0.1))
        let collected = LabMath.smoothstep((q - 0.15) / 0.75)
        let fx: CGFloat = 84
        let rx: CGFloat = 292

        // Burner
        c.fill(Path(roundedRect: CGRect(x: fx - 22, y: 286, width: 44, height: 10), cornerRadius: 3), with: .color(Color(white: 0.3)))
        c.fill(Path(roundedRect: CGRect(x: fx - 4, y: 252, width: 8, height: 34), cornerRadius: 2), with: .color(Color(white: 0.4)))
        LabDraw.flame(&c, x: fx, y: 252, height: 34 * CGFloat(boil), width: 14, t: t, seed: 9, blue: true)

        // Boiling flask
        let body = CGRect(x: fx - 38, y: 172, width: 76, height: 76)
        let bodyPath = Path(ellipseIn: body)
        let liquidSurface = 214 + 22 * CGFloat(collected)
        c.drawLayer { l in
            l.clip(to: bodyPath)
            let liquid = LabDraw.liquidPath(x0: fx - 44, x1: fx + 44, surface: liquidSurface, bottom: 252, amp: (0.8 + 1.2 * boil).cg, phase: t * 2.6)
            l.fill(liquid, with: .color(LabDraw.waterTint.opacity(0.36)))
            LabDraw.bubbleStream(&l, t: t, count: 22, intensity: boil, x0: fx - 26, x1: fx + 26, yStart: 240, yEnd: liquidSurface, speed: 80, radius: 2.8, salt: 3)
        }
        c.stroke(bodyPath, with: .color(Color.primary.opacity(0.55)), lineWidth: 1.8)
        LabDraw.segment(&c, CGPoint(x: fx - 8, y: 126), CGPoint(x: fx - 8, y: 172), Color.primary.opacity(0.55), 1.8)
        LabDraw.segment(&c, CGPoint(x: fx + 8, y: 126), CGPoint(x: fx + 8, y: 172), Color.primary.opacity(0.55), 1.8)
        c.fill(Path(CGRect(x: fx - 7, y: 168, width: 14, height: 8)), with: .color(Color(.systemBackground)))

        // Condenser with cooling-water jacket
        let condenser: [CGPoint] = [CGPoint(x: 120, y: 126), CGPoint(x: 288, y: 214)]
        c.stroke(LabDraw.polyline(condenser), with: .color(LabDraw.waterTint.opacity(0.18)), style: StrokeStyle(lineWidth: 18, lineCap: .butt))
        LabDraw.glassTube(&c, condenser, width: 5)
        LabDraw.glassTube(&c, [CGPoint(x: fx, y: 168), CGPoint(x: fx, y: 126), CGPoint(x: 120, y: 126)], width: 5)
        for k in 0..<8 {
            let f = 1 - LabMath.fract(t * 0.4 + Double(k) / 8)
            let pt = LabDraw.point(on: condenser, at: f)
            LabDraw.dot(&c, pt.x - 2.8, pt.y + 5.3, 2, LabDraw.waterTint.opacity(0.7))
        }

        // Vapour travelling to the condenser
        let vapourPath: [CGPoint] = [CGPoint(x: fx, y: 168), CGPoint(x: fx, y: 126), CGPoint(x: 120, y: 126), CGPoint(x: 288, y: 214)]
        if boil > 0.05 {
            for k in 0..<10 {
                let f = LabMath.fract(t * 0.5 + Double(k) / 10)
                let pt = LabDraw.point(on: vapourPath, at: f)
                LabDraw.dot(&c, pt.x, pt.y, 1.7, Color.gray.opacity(0.7 * boil))
            }
        }

        // Receiving flask
        let receiver = LabDraw.flaskPath(cx: rx, top: 232, shoulder: 252, base: 296, neckHalf: 9, baseHalf: 40)
        let receiverSurface = 292 - 24 * CGFloat(collected)
        c.drawLayer { l in
            l.clip(to: receiver)
            if collected > 0.02 {
                let pool = LabDraw.liquidPath(x0: rx - 50, x1: rx + 50, surface: receiverSurface, bottom: 300, amp: 0.7, phase: t * 2)
                l.fill(pool, with: .color(LabDraw.waterTint.opacity(0.34)))
            }
        }
        LabDraw.strokeGlass(&c, receiver)
        if boil > 0.3 {
            let ph = LabMath.fract(t * (0.5 + 1.5 * boil))
            let dropY = 218 + (receiverSurface - 218) * (ph * ph).cg
            LabDraw.dot(&c, 290, dropY, 2.2, LabDraw.waterTint.opacity(0.9))
        }

        LabDraw.label(&c, "Flask + heat", CGPoint(x: fx, y: 312), size: 9.5, weight: .medium)
        LabDraw.label(&c, "Distillate", CGPoint(x: rx, y: 312), size: 9.5, weight: .medium)
    }

    // MARK: - Solubility & crystallisation

    static func solubility(_ c: inout GraphicsContext, _ m: ChemistryLabViewModel) {
        let mo = m.motion
        let t = mo.ambient
        let p = mo.tween("sol", to: Double(m.solubilityStep), duration: 3.0)
        let mass = m.solubilityDissolvedMass
        let coolTemp = m.solubilityCoolingTemp
        let dissolve = LabMath.smoothstep(p / 0.9)
        let concentrate = LabMath.smoothstep(p - 1.0)
        let coolP = LabMath.smoothstep(p - 2.0)

        var temp = 20.0
        if p <= 1 {
            temp = LabMath.mix(20, 80, LabMath.smoothstep(p))
        } else if p <= 2 {
            temp = LabMath.mix(80, 92, concentrate)
        } else {
            temp = LabMath.mix(92, coolTemp, coolP)
        }
        let heat = mo.smooth("heatS", to: (p > 0.02 && p < 2.0) ? 1 : 0, rate: 4)
        let stir = mo.smooth("stirS", to: (p > 0.03 && p < 0.97) ? 1 : 0, rate: 5)
        let massFactor = 0.3 + 0.7 * LabMath.clamp01((mass - 2) / 13)
        let crystalAmt = LabMath.smoothstep((p - 2.0) / 0.9) * LabMath.smoothstep((85 - temp) / 50)
        let filt = mo.smooth("filt", to: (m.solubilityFiltered && m.solubilityStep >= 3) ? 1 : 0, rate: 2.5)
        let warmth = LabMath.clamp01((temp - 20) / 70)

        LabDraw.bench(&c)

        // Hot plate
        c.fill(Path(roundedRect: CGRect(x: 72, y: 286, width: 156, height: 10), cornerRadius: 3), with: .color(Color(white: 0.28)))
        c.fill(Path(roundedRect: CGRect(x: 80, y: 286, width: 140, height: 4), cornerRadius: 2), with: .color(Color.orange.opacity(0.75 * heat)))

        // Beaker of solution
        let left: CGFloat = 85
        let right: CGFloat = 215
        let bottom: CGFloat = 286
        let beaker = LabDraw.beakerPath(left: left, right: right, top: 116, bottom: bottom, corner: 14)
        let surface = 176 + 24 * CGFloat(concentrate)
        let grains = Int(mass * 4)
        let crystals = Int(crystalAmt * massFactor * 60)
        let sizeScale = 0.4 + 0.6 * crystalAmt
        c.drawLayer { l in
            l.clip(to: beaker)
            let liquid = LabDraw.liquidPath(x0: left - 6, x1: right + 6, surface: surface, bottom: bottom + 4, amp: (0.8 + 1.6 * stir).cg, phase: t * (2 + 4 * stir))
            l.fill(liquid, with: .color(Color.cyan.opacity(0.06 + 0.12 * dissolve)))
            l.fill(liquid, with: .color(Color(red: 0.55, green: 0.75, blue: 0.95).opacity(0.14)))
            l.fill(liquid, with: .color(Color.orange.opacity(0.10 * warmth)))
            if grains > 0 {
                for i in 0..<grains {
                    let gate = LabMath.hash(i, 101)
                    let alpha = 1 - LabMath.smoothstep((dissolve - gate * 0.8) / 0.2)
                    if alpha < 0.02 { continue }
                    let gx = left + 8 + (right - left - 16) * LabMath.hash(i, 102).cg
                    let gy = bottom - 6 - 14 * LabMath.hash(i, 103).cg
                    LabDraw.grain(&l, gx, gy, (1.5 + 1.6 * LabMath.hash(i, 104)).cg, alpha: alpha)
                }
            }
            if crystals > 0 {
                for i in 0..<crystals {
                    let cx = left + 8 + (right - left - 16) * LabMath.hash(i, 111).cg
                    let cy = bottom - 8 - 26 * (LabMath.hash(i, 112) * LabMath.hash(i, 113)).cg
                    let r = (1.5 + 3.5 * LabMath.hash(i, 114)) * sizeScale
                    LabDraw.crystal(&l, cx, cy, r.cg, rotation: LabMath.hash(i, 115) * 3, alpha: 1 - filt)
                }
            }
        }
        LabDraw.strokeGlass(&c, beaker)
        LabDraw.shine(&c, x: left + 6, y: 128, height: 100)

        // Stirring rod
        if stir > 0.02 {
            let topX = 168 + CGFloat(sin(t * 5) * stir) * 3
            let botX = 150 + CGFloat(sin(t * 6) * stir) * 26
            var rod = Path()
            rod.move(to: CGPoint(x: topX, y: 66))
            rod.addLine(to: CGPoint(x: botX, y: 262))
            c.stroke(rod, with: .color(Color.primary.opacity(0.5 * stir)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        LabDraw.steam(&c, t: t, x0: 100, x1: 200, y: 110, height: 70, intensity: heat * LabMath.smoothstep((p - 0.4) / 0.5), salt: 12)

        // Watch glass with filtered crystals
        var dish = Path()
        dish.move(to: CGPoint(x: 240, y: 268))
        dish.addQuadCurve(to: CGPoint(x: 316, y: 268), control: CGPoint(x: 278, y: 296))
        let pile = Int(filt * massFactor * 40)
        if pile > 0 {
            for i in 0..<pile {
                let cx = 250 + 56 * LabMath.hash(i, 121).cg
                let cy = 274 - 6 * LabMath.hash(i, 122).cg
                LabDraw.crystal(&c, cx, cy, (2 + 2.4 * LabMath.hash(i, 123)).cg, rotation: LabMath.hash(i, 124) * 3, alpha: filt)
            }
        }
        LabDraw.strokeGlass(&c, dish, width: 2)
        LabDraw.steam(&c, t: t, x0: 250, x1: 306, y: 262, height: 34, intensity: filt * 0.6, salt: 9, count: 4)
        LabDraw.label(&c, "Filter paper + crystals (drying)", CGPoint(x: 278, y: 312), size: 9, weight: .medium, color: Color.primary.opacity(filt))

        // Stage caption and temperature badge
        let stageNames = ["Dissolve in hot water", "Concentrate the solution", "Cool slowly", "Filter, wash and dry"]
        let stepIndex = min(max(m.solubilityStep, 0), 3)
        LabDraw.label(&c, "Stage \(stepIndex + 1): \(stageNames[stepIndex])", CGPoint(x: 14, y: 22), size: 11, weight: .bold, anchor: .leading)
        let badge = CGRect(x: 250, y: 44, width: 96, height: 30)
        c.fill(Path(roundedRect: badge, cornerRadius: 8), with: .color(Color(.secondarySystemBackground)))
        LabDraw.label(&c, String(format: "%.0f °C", temp), CGPoint(x: badge.midX, y: badge.midY), size: 15, weight: .bold, design: .monospaced, color: Color.orange.opacity(0.5 + 0.5 * warmth))
        LabDraw.label(&c, "Solution temperature", CGPoint(x: badge.midX, y: badge.minY - 8), size: 9, weight: .medium, color: Color.secondary)
        LabDraw.label(&c, "Hot plate + beaker", CGPoint(x: 150, y: 312), size: 9.5, weight: .medium)
    }
}
