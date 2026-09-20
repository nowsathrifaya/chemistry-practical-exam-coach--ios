//
//  LabDraw.swift
//  ChemistryCoach
//
//  Reusable Canvas drawing helpers for the virtual labs: glassware outlines,
//  wavy liquid surfaces, procedural bubble streams, flames, steam and crystals.
//
//  Everything that moves is a pure function of time (`t`) and a per-item hash,
//  so scenes stay stateless and deterministic from frame to frame.
//

import SwiftUI

enum LabDraw {
    // MARK: Colours

    static var waterTint: Color { Color(red: 0.38, green: 0.64, blue: 0.95) }

    // MARK: Primitives

    static func label(_ c: inout GraphicsContext, _ text: String, _ p: CGPoint, size: CGFloat = 11, weight: Font.Weight = .semibold, design: Font.Design = .default, color: Color = Color.primary, anchor: UnitPoint = .center) {
        c.draw(Text(text).font(.system(size: size, weight: weight, design: design)).foregroundStyle(color), at: p, anchor: anchor)
    }

    static func dot(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ color: Color) {
        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
        c.fill(Path(ellipseIn: rect), with: .color(color))
    }

    static func segment(_ c: inout GraphicsContext, _ a: CGPoint, _ b: CGPoint, _ color: Color, _ width: CGFloat = 1) {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        c.stroke(p, with: .color(color), lineWidth: width)
    }

    static func polyline(_ pts: [CGPoint]) -> Path {
        var p = Path()
        for (i, pt) in pts.enumerated() {
            if i == 0 {
                p.move(to: pt)
            } else {
                p.addLine(to: pt)
            }
        }
        return p
    }

