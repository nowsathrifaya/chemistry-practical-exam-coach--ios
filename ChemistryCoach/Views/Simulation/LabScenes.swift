//
//  LabScenes.swift
//  ChemistryCoach
//
//  Animated apparatus scenes for the eight practical labs. `render` is called
//  every frame from a TimelineView-driven Canvas: it advances `LabMotion`,
//  maps the fixed 360 × 330 design space onto the canvas, and dispatches to
//  the scene for the current experiment.
//
//  This file: dispatcher, acid–base titration, qualitative analysis.
//  Other scenes live in LabScenesGasAndCell / LabScenesMeasure / LabScenesProcess.
//

import SwiftUI

@MainActor
enum LabScenes {
    static func render(_ c: inout GraphicsContext, size: CGSize, model m: ChemistryLabViewModel, date: Date) {
        guard size.width > 1, size.height > 1 else { return }
        m.motion.tick(date)

        let full = CGRect(origin: .zero, size: size)
        c.fill(Path(roundedRect: full, cornerRadius: 18), with: .linearGradient(Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))

        let s = min(size.width / LabCanvas.width, size.height / LabCanvas.height)
        let ox = (size.width - LabCanvas.width * s) / 2
        let oy = (size.height - LabCanvas.height * s) / 2
        c.translateBy(x: ox, y: oy)
        c.scaleBy(x: s, y: s)

        switch m.type {
        case .titration: titration(&c, m)
        case .qualitativeAnalysis: qualitative(&c, m)
        case .rateReaction: rate(&c, m)
        case .electrolysis: electrolysis(&c, m)
        case .chromatography: chromatography(&c, m)
        case .energetics: energetics(&c, m)
        case .separation: separation(&c, m)
        case .solubility: solubility(&c, m)
        }
    }

    // MARK: - Titration

