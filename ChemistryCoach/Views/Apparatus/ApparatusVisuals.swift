import SwiftUI

struct ChemistryInstrumentView: View {
    let state: ApparatusVisualState
    let type: ApparatusType
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                drawBackground(&context, size: size)
                switch state {
                case .burette(let reading): drawBurette(&context, size: size, reading: reading)
                case .balance(let mass): drawBalance(&context, size: size, reading: mass)
                case .thermometer(let temp): drawThermometer(&context, size: size, reading: temp)
                case .measuringCylinder(let volume): drawCylinder(&context, size: size, reading: volume)
                case .gasSyringe(let volume): drawSyringe(&context, size: size, reading: volume)
                case .stopwatch(let seconds): drawStopwatch(&context, size: size, reading: seconds)
                case .pipette: drawPipette(&context, size: size)
                case .generic: break
                }
            }.accessibilityLabel("Interactive \(type.label) showing a reading")
        }
        .padding(12)
    }

    // MARK: - Shared helpers

    private func drawBackground(_ c: inout GraphicsContext, size: CGSize) {
        c.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 16),
               with: .linearGradient(Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground).opacity(0.5)]),
                                      startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
    }

    /// Soft contact shadow under an item resting on the bench.
    private func groundShadow(_ c: inout GraphicsContext, cx: CGFloat, y: CGFloat, width: CGFloat) {
        let rect = CGRect(x: cx - width / 2, y: y - 4, width: width, height: 8)
        c.fill(Path(ellipseIn: rect), with: .color(Color.black.opacity(0.14)))
    }

    /// Glassy fill for a tube-shaped path: pale gradient plus an outline stroke.
    private func glassFill(_ c: inout GraphicsContext, path: Path, in rect: CGRect) {
        c.fill(path, with: .linearGradient(Gradient(colors: [Color.white.opacity(0.55), Color(white: 0.85).opacity(0.28), Color.white.opacity(0.5)]),
                                            startPoint: CGPoint(x: rect.minX, y: rect.midY), endPoint: CGPoint(x: rect.maxX, y: rect.midY)))
        c.stroke(path, with: .color(Color.primary.opacity(0.55)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
    }

    /// A shallow curved meniscus line — dips down slightly in the middle for an aqueous liquid in glass.
    private func meniscus(_ c: inout GraphicsContext, y: CGFloat, x0: CGFloat, x1: CGFloat, dip: CGFloat, color: Color, lineWidth: CGFloat = 1.4) {
        var p = Path()
        p.move(to: CGPoint(x: x0, y: y))
        p.addQuadCurve(to: CGPoint(x: x1, y: y), control: CGPoint(x: (x0 + x1) / 2, y: y + dip))
        c.stroke(p, with: .color(color), lineWidth: lineWidth)
    }

    private func rulerPlaque(_ c: inout GraphicsContext, rect: CGRect) {
        c.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(Color.yellow.opacity(0.15)))
        c.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(Color.primary.opacity(0.22)), lineWidth: 1)
    }

    // MARK: - Burette (clamped on a retort stand)

    private func drawBurette(_ c: inout GraphicsContext, size: CGSize, reading: Double) {
        let x = size.width * 0.42
        let top = 22.0, bottom = size.height - 66, h = bottom - top
        let hw: CGFloat = 9

        // Retort stand: base, vertical rod and a boss-head clamp.
        let baseY = size.height - 20
        c.fill(Path(roundedRect: CGRect(x: 14, y: baseY - 4, width: 30, height: 8), cornerRadius: 2), with: .color(Color.gray.opacity(0.55)))
        LabDraw.segment(&c, CGPoint(x: 24, y: baseY), CGPoint(x: 24, y: top - 6), Color.gray.opacity(0.6), 4)
        LabDraw.segment(&c, CGPoint(x: 24, y: top + 14), CGPoint(x: x - hw - 1, y: top + 14), Color.gray.opacity(0.7), 6)
        c.fill(Path(roundedRect: CGRect(x: 18, y: top + 8, width: 12, height: 12), cornerRadius: 3), with: .color(Color.gray.opacity(0.8)))

        // Glass tube tapering into a stopcock, then a thin jet.
        var tube = Path()
        tube.move(to: CGPoint(x: x - hw, y: top))
        tube.addLine(to: CGPoint(x: x - hw, y: bottom - 26))
        tube.addLine(to: CGPoint(x: x - 3, y: bottom - 8))
        tube.addLine(to: CGPoint(x: x - 3, y: bottom))
        tube.addLine(to: CGPoint(x: x + 3, y: bottom))
        tube.addLine(to: CGPoint(x: x + 3, y: bottom - 8))
        tube.addLine(to: CGPoint(x: x + hw, y: bottom - 26))
        tube.addLine(to: CGPoint(x: x + hw, y: top))
        glassFill(&c, path: tube, in: CGRect(x: x - hw, y: top, width: hw * 2, height: h))

        // Liquid inside, from the top down to the reading level.
        let liquidTopY = top + 4
        let readingY = min(top + h * CGFloat(reading / 50), bottom - 27)
        var liquid = Path()
        liquid.move(to: CGPoint(x: x - hw + 1.5, y: liquidTopY))
        liquid.addLine(to: CGPoint(x: x - hw + 1.5, y: readingY))
        liquid.addLine(to: CGPoint(x: x + hw - 1.5, y: readingY))
        liquid.addLine(to: CGPoint(x: x + hw - 1.5, y: liquidTopY))
        liquid.closeSubpath()
        c.drawLayer { l in
            l.clip(to: tube)
            l.fill(liquid, with: .color(LabDraw.waterTint.opacity(0.32)))
            meniscus(&l, y: readingY, x0: x - hw + 1.5, x1: x + hw - 1.5, dip: 2.2, color: LabDraw.waterTint.opacity(0.85))
            LabDraw.shine(&l, x: x - hw + 2.5, y: top + 6, height: h - 40, width: 2)
        }

        // Stopcock handle at the base.
        c.stroke(Path(ellipseIn: CGRect(x: x - 7, y: bottom - 6, width: 14, height: 8)), with: .color(Color.primary.opacity(0.5)), lineWidth: 1.3)
        LabDraw.segment(&c, CGPoint(x: x - 10, y: bottom - 2), CGPoint(x: x + 10, y: bottom - 2), Color.primary.opacity(0.6), 2.2)
        LabDraw.dot(&c, x, bottom + 4, 1.6, LabDraw.waterTint.opacity(0.9))

        // Scale: major ticks every 5 cm³ (numbered), minor ticks every 1 cm³, on a plaque.
        rulerPlaque(&c, rect: CGRect(x: x + hw + 4, y: top - 4, width: 60, height: h + 8))
        for i in 0...10 {
            let y = top + h * CGFloat(i) / 10
            LabDraw.segment(&c, CGPoint(x: x + hw + 2, y: y), CGPoint(x: x + hw + 24, y: y), Color.primary.opacity(0.85), 1.1)
            LabDraw.label(&c, "\(i * 5)", CGPoint(x: x + hw + 40, y: y), size: 9.5, weight: .medium)
        }
        for i in 0...50 where i % 5 != 0 {
            let y = top + h * CGFloat(i) / 50
            LabDraw.segment(&c, CGPoint(x: x + hw + 2, y: y), CGPoint(x: x + hw + 12, y: y), Color.secondary.opacity(0.8), 0.6)
        }
        LabDraw.label(&c, "Burette · 0–50 cm³ (reads downward)", CGPoint(x: size.width / 2, y: size.height - 8), size: 11, weight: .semibold)
        groundShadow(&c, cx: 26, y: baseY + 4, width: 40)
    }

    // MARK: - Electronic balance

    private func drawBalance(_ c: inout GraphicsContext, size: CGSize, reading: Double) {
        let bodyRect = CGRect(x: size.width * 0.14, y: size.height * 0.5, width: size.width * 0.72, height: size.height * 0.32)
        let panRect = CGRect(x: size.width * 0.22, y: size.height * 0.36, width: size.width * 0.56, height: size.height * 0.2)
        groundShadow(&c, cx: bodyRect.midX, y: bodyRect.maxY + 6, width: bodyRect.width * 0.9)

        // Body (metallic gradient).
        c.fill(Path(roundedRect: bodyRect, cornerRadius: 14),
               with: .linearGradient(Gradient(colors: [Color(white: 0.86), Color(white: 0.68)]), startPoint: CGPoint(x: 0, y: bodyRect.minY), endPoint: CGPoint(x: 0, y: bodyRect.maxY)))
        c.stroke(Path(roundedRect: bodyRect, cornerRadius: 14), with: .color(Color.primary.opacity(0.35)), lineWidth: 1.2)

        // Weighing pan (draw before the display so the display sits "in front").
        c.fill(Path(ellipseIn: panRect), with: .linearGradient(Gradient(colors: [Color(white: 0.92), Color(white: 0.75)]), startPoint: CGPoint(x: 0, y: panRect.minY), endPoint: CGPoint(x: 0, y: panRect.maxY)))
        c.stroke(Path(ellipseIn: panRect), with: .color(Color.primary.opacity(0.4)), lineWidth: 1.1)
        c.stroke(Path(ellipseIn: panRect.insetBy(dx: panRect.width * 0.18, dy: panRect.height * 0.28)), with: .color(Color.primary.opacity(0.2)), lineWidth: 0.8)

        // Digital display bezel with LCD-style reading.
        let screen = CGRect(x: bodyRect.midX - 62, y: bodyRect.minY + 10, width: 124, height: 34)
        c.fill(Path(roundedRect: screen, cornerRadius: 5), with: .color(Color.black.opacity(0.9)))
        c.stroke(Path(roundedRect: screen, cornerRadius: 5), with: .color(Color.gray.opacity(0.7)), lineWidth: 1)
        c.draw(Text(String(format: "%.1f g", reading)).font(.system(size: 17, weight: .bold, design: .monospaced)).foregroundStyle(Color.green.opacity(0.95)), at: CGPoint(x: screen.midX, y: screen.midY))

        // Buttons.
        for (i, label) in ["ON", "TARE", "MODE"].enumerated() {
            let bx = bodyRect.minX + 20 + CGFloat(i) * 26
            let by = bodyRect.maxY - 14
            c.fill(Path(ellipseIn: CGRect(x: bx - 7, y: by - 7, width: 14, height: 14)), with: .color(Color(white: 0.55)))
            c.stroke(Path(ellipseIn: CGRect(x: bx - 7, y: by - 7, width: 14, height: 14)), with: .color(Color.primary.opacity(0.4)), lineWidth: 0.8)
            LabDraw.label(&c, label, CGPoint(x: bx, y: by + 13), size: 6.5, weight: .medium, color: .secondary)
        }
        LabDraw.label(&c, "Electronic balance", CGPoint(x: size.width / 2, y: size.height - 14), size: 11, weight: .semibold)
    }

    // MARK: - Thermometer

    private func drawThermometer(_ c: inout GraphicsContext, size: CGSize, reading: Double) {
        let x = size.width * 0.4
        let bulbY = size.height - 58
        let top: CGFloat = 30
        let tubeRect = CGRect(x: x - 9, y: top, width: 18, height: bulbY - top + 14)
        let tube = Path(roundedRect: tubeRect, cornerRadius: 9)
        glassFill(&c, path: tube, in: tubeRect)

        // Bulb.
        let bulbRect = CGRect(x: x - 15, y: bulbY, width: 30, height: 30)
        c.fill(Path(ellipseIn: bulbRect), with: .radialGradient(Gradient(colors: [Color.red.opacity(0.95), Color.red.opacity(0.65)]), center: CGPoint(x: bulbRect.midX - 4, y: bulbRect.midY - 4), startRadius: 1, endRadius: 20))
        c.stroke(Path(ellipseIn: bulbRect), with: .color(Color.primary.opacity(0.5)), lineWidth: 1.2)

        // Liquid column.
        let scaleTop = 0.0, scaleBottom = 100.0
        let fraction = max(0, min(1, (reading - scaleTop) / (scaleBottom - scaleTop)))
        let colRect = CGRect(x: x - 4, y: top + 6 + (tubeRect.height - 12) * (1 - fraction), width: 8, height: (tubeRect.height - 12) * fraction + 6)
        c.fill(Path(roundedRect: colRect, cornerRadius: 4), with: .color(Color.red.opacity(0.85)))
        c.drawLayer { l in
            LabDraw.shine(&l, x: x - 6, y: top + 4, height: tubeRect.height - 20, width: 2)
        }

        // Scale.
        rulerPlaque(&c, rect: CGRect(x: x + 16, y: top - 4, width: 62, height: tubeRect.height + 8))
        for t in stride(from: 0, through: 100, by: 10) {
            let y = top + 6 + (tubeRect.height - 12) * CGFloat(1 - Double(t) / 100)
            LabDraw.segment(&c, CGPoint(x: x + 14, y: y), CGPoint(x: x + 34, y: y), Color.primary.opacity(0.85), 1.1)
            LabDraw.label(&c, "\(t)", CGPoint(x: x + 52, y: y), size: 9.5, weight: .medium)
        }
        for t in stride(from: 0, through: 100, by: 2) where t % 10 != 0 {
            let y = top + 6 + (tubeRect.height - 12) * CGFloat(1 - Double(t) / 100)
            LabDraw.segment(&c, CGPoint(x: x + 14, y: y), CGPoint(x: x + 22, y: y), Color.secondary.opacity(0.8), 0.6)
        }
        LabDraw.label(&c, "Thermometer · 0–100 °C", CGPoint(x: size.width / 2, y: size.height - 10), size: 11, weight: .semibold)
        groundShadow(&c, cx: x, y: bulbY + 30, width: 40)
    }

    // MARK: - Measuring cylinder

    private func drawCylinder(_ c: inout GraphicsContext, size: CGSize, reading: Double) {
        let top: CGFloat = 26
        let bottom = size.height - 60
        let topHalf: CGFloat = size.width * 0.16
        let baseHalf: CGFloat = size.width * 0.135
        let cx = size.width * 0.36

        var body = Path()
        body.move(to: CGPoint(x: cx - topHalf - 5, y: top))
        body.addLine(to: CGPoint(x: cx - topHalf, y: top + 6))
        body.addLine(to: CGPoint(x: cx - baseHalf, y: bottom - 14))
        body.addLine(to: CGPoint(x: cx - baseHalf - 10, y: bottom))
        body.addLine(to: CGPoint(x: cx + baseHalf + 10, y: bottom))
        body.addLine(to: CGPoint(x: cx + baseHalf, y: bottom - 14))
        body.addLine(to: CGPoint(x: cx + topHalf, y: top + 6))
        body.addLine(to: CGPoint(x: cx + topHalf + 5, y: top))
        glassFill(&c, path: body, in: CGRect(x: cx - topHalf - 5, y: top, width: (topHalf + 5) * 2, height: bottom - top))

        // Liquid fill with a concave meniscus.
        let fillFraction = max(0, min(1, reading / 100))
        let liquidTopY = bottom - (bottom - (top + 8)) * CGFloat(fillFraction)
        let halfAtLiquid = baseHalf + (topHalf - baseHalf) * (bottom - liquidTopY) / (bottom - top)
        var liquid = Path()
        liquid.move(to: CGPoint(x: cx - halfAtLiquid + 2, y: liquidTopY))
        liquid.addLine(to: CGPoint(x: cx - baseHalf, y: bottom - 14))
        liquid.addLine(to: CGPoint(x: cx - baseHalf - 8, y: bottom - 2))
        liquid.addLine(to: CGPoint(x: cx + baseHalf + 8, y: bottom - 2))
        liquid.addLine(to: CGPoint(x: cx + baseHalf, y: bottom - 14))
        liquid.addLine(to: CGPoint(x: cx + halfAtLiquid - 2, y: liquidTopY))
        liquid.closeSubpath()
        c.drawLayer { l in
            l.clip(to: body)
            l.fill(liquid, with: .color(LabDraw.waterTint.opacity(0.34)))
            meniscus(&l, y: liquidTopY, x0: cx - halfAtLiquid + 2, x1: cx + halfAtLiquid - 2, dip: 3, color: LabDraw.waterTint.opacity(0.9))
            LabDraw.shine(&l, x: cx - topHalf - 1, y: top + 10, height: bottom - top - 40, width: 2.2)
        }

        // Graduations on the left, numbered every 20 cm³ with finer ticks every 5 cm³.
        rulerPlaque(&c, rect: CGRect(x: cx - topHalf - 62, y: top - 4, width: 56, height: bottom - top + 8))
        for i in stride(from: 0, through: 100, by: 20) {
            let y = top + 8 + (bottom - top - 16) * CGFloat(1 - Double(i) / 100)
            LabDraw.segment(&c, CGPoint(x: cx - topHalf - 22, y: y), CGPoint(x: cx - topHalf - 4, y: y), Color.primary.opacity(0.85), 1.1)
            LabDraw.label(&c, "\(i)", CGPoint(x: cx - topHalf - 40, y: y), size: 9.5, weight: .medium)
        }
        for i in stride(from: 0, through: 100, by: 5) where i % 20 != 0 {
            let y = top + 8 + (bottom - top - 16) * CGFloat(1 - Double(i) / 100)
            LabDraw.segment(&c, CGPoint(x: cx - topHalf - 12, y: y), CGPoint(x: cx - topHalf - 4, y: y), Color.secondary.opacity(0.8), 0.6)
        }
        LabDraw.label(&c, "Measuring cylinder · 0–100 cm³", CGPoint(x: size.width / 2, y: size.height - 10), size: 11, weight: .semibold)
        groundShadow(&c, cx: cx, y: bottom + 4, width: (baseHalf + 10) * 2 + 6)
    }

    // MARK: - Gas syringe

    private func drawSyringe(_ c: inout GraphicsContext, size: CGSize, reading: Double) {
        let r = CGRect(x: size.width * 0.2, y: size.height * 0.42, width: size.width * 0.58, height: 46)
        let frac = min(max(reading / 100, 0), 1)

        // Barrel.
        glassFill(&c, path: Path(roundedRect: r, cornerRadius: 8), in: r)
        // Gas fill (pale, since a gas syringe usually holds a colourless gas) up to the plunger.
        let gasRect = CGRect(x: r.minX + 5, y: r.minY + 5, width: (r.width - 10) * frac, height: r.height - 10)
        c.fill(Path(gasRect), with: .color(Color.yellow.opacity(0.10)))
        c.drawLayer { l in LabDraw.shine(&l, x: r.minX + 6, y: r.minY + 4, height: r.height - 8, width: 2) }

        // Barrel scale.
        for i in stride(from: 0, through: 100, by: 20) {
            let x = r.minX + r.width * CGFloat(Double(i) / 100)
            LabDraw.segment(&c, CGPoint(x: x, y: r.minY), CGPoint(x: x, y: r.minY - 10), Color.primary.opacity(0.85), 1.1)
            LabDraw.label(&c, "\(i)", CGPoint(x: x, y: r.minY - 18), size: 9)
        }
        for i in stride(from: 0, through: 100, by: 5) where i % 20 != 0 {
            let x = r.minX + r.width * CGFloat(Double(i) / 100)
            LabDraw.segment(&c, CGPoint(x: x, y: r.minY), CGPoint(x: x, y: r.minY - 5), Color.secondary.opacity(0.8), 0.6)
        }

        // Plunger: rod extending to the right, rubber-tipped seal, thumb rest.
        let plungerX = r.minX + (r.width - 12) * frac + 4
        c.fill(Path(roundedRect: CGRect(x: plungerX, y: r.minY - 3, width: 6, height: r.height + 6), cornerRadius: 3), with: .color(Color(white: 0.4)))
        LabDraw.segment(&c, CGPoint(x: plungerX + 3, y: r.midY), CGPoint(x: r.maxX + 30, y: r.midY), Color(white: 0.55), 5)
        c.fill(Path(roundedRect: CGRect(x: r.maxX + 26, y: r.midY - 16, width: 8, height: 32), cornerRadius: 4), with: .color(Color(white: 0.4)))

        // Nozzle + short delivery-tube stub on the left.
        c.fill(Path(roundedRect: CGRect(x: r.minX - 16, y: r.midY - 4, width: 16, height: 8), cornerRadius: 3), with: .color(Color.gray.opacity(0.7)))
        LabDraw.glassTube(&c, [CGPoint(x: r.minX - 16, y: r.midY), CGPoint(x: r.minX - 30, y: r.midY)], width: 4)

        LabDraw.label(&c, "Gas syringe · 0–100 cm³ barrel", CGPoint(x: size.width / 2, y: size.height - 14), size: 11, weight: .semibold)
        groundShadow(&c, cx: r.midX, y: r.maxY + 24, width: r.width + 20)
    }

    // MARK: - Stopwatch (analogue face, hands driven by the reading)

    private func drawStopwatch(_ c: inout GraphicsContext, size: CGSize, reading: Double) {
        let d = min(size.width, size.height) * 0.62
        let r = CGRect(x: (size.width - d) / 2, y: 26, width: d, height: d)
        groundShadow(&c, cx: r.midX, y: r.maxY + 10, width: d * 0.7)

        // Crown button.
        c.fill(Path(roundedRect: CGRect(x: r.midX - 6, y: r.minY - 14, width: 12, height: 14), cornerRadius: 3), with: .color(Color(white: 0.55)))

        // Case.
        c.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: [Color(white: 0.96), Color(white: 0.78)]), center: CGPoint(x: r.midX - d * 0.15, y: r.midY - d * 0.15), startRadius: 1, endRadius: d * 0.75))
        c.stroke(Path(ellipseIn: r), with: .color(Color.primary.opacity(0.45)), lineWidth: 2)
        let face = r.insetBy(dx: d * 0.08, dy: d * 0.08)
        c.fill(Path(ellipseIn: face), with: .color(Color.white.opacity(0.9)))
        c.stroke(Path(ellipseIn: face), with: .color(Color.primary.opacity(0.3)), lineWidth: 1)

        // Tick marks: 12 major (every 5s), 60 minor.
        for i in 0..<60 {
            let major = i % 5 == 0
            let angle = Double(i) / 60 * 2 * .pi - .pi / 2
            let outer = CGPoint(x: face.midX + cos(angle) * face.width / 2 * 0.94, y: face.midY + sin(angle) * face.height / 2 * 0.94)
            let inner = CGPoint(x: face.midX + cos(angle) * face.width / 2 * (major ? 0.80 : 0.88), y: face.midY + sin(angle) * face.height / 2 * (major ? 0.80 : 0.88))
            LabDraw.segment(&c, inner, outer, Color.primary.opacity(major ? 0.8 : 0.4), major ? 1.6 : 0.8)
            if major {
                let labelPt = CGPoint(x: face.midX + cos(angle) * face.width / 2 * 0.66, y: face.midY + sin(angle) * face.height / 2 * 0.66)
                LabDraw.label(&c, "\(i)", labelPt, size: 9, weight: .medium, color: .secondary)
            }
        }

        // Hands: second hand sweeps every 60 s; a slower minute-style sub-hand shows completed minutes.
        let secs = reading.truncatingRemainder(dividingBy: 60)
        let mins = (reading / 60).truncatingRemainder(dividingBy: 60)
        func hand(_ value: Double, length: CGFloat, width: CGFloat, color: Color) {
            let angle = value / 60 * 2 * .pi - .pi / 2
            let end = CGPoint(x: face.midX + cos(angle) * length, y: face.midY + sin(angle) * length)
            LabDraw.segment(&c, face.center, end, color, width)
        }
        hand(mins, length: face.width * 0.24, width: 2.2, color: .secondary)
        hand(secs, length: face.width * 0.36, width: 1.6, color: .red)
        LabDraw.dot(&c, face.midX, face.midY, 3, .primary)

        LabDraw.label(&c, String(format: "%.1f s", reading), CGPoint(x: size.width / 2, y: r.maxY + 22), size: 13, weight: .bold)
        LabDraw.label(&c, "Stopwatch", CGPoint(x: size.width / 2, y: size.height - 10), size: 11, weight: .semibold)
    }

    // MARK: - Volumetric (bulb) pipette

    private func drawPipette(_ c: inout GraphicsContext, size: CGSize) {
        let cx = size.width / 2
        let top: CGFloat = 24
        let tipY = size.height - 44
        let bulbCenterY = top + (tipY - top) * 0.32
        let bulbR: CGFloat = size.width * 0.14

        var glass = Path()
        glass.move(to: CGPoint(x: cx - 5, y: top))
        glass.addLine(to: CGPoint(x: cx + 5, y: top))
        glass.addLine(to: CGPoint(x: cx + 5, y: bulbCenterY - bulbR * 0.7))
        glass.addCurve(to: CGPoint(x: cx + bulbR, y: bulbCenterY), control1: CGPoint(x: cx + 5, y: bulbCenterY - bulbR * 0.2), control2: CGPoint(x: cx + bulbR, y: bulbCenterY - bulbR * 0.6))
        glass.addCurve(to: CGPoint(x: cx + 5, y: bulbCenterY + bulbR * 0.7), control1: CGPoint(x: cx + bulbR, y: bulbCenterY + bulbR * 0.6), control2: CGPoint(x: cx + 5, y: bulbCenterY + bulbR * 0.2))
        glass.addLine(to: CGPoint(x: cx + 5, y: tipY - 20))
        glass.addLine(to: CGPoint(x: cx + 1.5, y: tipY))
        glass.addLine(to: CGPoint(x: cx - 1.5, y: tipY))
        glass.addLine(to: CGPoint(x: cx - 5, y: tipY - 20))
        glass.addLine(to: CGPoint(x: cx - 5, y: bulbCenterY + bulbR * 0.7))
        glass.addCurve(to: CGPoint(x: cx - bulbR, y: bulbCenterY), control1: CGPoint(x: cx - 5, y: bulbCenterY + bulbR * 0.2), control2: CGPoint(x: cx - bulbR, y: bulbCenterY + bulbR * 0.6))
        glass.addCurve(to: CGPoint(x: cx - 5, y: bulbCenterY - bulbR * 0.7), control1: CGPoint(x: cx - bulbR, y: bulbCenterY - bulbR * 0.6), control2: CGPoint(x: cx - 5, y: bulbCenterY - bulbR * 0.2))
        glass.closeSubpath()
        glassFill(&c, path: glass, in: CGRect(x: cx - bulbR, y: top, width: bulbR * 2, height: tipY - top))

        // A thin film of liquid sitting in the bulb, as if just filled.
        c.drawLayer { l in
            l.clip(to: glass)
            let liquid = CGRect(x: cx - bulbR, y: bulbCenterY - 4, width: bulbR * 2, height: bulbR + 30)
            l.fill(Path(ellipseIn: liquid), with: .color(LabDraw.waterTint.opacity(0.3)))
            LabDraw.shine(&l, x: cx - bulbR * 0.5, y: bulbCenterY - bulbR * 0.5, height: bulbR, width: 2.2)
        }

        // Single graduation (fill-to-here) ring above the bulb, with the rated volume alongside.
        let markY = top + 16
        LabDraw.segment(&c, CGPoint(x: cx - 9, y: markY), CGPoint(x: cx + 9, y: markY), Color.primary.opacity(0.8), 1.6)
        LabDraw.label(&c, "25.0 cm³ mark", CGPoint(x: cx + 16, y: markY), size: 9.5, weight: .medium, anchor: .leading)

        LabDraw.label(&c, "25.0 cm³ volumetric pipette", CGPoint(x: size.width / 2, y: size.height - 12), size: 11, weight: .semibold)
        groundShadow(&c, cx: cx, y: tipY + 14, width: 30)
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