    /// Point at fraction `f` (0…1) of the total length of a polyline.
    static func point(on pts: [CGPoint], at f: Double) -> CGPoint {
        guard pts.count > 1 else { return pts.first ?? .zero }
        var total: CGFloat = 0
        for i in 1..<pts.count {
            total += hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)
        }
        var remaining = total * CGFloat(min(max(f, 0), 1))
        for i in 1..<pts.count {
            let seg = hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)
            if remaining <= seg {
                let u = seg > 0 ? remaining / seg : 0
                return CGPoint(x: pts[i - 1].x + (pts[i].x - pts[i - 1].x) * u, y: pts[i - 1].y + (pts[i].y - pts[i - 1].y) * u)
            }
            remaining -= seg
        }
        return pts[pts.count - 1]
    }

    // MARK: Bench

    static func bench(_ c: inout GraphicsContext) {
        let top = LabCanvas.bench
        let strip = CGRect(x: -600, y: top, width: LabCanvas.width + 1200, height: LabCanvas.height - top + 400)
        c.fill(Path(strip), with: .linearGradient(Gradient(colors: [Color.primary.opacity(0.10), Color.primary.opacity(0.03)]), startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: top + 40)))
        segment(&c, CGPoint(x: -600, y: top), CGPoint(x: 1000, y: top), Color.primary.opacity(0.22), 1.5)
    }

    static func shadow(_ c: inout GraphicsContext, x: CGFloat, y: CGFloat, width: CGFloat) {
        let rect = CGRect(x: x - width / 2, y: y - 3, width: width, height: 8)
        c.fill(Path(ellipseIn: rect), with: .color(Color.black.opacity(0.10)))
    }

    // MARK: Glassware paths

    static func tubePath(cx: CGFloat, top: CGFloat, bottom: CGFloat, halfWidth hw: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: cx - hw, y: top))
        p.addLine(to: CGPoint(x: cx - hw, y: bottom - hw))
        p.addCurve(to: CGPoint(x: cx + hw, y: bottom - hw), control1: CGPoint(x: cx - hw, y: bottom + hw * 0.33), control2: CGPoint(x: cx + hw, y: bottom + hw * 0.33))
        p.addLine(to: CGPoint(x: cx + hw, y: top))
        return p
    }

    /// A tube that is closed (rounded) at the top and open at the bottom, e.g. an inverted measuring cylinder.
    static func invertedTubePath(cx: CGFloat, top: CGFloat, bottom: CGFloat, halfWidth hw: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: cx - hw, y: bottom))
        p.addLine(to: CGPoint(x: cx - hw, y: top + hw))
        p.addCurve(to: CGPoint(x: cx + hw, y: top + hw), control1: CGPoint(x: cx - hw, y: top - hw * 0.33), control2: CGPoint(x: cx + hw, y: top - hw * 0.33))
        p.addLine(to: CGPoint(x: cx + hw, y: bottom))
        return p
    }

    static func beakerPath(left: CGFloat, right: CGFloat, top: CGFloat, bottom: CGFloat, corner: CGFloat = 12) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: left - 3, y: top - 3))
        p.addLine(to: CGPoint(x: left, y: top))
        p.addLine(to: CGPoint(x: left, y: bottom - corner))
        p.addQuadCurve(to: CGPoint(x: left + corner, y: bottom), control: CGPoint(x: left, y: bottom))
        p.addLine(to: CGPoint(x: right - corner, y: bottom))
        p.addQuadCurve(to: CGPoint(x: right, y: bottom - corner), control: CGPoint(x: right, y: bottom))
        p.addLine(to: CGPoint(x: right, y: top))
        p.addLine(to: CGPoint(x: right + 3, y: top - 3))
        return p
    }

    /// Conical (Erlenmeyer) flask outline, open at the top.
    static func flaskPath(cx: CGFloat, top: CGFloat, shoulder: CGFloat, base: CGFloat, neckHalf: CGFloat, baseHalf: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: cx - neckHalf - 3, y: top))
        p.addLine(to: CGPoint(x: cx - neckHalf, y: top + 4))
        p.addLine(to: CGPoint(x: cx - neckHalf, y: shoulder))
        p.addLine(to: CGPoint(x: cx - baseHalf + 8, y: base - 10))
        p.addQuadCurve(to: CGPoint(x: cx - baseHalf + 18, y: base), control: CGPoint(x: cx - baseHalf, y: base))
        p.addLine(to: CGPoint(x: cx + baseHalf - 18, y: base))
        p.addQuadCurve(to: CGPoint(x: cx + baseHalf - 8, y: base - 10), control: CGPoint(x: cx + baseHalf, y: base))
        p.addLine(to: CGPoint(x: cx + neckHalf, y: shoulder))
        p.addLine(to: CGPoint(x: cx + neckHalf, y: top + 4))
        p.addLine(to: CGPoint(x: cx + neckHalf + 3, y: top))
        return p
    }

    /// Filled shape whose top edge is a travelling sine wave — the surface of a liquid.
    static func liquidPath(x0: CGFloat, x1: CGFloat, surface: CGFloat, bottom: CGFloat, amp: CGFloat, phase: Double, wavelength: CGFloat = 38) -> Path {
        var p = Path()
        let count = max(2, Int((x1 - x0) / 4))
        for i in 0...count {
            let x = x0 + (x1 - x0) * CGFloat(i) / CGFloat(count)
            let angle = Double(x) / Double(wavelength) * 2 * Double.pi + phase
            let y = surface + amp * CGFloat(sin(angle))
            if i == 0 {
                p.move(to: CGPoint(x: x, y: y))
            } else {
                p.addLine(to: CGPoint(x: x, y: y))
            }
        }
        p.addLine(to: CGPoint(x: x1, y: bottom))
        p.addLine(to: CGPoint(x: x0, y: bottom))
        p.closeSubpath()
        return p
    }

    // MARK: Glass finishing

    static func strokeGlass(_ c: inout GraphicsContext, _ path: Path, width: CGFloat = 1.8) {
        c.stroke(path, with: .color(Color.primary.opacity(0.55)), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    static func shine(_ c: inout GraphicsContext, x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat = 3) {
        let rect = CGRect(x: x, y: y, width: width, height: height)
        c.fill(Path(roundedRect: rect, cornerRadius: width / 2), with: .color(Color.white.opacity(0.55)))
    }

    /// A hollow glass tube following a polyline (delivery tubes, condensers).
    static func glassTube(_ c: inout GraphicsContext, _ pts: [CGPoint], width: CGFloat = 5.5) {
        let path = polyline(pts)
        let style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        let inner = StrokeStyle(lineWidth: width - 2.4, lineCap: .round, lineJoin: .round)
        c.stroke(path, with: .color(Color.primary.opacity(0.45)), style: style)
        c.stroke(path, with: .color(Color(.systemBackground)), style: inner)
    }

    // MARK: Particles

    static func bubble(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, alpha: Double = 1, tint: Color = Color.white, fill: Double = 0.28) {
        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
        c.fill(Path(ellipseIn: rect), with: .color(tint.opacity(fill * alpha)))
        c.stroke(Path(ellipseIn: rect), with: .color(Color.primary.opacity(0.38 * alpha)), lineWidth: 0.8)
        dot(&c, x - r * 0.35, y - r * 0.35, max(r * 0.28, 0.4), Color.white.opacity(0.8 * alpha))
    }

    /// A field of bubbles rising from `yStart` to `yEnd`. `intensity` (0…1) controls how many are visible;
    /// bubbles fade in and out as it changes so the stream never pops.
    static func bubbleStream(_ c: inout GraphicsContext, t: Double, count: Int, intensity: Double, x0: CGFloat, x1: CGFloat, yStart: CGFloat, yEnd: CGFloat, speed: Double = 60, radius: CGFloat = 3, salt: Int = 0, tint: Color = Color.white, fill: Double = 0.28, wobble: CGFloat = 2.5) {
        guard intensity > 0.01, yStart > yEnd else { return }
        let travel = Double(yStart - yEnd)
        for i in 0..<count {
            let gate = LabMath.hash(i, salt + 11)
            let visible = LabMath.smoothstep((intensity - gate) * 5)
            if visible <= 0.01 { continue }
            let pace = speed * (0.7 + 0.6 * LabMath.hash(i, salt + 3))
            let phase = LabMath.fract(t * pace / travel + LabMath.hash(i, salt + 1))
            let px = x0 + (x1 - x0) * LabMath.hash(i, salt + 5).cg
            let sway = wobble * CGFloat(sin(t * 3 + LabMath.hash(i, salt + 7) * 6.28))
            let y = yStart - (yStart - yEnd) * phase.cg
            let edge = min(phase * 10, (1 - phase) * 10, 1)
            let grow = 0.7 + 0.5 * phase
            let size = radius * (0.55 + 0.7 * LabMath.hash(i, salt + 9)).cg * grow.cg
            bubble(&c, px + sway, y, size, alpha: visible * edge, tint: tint, fill: fill)
        }
    }

    /// Soft grey puffs drifting upwards.
    static func steam(_ c: inout GraphicsContext, t: Double, x0: CGFloat, x1: CGFloat, y: CGFloat, height: CGFloat, intensity: Double, salt: Int = 0, count: Int = 7) {
        guard intensity > 0.02 else { return }
        for i in 0..<count {
            let phase = LabMath.fract(t * 0.32 + LabMath.hash(i, salt + 2))
            let drift = CGFloat(sin(t * 1.6 + Double(i))) * 5
            let px = x0 + (x1 - x0) * LabMath.hash(i, salt + 4).cg + drift
            let py = y - height * phase.cg
            let r = 4 + 9 * phase
            let a = sin(phase * Double.pi) * 0.22 * intensity
            dot(&c, px, py, r.cg, Color.gray.opacity(a))
        }
    }

    /// Small pale grain (undissolved solid, precipitate, salt crystal seen from afar).
    static func grain(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, alpha: Double = 1) {
        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
        c.fill(Path(ellipseIn: rect), with: .color(Color(white: 0.97).opacity(alpha)))
        c.stroke(Path(ellipseIn: rect), with: .color(Color.gray.opacity(0.55 * alpha)), lineWidth: 0.6)
    }

    /// A little faceted crystal.
    static func crystal(_ c: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, rotation: Double, alpha: Double = 1) {
        var p = Path()
        for k in 0..<4 {
            let ang = rotation + Double(k) * Double.pi / 2
            let px = x + r * CGFloat(cos(ang))
            let py = y + r * CGFloat(sin(ang)) * 1.15
            if k == 0 {
                p.move(to: CGPoint(x: px, y: py))
            } else {
                p.addLine(to: CGPoint(x: px, y: py))
            }
        }
        p.closeSubpath()
        c.fill(p, with: .color(Color(red: 0.86, green: 0.94, blue: 1.0).opacity(0.95 * alpha)))
        c.stroke(p, with: .color(Color(red: 0.35, green: 0.5, blue: 0.75).opacity(0.75 * alpha)), lineWidth: 0.7)
    }

    // MARK: Flame

    static func flame(_ c: inout GraphicsContext, x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat, t: Double, seed: Int = 0, blue: Bool = false) {
        guard height > 0.5 else { return }
        let flick = CGFloat(sin(t * 17 + Double(seed)) * 0.5 + sin(t * 29 + Double(seed) * 2.1) * 0.5)
        let h = height * (1 + 0.08 * flick)
        let sway = flick * width * 0.18
        var p = Path()
        p.move(to: CGPoint(x: x - width / 2, y: y))
        p.addCurve(to: CGPoint(x: x + sway, y: y - h), control1: CGPoint(x: x - width * 0.7, y: y - h * 0.35), control2: CGPoint(x: x - width * 0.1 + sway, y: y - h * 0.65))
        p.addCurve(to: CGPoint(x: x + width / 2, y: y), control1: CGPoint(x: x + width * 0.1 + sway, y: y - h * 0.65), control2: CGPoint(x: x + width * 0.7, y: y - h * 0.35))
        p.closeSubpath()
        let colors: [Color] = blue
            ? [Color(red: 0.75, green: 0.9, blue: 1.0), Color(red: 0.25, green: 0.5, blue: 1.0)]
            : [Color(red: 1.0, green: 0.95, blue: 0.5), Color(red: 1.0, green: 0.5, blue: 0.1)]
        c.fill(p, with: .linearGradient(Gradient(colors: colors), startPoint: CGPoint(x: x, y: y - h), endPoint: CGPoint(x: x, y: y)))
    }
}