    static func titration(_ c: inout GraphicsContext, _ m: ChemistryLabViewModel) {
        let mo = m.motion
        let t = mo.ambient
        mo.observeTitrant(m.buretteReading)
        let reading = mo.smooth("burette", to: m.buretteReading, rate: 9)
        let pinkTarget = LabMath.smoothstep((m.flaskColourProgress - 0.12) / 0.8)
        let pink = mo.smooth("pink", to: pinkTarget, rate: 3.0)
        let swirl = max(0.14, mo.swirl)
        let bx: CGFloat = 128

        LabDraw.bench(&c)
        LabDraw.shadow(&c, x: bx, y: LabCanvas.bench, width: 118)

        // Burette
        let bTop: CGFloat = 30
        let bBottom: CGFloat = 170
        let pxPerMl = (bBottom - bTop) / 50
        let level = bTop + reading.cg * pxPerMl
        let naoh = Color(red: 0.40, green: 0.65, blue: 0.95).opacity(0.28)
        let tubeRect = CGRect(x: bx - 8, y: bTop - 10, width: 16, height: bBottom - bTop + 14)
        c.fill(Path(CGRect(x: bx - 7, y: level, width: 14, height: bBottom + 4 - level)), with: .color(naoh))
        let neckRect = CGRect(x: bx - 4, y: bBottom + 4, width: 8, height: 26)
        c.fill(Path(neckRect), with: .color(naoh))
        var tip = Path()
        tip.move(to: CGPoint(x: bx - 4, y: bBottom + 30))
        tip.addLine(to: CGPoint(x: bx + 4, y: bBottom + 30))
        tip.addLine(to: CGPoint(x: bx + 1, y: bBottom + 46))
        tip.addLine(to: CGPoint(x: bx - 1, y: bBottom + 46))
        tip.closeSubpath()
        c.fill(tip, with: .color(naoh))
        c.fill(Path(ellipseIn: CGRect(x: bx - 7, y: level - 2, width: 14, height: 4)), with: .color(Color.blue.opacity(0.35)))
        LabDraw.strokeGlass(&c, Path(roundedRect: tubeRect, cornerRadius: 3))
        LabDraw.strokeGlass(&c, Path(neckRect), width: 1.4)
        LabDraw.strokeGlass(&c, tip, width: 1.4)
        LabDraw.shine(&c, x: bx - 5.5, y: bTop, height: 90)

        for mL in 0...50 {
            let y = bTop + CGFloat(mL) * pxPerMl
            let len: CGFloat = mL % 10 == 0 ? 13 : (mL % 5 == 0 ? 9 : 5)
            let strength: Double = mL % 5 == 0 ? 0.7 : 0.35
            let weight: CGFloat = mL % 10 == 0 ? 1.2 : 0.7
            LabDraw.segment(&c, CGPoint(x: bx + 8, y: y), CGPoint(x: bx + 8 + len, y: y), Color.primary.opacity(strength), weight)
            if mL % 10 == 0 {
                LabDraw.label(&c, "\(mL)", CGPoint(x: bx + 32, y: y), size: 9, weight: .medium)
            }
        }

        // Stopcock: the handle turns while titrant is flowing
        let tapOpen = mo.smooth("tap", to: mo.tapIsOpen ? 1 : 0, rate: 22)
        let tapY = bBottom + 14
        let handleAngle = tapOpen * Double.pi / 2
        let hx = CGFloat(cos(handleAngle)) * 12
        let hy = CGFloat(sin(handleAngle)) * 12
        LabDraw.segment(&c, CGPoint(x: bx - hx, y: tapY - hy), CGPoint(x: bx + hx, y: tapY + hy), Color.primary.opacity(0.75), 4)
        LabDraw.dot(&c, bx, tapY, 5.5, Color.gray.opacity(0.9))

        // Falling drops and ripples
        let tipY = bBottom + 46
        let surfaceY: CGFloat = 276 - 6 * min(reading, 50).cg / 50
        let dropColour = Color(red: 0.40, green: 0.65, blue: 0.95).opacity(0.8)
        let fall = 0.30
        for d in mo.drops {
            let age = mo.t - d.birth
            if age < 0 { continue }
            if age < d.hang {
                let r = (1.0 + 2.6 * LabMath.smoothstep(age / d.hang)).cg
                LabDraw.dot(&c, bx, tipY + r * 0.6, r, dropColour)
            } else if age < d.hang + fall {
                let u = (age - d.hang) / fall
                let y = tipY + (surfaceY - tipY) * (u * u).cg
                let dropRect = CGRect(x: bx - 2.4, y: y - 3.4, width: 4.8, height: 6.8)
                c.fill(Path(ellipseIn: dropRect), with: .color(dropColour))
            } else {
                let a = age - d.hang - fall
                if a < 0.9 {
                    let rx = (4 + a * 40).cg
                    let ring = CGRect(x: bx - rx, y: surfaceY - rx * 0.12, width: rx * 2, height: rx * 0.24)
                    c.stroke(Path(ellipseIn: ring), with: .color(Color.primary.opacity(0.35 * (1 - a / 0.9))), lineWidth: 1)
                }
            }
        }

        // Conical flask: sloshes with the swirl, pink blooms where each drop lands
        let sw = t * (4 + swirl * 7)
        let dx = CGFloat(cos(sw) * (0.5 + 3.4 * swirl))
        let dy = CGFloat(sin(sw) * 0.5 * swirl)
        let flask = LabDraw.flaskPath(cx: bx, top: 224, shoulder: 246, base: 298, neckHalf: 9, baseHalf: 54)
        let dropsNow = mo.drops
        let clockNow = mo.t
        c.drawLayer { f in
            f.translateBy(x: dx, y: dy)
            f.drawLayer { l in
                l.clip(to: flask)
                let amp = (0.7 + 2.6 * swirl).cg
                let phase = t * (2 + swirl * 8)
                let liquid = LabDraw.liquidPath(x0: bx - 70, x1: bx + 70, surface: surfaceY, bottom: 304, amp: amp, phase: phase)
                l.fill(liquid, with: .color(Color(red: 0.72, green: 0.86, blue: 1.0).opacity(0.30)))
                l.fill(liquid, with: .color(Color(red: 1.0, green: 0.30, blue: 0.62).opacity(0.62 * pink)))
                for k in 0..<3 {
                    let ang = t * (3 + swirl * 8) + Double(k) * 2.1
                    let rx = 16 + 11 * CGFloat(k)
                    let cy = surfaceY + 8 + 7 * CGFloat(k)
                    let ox = CGFloat(cos(ang)) * 5
                    let ring = CGRect(x: bx - rx + ox, y: cy - 3.2, width: rx * 2, height: 6.4)
                    l.stroke(Path(ellipseIn: ring), with: .color(Color.primary.opacity(0.16 * swirl)), lineWidth: 1)
                }
                for d in dropsNow {
                    let a = clockNow - d.birth - d.hang - fall
                    if a < 0 { continue }
                    let life = (0.5 + 2.6 * pinkTarget) * (1 - 0.55 * swirl)
                    if a > life { continue }
                    let strength = (0.25 + 0.75 * pinkTarget) * (1 - a / life)
                    let r = (8 + a * 16).cg
                    let drift = CGFloat(sin(a * 3 + d.birth) * 6 * swirl)
                    let centre = CGPoint(x: bx + drift, y: surfaceY + 6 + (a * 5).cg)
                    let pinkColour = Color(red: 1.0, green: 0.25, blue: 0.6)
                    let blob = CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)
                    l.fill(Path(ellipseIn: blob), with: .radialGradient(Gradient(colors: [pinkColour.opacity(0.85 * strength), pinkColour.opacity(0)]), center: centre, startRadius: 0, endRadius: r))
                }
            }
            LabDraw.strokeGlass(&f, flask)
            LabDraw.shine(&f, x: bx - 8, y: 232, height: 10)
        }

        // Meniscus close-up
        let ix: CGFloat = 224
        let iy: CGFloat = 40
        let iw: CGFloat = 124
        let ih: CGFloat = 136
        let inset = CGRect(x: ix, y: iy, width: iw, height: ih)
        let insetShape = Path(roundedRect: inset, cornerRadius: 12)
        c.fill(insetShape, with: .color(Color(.secondarySystemBackground)))
        c.drawLayer { l in
            l.clip(to: insetShape)
            let zoom: CGFloat = 46
            let midY = inset.midY
            let tubeL = ix + 20
            let tubeR = ix + 64
            let edgeY = midY - 5
            let midX = (tubeL + tubeR) / 2
            var liquid = Path()
            liquid.move(to: CGPoint(x: tubeL, y: edgeY))
            liquid.addQuadCurve(to: CGPoint(x: tubeR, y: edgeY), control: CGPoint(x: midX, y: midY + 5))
            liquid.addLine(to: CGPoint(x: tubeR, y: iy + ih + 4))
            liquid.addLine(to: CGPoint(x: tubeL, y: iy + ih + 4))
            liquid.closeSubpath()
            l.fill(liquid, with: .color(Color.blue.opacity(0.22)))
            var meniscus = Path()
            meniscus.move(to: CGPoint(x: tubeL, y: edgeY))
            meniscus.addQuadCurve(to: CGPoint(x: tubeR, y: edgeY), control: CGPoint(x: midX, y: midY + 5))
            l.stroke(meniscus, with: .color(Color.primary.opacity(0.8)), lineWidth: 2)
            LabDraw.segment(&l, CGPoint(x: tubeL, y: iy), CGPoint(x: tubeL, y: iy + ih), Color.primary.opacity(0.5), 2)
            LabDraw.segment(&l, CGPoint(x: tubeR, y: iy), CGPoint(x: tubeR, y: iy + ih), Color.primary.opacity(0.5), 2)
            let first = Int(((reading - 1.8) * 10).rounded(.down))
            let last = Int(((reading + 1.8) * 10).rounded(.up))
            if first <= last {
                for k in first...last {
                    if k < 0 || k > 500 { continue }
                    let v = Double(k) / 10
                    let y = midY + CGFloat(v - reading) * zoom
                    if y < iy + 4 || y > iy + ih - 4 { continue }
                    let whole = k % 10 == 0
                    let half = k % 5 == 0
                    let len: CGFloat = whole ? 24 : (half ? 16 : 9)
                    LabDraw.segment(&l, CGPoint(x: tubeR, y: y), CGPoint(x: tubeR + len, y: y), Color.primary.opacity(whole ? 0.85 : 0.5), whole ? 1.3 : 0.8)
                    if whole {
                        LabDraw.label(&l, "\(k / 10)", CGPoint(x: tubeR + 36, y: y), size: 11, weight: .semibold)
                    }
                }
            }
            var arrow = Path()
            arrow.move(to: CGPoint(x: ix + 6, y: midY - 5))
            arrow.addLine(to: CGPoint(x: ix + 6, y: midY + 5))
            arrow.addLine(to: CGPoint(x: ix + 14, y: midY))
            arrow.closeSubpath()
            l.fill(arrow, with: .color(Color.accentColor))
        }
        c.stroke(insetShape, with: .color(Color.primary.opacity(0.22)), lineWidth: 1)
        LabDraw.label(&c, "Meniscus close-up", CGPoint(x: inset.midX, y: iy - 10), size: 10)

        let stateText = m.flaskColourProgress > 0.85 ? "PALE PINK ENDPOINT" : (m.flaskColourProgress > 0.35 ? "PINK DEVELOPING" : "COLOURLESS")
        let pill = CGRect(x: ix, y: iy + ih + 24, width: iw, height: 24)
        c.fill(Path(roundedRect: pill, cornerRadius: 12), with: .color(Color(red: 1.0, green: 0.3, blue: 0.62).opacity(0.08 + 0.3 * pink)))
        LabDraw.label(&c, stateText, CGPoint(x: pill.midX, y: pill.midY), size: 9.5, weight: .bold)
        LabDraw.label(&c, "Drag the flask to swirl", CGPoint(x: pill.midX, y: pill.maxY + 14), size: 9, weight: .regular, color: Color.secondary)

        LabDraw.label(&c, "Burette: NaOH", CGPoint(x: bx, y: 12), size: 10)
        LabDraw.label(&c, "Conical flask · HCl + phenolphthalein", CGPoint(x: bx, y: 314), size: 10)
    }

    // MARK: - Qualitative analysis

    static func qualitative(_ c: inout GraphicsContext, _ m: ChemistryLabViewModel) {
        let mo = m.motion
        let t = mo.ambient
        let reagent = m.qualitativeReagent
        var idx = -1
        if reagent == "Acidified silver nitrate" { idx = 0 }
        if reagent == "Lighted splint" { idx = 1 }
        if reagent == "Dilute acid + limewater" { idx = 2 }
        let presence = mo.smooth("reagent", to: (m.reagentBottleOpen && idx >= 0) ? 1 : 0, rate: 5)
        mo.track("dispense", m.reagentDispensed)
        let ageValue = mo.age("dispense")
        let started = ageValue != nil
        let a = ageValue ?? 0

        let xs: [CGFloat] = [58, 128, 198]
        let limeX: CGFloat = 300
        let mouthY: CGFloat = 128
        let bottomY: CGFloat = 280
        let hw: CGFloat = 17
        let baseSurface: CGFloat = 206

        // Reaction timelines (all zero until the reagent is dispensed)
        var cloud0 = 0.0
        var settle0 = 0.0
        var fizz1 = 0.0
        var popP = -1.0
        var fizz2 = 0.0
        var dissolve2 = 0.0
        var milk = 0.0
        var limeBubbles = 0.0
        if started && idx == 0 {
            cloud0 = LabMath.smoothstep((a - 0.35) / 1.4) * (1 - 0.65 * LabMath.smoothstep((a - 3.0) / 4.0))
            settle0 = LabMath.smoothstep((a - 1.8) / 5.0)
        }
        if started && idx == 1 {
            fizz1 = LabMath.smoothstep(a / 0.3) * (1 - LabMath.smoothstep((a - 1.0) / 0.4))
            popP = (a - 0.9) / 0.6
        }
        if started && idx == 2 {
            fizz2 = LabMath.smoothstep((a - 0.45) / 0.4) * (1 - LabMath.smoothstep((a - 6.5) / 2.5))
            dissolve2 = LabMath.smoothstep((a - 0.5) / 6.0)
            milk = LabMath.smoothstep((a - 2.2) / 4.5)
            limeBubbles = LabMath.smoothstep((a - 1.9) / 0.6) * (1 - LabMath.smoothstep((a - 8.0) / 3.0))
        }
        var shake: CGFloat = 0
        if popP >= 0 && popP < 0.6 {
            shake = CGFloat(sin(a * 90)) * 2.5 * CGFloat(1 - popP / 0.6)
        }
        let bungDrop = idx == 2 && started ? LabMath.smoothstep((a - 1.1) / 0.6) : 0.0

        LabDraw.bench(&c)

        // Test tubes
        for i in 0..<4 {
            let cx: CGFloat = i < 3 ? xs[i] : limeX
            let tube = LabDraw.tubePath(cx: cx, top: mouthY, bottom: bottomY, halfWidth: hw)
            var surface = baseSurface
            if i == idx && started {
                surface -= 5 * CGFloat(LabMath.smoothstep(a / 1.3))
            }
            let tubeShake: CGFloat = i == 1 ? shake : 0
            c.drawLayer { l in
                l.translateBy(x: tubeShake, y: 0)
                l.drawLayer { g in
                    g.clip(to: tube)
                    let waves = LabDraw.liquidPath(x0: cx - hw - 2, x1: cx + hw + 2, surface: surface, bottom: bottomY + 4, amp: 0.8, phase: t * 2 + Double(i))
                    switch i {
                    case 0:
                        g.fill(waves, with: .color(Color(red: 0.72, green: 0.86, blue: 1.0).opacity(0.22)))
                        if cloud0 > 0 {
                            g.fill(waves, with: .color(Color.gray.opacity(0.22 * cloud0)))
                            g.fill(waves, with: .color(Color(white: 0.97).opacity(0.7 * cloud0)))
                            for k in 0..<46 {
                                let appear = 0.35 + LabMath.hash(k, 1) * 1.8
                                if a < appear { continue }
                                let sink = 3.0 + LabMath.hash(k, 2) * 4.0
                                let prog = LabMath.smoothstep((a - appear) / sink)
                                let yStart = surface + 6 + LabMath.hash(k, 3).cg * 44
                                let yEnd = bottomY - 4 - LabMath.hash(k, 4).cg * 8
                                let wander = CGFloat(sin(a * 1.7 + LabMath.hash(k, 6) * 6.28)) * 3 * CGFloat(1 - prog)
                                let px = cx + (LabMath.hash(k, 5).cg - 0.5) * 26 + wander
                                let py = yStart + (yEnd - yStart) * prog.cg
                                let gr = 1.1 + LabMath.hash(k, 4).cg * 1.6
                                LabDraw.grain(&g, px, py, gr, alpha: min(1, (a - appear) * 3) * 0.9)
                            }
                        }
                        if settle0 > 0 {
                            let mound = CGRect(x: cx - 14, y: bottomY - 6 - 8 * CGFloat(settle0), width: 28, height: 6 + 8 * CGFloat(settle0))
                            g.fill(Path(ellipseIn: mound), with: .color(Color(white: 0.97)))
                            g.stroke(Path(ellipseIn: mound), with: .color(Color.gray.opacity(0.5)), lineWidth: 0.6)
                        }
                    case 1:
                        g.fill(waves, with: .color(Color(red: 0.85, green: 0.85, blue: 0.7).opacity(0.22)))
                        var strip = Path()
                        strip.move(to: CGPoint(x: cx - 9, y: bottomY - 4))
                        strip.addLine(to: CGPoint(x: cx - 3, y: bottomY - 44))
                        strip.addLine(to: CGPoint(x: cx + 1, y: bottomY - 42))
                        strip.addLine(to: CGPoint(x: cx - 4, y: bottomY - 2))
                        strip.closeSubpath()
                        g.fill(strip, with: .color(Color.gray.opacity(0.8)))
                        LabDraw.bubbleStream(&g, t: t, count: 16, intensity: fizz1, x0: cx - 12, x1: cx + 12, yStart: bottomY - 6, yEnd: surface, speed: 70, radius: 2.4, salt: 71)
                    case 2:
                        g.fill(waves, with: .color(Color(red: 0.72, green: 0.86, blue: 1.0).opacity(0.22)))
                        let powderH = 9 * CGFloat(1 - dissolve2)
                        if powderH > 0.3 {
                            let powder = CGRect(x: cx - 14, y: bottomY - 4 - powderH, width: 28, height: powderH + 4)
                            g.fill(Path(ellipseIn: powder), with: .color(Color(white: 0.97)))
                            g.stroke(Path(ellipseIn: powder), with: .color(Color.gray.opacity(0.5)), lineWidth: 0.6)
                        }
                        LabDraw.bubbleStream(&g, t: t, count: 30, intensity: fizz2, x0: cx - 12, x1: cx + 12, yStart: bottomY - 8, yEnd: surface, speed: 85, radius: 2.6, salt: 81)
                    default:
                        g.fill(waves, with: .color(Color(red: 0.72, green: 0.86, blue: 1.0).opacity(0.18)))
                        if milk > 0 {
                            g.fill(waves, with: .color(Color.gray.opacity(0.2 * milk)))
                            g.fill(waves, with: .color(Color(white: 0.97).opacity(0.75 * milk)))
                        }
                        LabDraw.bubbleStream(&g, t: t, count: 16, intensity: limeBubbles, x0: cx - 5, x1: cx + 5, yStart: 252, yEnd: surface, speed: 65, radius: 2.4, salt: 91)
                    }
                }
                LabDraw.strokeGlass(&l, tube)
                LabDraw.shine(&l, x: cx - hw + 3, y: mouthY + 8, height: 90)
            }
        }

        // Rack (drawn in front of the tubes)
        let rackColour = Color(red: 0.62, green: 0.45, blue: 0.28)
        c.fill(Path(roundedRect: CGRect(x: 28, y: 238, width: 304, height: 10), cornerRadius: 3), with: .color(rackColour.opacity(0.85)))
        c.fill(Path(roundedRect: CGRect(x: 28, y: 280, width: 304, height: 14), cornerRadius: 4), with: .color(rackColour))
        let names = ["Chloride", "Hydrogen", "Carbonate", "Limewater"]
        for i in 0..<4 {
            let cx: CGFloat = i < 3 ? xs[i] : limeX
            LabDraw.label(&c, names[i], CGPoint(x: cx, y: 312), size: 10, weight: i == idx ? .bold : .medium)
        }

        // Bung, delivery tube and CO2 flow for the carbonate test
        if idx == 2 && bungDrop > 0.001 {
            let lift = CGFloat(1 - bungDrop) * -46
            let tubePts: [CGPoint] = [CGPoint(x: xs[2], y: mouthY + lift - 2), CGPoint(x: xs[2], y: 96 + lift), CGPoint(x: limeX, y: 96 + lift), CGPoint(x: limeX, y: 252)]
            LabDraw.glassTube(&c, tubePts, width: 5)
            let bung = CGRect(x: xs[2] - 13, y: mouthY - 6 + lift, width: 26, height: 12)
            c.fill(Path(roundedRect: bung, cornerRadius: 3), with: .color(rackColour))
            let bung2 = CGRect(x: limeX - 13, y: mouthY - 6 + lift, width: 26, height: 12)
            c.fill(Path(roundedRect: bung2, cornerRadius: 3), with: .color(rackColour))
            if limeBubbles > 0.05 && bungDrop > 0.95 {
                for k in 0..<7 {
                    let f = LabMath.fract(t * 0.6 + Double(k) / 7)
                    let p = LabDraw.point(on: tubePts, at: f)
                    LabDraw.dot(&c, p.x, p.y, 1.8, Color.gray.opacity(0.7 * limeBubbles))
                }
            }
        }

        // Dropper bottle
        if idx == 0 || idx == 2 {
            let x = xs[idx]
            let tipY = LabMath.mixCG(-110, 100, LabMath.smoothstep(presence))
            var squeeze = 0.0
            let drops = idx == 0 ? 4 : 3
            if started {
                for k in 0..<drops {
                    let dtk = a - Double(k) * 0.32
                    if dtk >= 0 && dtk < 0.18 {
                        squeeze = max(squeeze, sin(dtk / 0.18 * Double.pi))
                    }
                }
            }
            drawDropperBottle(&c, x: x, tipY: tipY, squeeze: squeeze, name: idx == 0 ? "Acidified AgNO₃" : "Dilute acid")
            if started {
                let dropColour = Color(red: 0.55, green: 0.7, blue: 0.95).opacity(0.85)
                for k in 0..<drops {
                    let dtk = a - Double(k) * 0.32
                    if dtk < 0 { continue }
                    let fall = 0.30
                    if dtk < fall {
                        let u = dtk / fall
                        let y = tipY + (baseSurface - 5 - tipY) * (u * u).cg
                        c.fill(Path(ellipseIn: CGRect(x: x - 2.2, y: y - 3, width: 4.4, height: 6.4)), with: .color(dropColour))
                    } else if dtk < fall + 0.8 {
                        let r = dtk - fall
                        let rx = (3 + r * 22).cg
                        let ring = CGRect(x: x - rx, y: baseSurface - 5 - rx * 0.12, width: rx * 2, height: rx * 0.24)
                        c.stroke(Path(ellipseIn: ring), with: .color(Color.primary.opacity(0.4 * (1 - r / 0.8))), lineWidth: 1)
                    }
                }
            }
        }

        // Lighted splint for the hydrogen test
        if idx == 1 {
            let mouthX = xs[1] + 4
            let restP = CGPoint(x: 178, y: 84)
            let mouthP = CGPoint(x: mouthX, y: mouthY - 12)
            var approach = 0.0
            if started {
                approach = LabMath.smoothstep(a / 0.9) - LabMath.smoothstep((a - 1.6) / 0.8)
            }
            let tipX = LabMath.mixCG(restP.x, mouthP.x, approach)
            let tipYs = LabMath.mixCG(restP.y, mouthP.y, approach)
            var flameScale = presence
            if started && popP >= 0 {
                flameScale = 0
            }
            var stick = Path()
            stick.move(to: CGPoint(x: tipX, y: tipYs))
            stick.addLine(to: CGPoint(x: tipX + 62, y: tipYs - 18))
            c.stroke(stick, with: .color(Color(red: 0.78, green: 0.6, blue: 0.35).opacity(presence)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            LabDraw.dot(&c, tipX, tipYs, 2.6, Color(red: 0.2, green: 0.1, blue: 0.05).opacity(presence))
            LabDraw.flame(&c, x: tipX, y: tipYs - 1, height: 22 * CGFloat(flameScale), width: 10, t: t, seed: 3)
            if started && popP >= 0 && popP < 1 {
                let ringR = (10 + 60 * popP).cg
                let centre = CGPoint(x: mouthX, y: mouthY - 6)
                let burst = CGRect(x: centre.x - ringR, y: centre.y - ringR, width: ringR * 2, height: ringR * 2)
                c.fill(Path(ellipseIn: burst), with: .radialGradient(Gradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.6).opacity(0.9 * (1 - popP) * (1 - popP)), Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0)]), center: centre, startRadius: 0, endRadius: ringR))
                c.stroke(Path(ellipseIn: burst), with: .color(Color.orange.opacity(0.6 * (1 - popP))), lineWidth: 1.5)
                LabDraw.label(&c, "POP!", CGPoint(x: mouthX + 34, y: mouthY - 30), size: 14, weight: .heavy, color: Color.orange.opacity(1 - popP))
            }
            if started && a > 1.0 && a < 4.0 {
                for k in 0..<5 {
                    let ph = LabMath.fract((a - 1.0) * 0.5 + Double(k) * 0.2)
                    let smokeX = tipX + CGFloat(sin(a * 2 + Double(k))) * 4
                    LabDraw.dot(&c, smokeX, tipYs - 4 - 26 * CGFloat(ph), 2 + 3 * CGFloat(ph), Color.gray.opacity(0.3 * (1 - ph)))
                }
            }
        }

        LabDraw.label(&c, "Test: \(m.qualitativeTestLabel)", CGPoint(x: 350, y: 18), size: 12, weight: .bold, anchor: .trailing)
    }

    private static func drawDropperBottle(_ c: inout GraphicsContext, x: CGFloat, tipY: CGFloat, squeeze: Double, name: String) {
        var pipette = Path()
        pipette.move(to: CGPoint(x: x - 2.5, y: tipY - 26))
        pipette.addLine(to: CGPoint(x: x + 2.5, y: tipY - 26))
        pipette.addLine(to: CGPoint(x: x + 0.8, y: tipY))
        pipette.addLine(to: CGPoint(x: x - 0.8, y: tipY))
        pipette.closeSubpath()
        c.fill(pipette, with: .color(Color.primary.opacity(0.25)))
        LabDraw.strokeGlass(&c, pipette, width: 1)
        let body = CGRect(x: x - 15, y: tipY - 70, width: 30, height: 44)
        c.fill(Path(roundedRect: body, cornerRadius: 6), with: .color(Color(red: 0.65, green: 0.4, blue: 0.12).opacity(0.88)))
        let tag = CGRect(x: x - 11, y: tipY - 60, width: 22, height: 20)
        c.fill(Path(roundedRect: tag, cornerRadius: 3), with: .color(Color.white.opacity(0.92)))
        let neck = CGRect(x: x - 6, y: tipY - 78, width: 12, height: 8)
        c.fill(Path(roundedRect: neck, cornerRadius: 2), with: .color(Color(white: 0.25)))
        let teatH = 16 * (1 - 0.35 * CGFloat(squeeze))
        let teat = CGRect(x: x - 7, y: tipY - 78 - teatH, width: 14, height: teatH)
        c.fill(Path(roundedRect: teat, cornerRadius: 6), with: .color(Color(white: 0.15)))
        LabDraw.label(&c, name, CGPoint(x: x + 20, y: tipY - 48), size: 9, weight: .medium, color: Color.secondary, anchor: .leading)
    }
}
