//
//  LabMotion.swift
//  ChemistryCoach
//
//  Time-based animation engine shared by the eight virtual practical labs.
//
//  The lab view model publishes *state* (burette reading, reagent dispensed,
//  step index, ...). `LabMotion` turns that state into *motion*: it owns a
//  monotonic clock, eases displayed values towards their targets, plays
//  step transitions as timed tweens, and remembers when one-off events
//  (a drop leaving the burette, a reagent being added) started so the scenes
//  can render them as functions of elapsed time.
//
//  It is a plain reference type (not observable) that is advanced from inside
//  the `TimelineView` + `Canvas` draw pass, so it never triggers extra SwiftUI
//  updates by itself.
//

import SwiftUI

extension Double {
    /// Bridges animation values (Double) into drawing geometry (CGFloat).
    var cg: CGFloat { CGFloat(self) }
}

/// Every scene is authored in a fixed 360 × 330 design space and scaled to fit.
enum LabCanvas {
    static let width: CGFloat = 360
    static let height: CGFloat = 330
    static let bench: CGFloat = 296
}

enum LabMath {
    static func clamp01(_ v: Double) -> Double { min(max(v, 0), 1) }

    static func smoothstep(_ v: Double) -> Double {
        let x = clamp01(v)
        return x * x * (3 - 2 * x)
    }

    static func mix(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    static func mixCG(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat { a + (b - a) * CGFloat(t) }

    static func fract(_ v: Double) -> Double { v - v.rounded(.down) }

    /// Deterministic pseudo-random value in [0, 1) for index `i`.
    /// Used so that bubbles, grains and crystals sit in stable positions from frame to frame.
    static func hash(_ i: Int, _ salt: Int = 0) -> Double {
        let mixed = (i &* 73856093) &+ (salt &* 19349663) &+ 12345
        var x = UInt64(truncatingIfNeeded: mixed)
        x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9
        x = (x ^ (x >> 27)) &* 0x94D049BB133111EB
        x = x ^ (x >> 31)
        return Double(x >> 11) / 9007199254740992.0
    }
}

/// One drop of titrant leaving the burette tip.
struct LabDrop {
    let birth: Double
    /// Seconds the drop hangs and swells on the tip before it falls.
    let hang: Double
}

@MainActor
final class LabMotion {
    private(set) var t: Double = 0
    private(set) var dt: Double = 0
    /// When true, everything snaps to its end state and ambient motion is frozen.
    var reduceMotion = false
    /// 0…1 flask-swirl energy; kicked by dragging, decays on its own.
    var swirl: Double = 0
    /// Time (in `t`) until which the burette tap is drawn open.
    private(set) var flowUntil: Double = 0
    private(set) var drops: [LabDrop] = []

    private struct Tween {
        var from: Double
        var to: Double
        var start: Double
        var duration: Double
    }

    private var lastDate: Date?
    private var values: [String: Double] = [:]
    private var tweens: [String: Tween] = [:]
    private var marks: [String: Double] = [:]
    private var accumulators: [String: Double] = [:]
    private var lastReading: Double = 0

    /// Clock for continuous ambient motion (waves, flames, bubbles).
    var ambient: Double { reduceMotion ? 0 : t }

    var tapIsOpen: Bool { !reduceMotion && t < flowUntil }

    // MARK: Clock

    func tick(_ date: Date) {
        let now = date
        if let last = lastDate {
            dt = min(max(now.timeIntervalSince(last), 0), 0.1)
        } else {
            dt = 0
        }
        lastDate = now
        t += dt
        swirl = max(0, swirl - dt * 0.7)
    }

    func kickSwirl(_ amount: Double) {
        swirl = min(1, swirl + amount)
    }

    // MARK: Smoothed values

    /// Exponentially eases a displayed value towards `target`. First use snaps to the target.
    func smooth(_ key: String, to target: Double, rate: Double = 6) -> Double {
        if reduceMotion {
            values[key] = target
            return target
        }
        guard let current = values[key] else {
            values[key] = target
            return target
        }
        let k = 1 - exp(-rate * dt)
        let next = current + (target - current) * k
        values[key] = next
        return next
    }

    // MARK: Timed tweens (used for step transitions)

    /// Moves a value to `target` over `duration` seconds with ease-in-out.
    /// Decreasing targets (a reset) snap immediately instead of playing backwards.
    func tween(_ key: String, to target: Double, duration: Double = 2.6) -> Double {
        if reduceMotion {
            tweens[key] = Tween(from: target, to: target, start: t, duration: 0)
            return target
        }
        guard var tw = tweens[key] else {
            tweens[key] = Tween(from: target, to: target, start: t, duration: duration)
            return target
        }
        if abs(tw.to - target) > 0.0001 {
            if target < tw.to {
                tw = Tween(from: target, to: target, start: t, duration: 0)
            } else {
                tw = Tween(from: tweenValue(tw), to: target, start: t, duration: duration)
            }
            tweens[key] = tw
        }
        return tweenValue(tw)
    }

    private func tweenValue(_ tw: Tween) -> Double {
        guard tw.duration > 0 else { return tw.to }
        let u = LabMath.smoothstep((t - tw.start) / tw.duration)
        return tw.from + (tw.to - tw.from) * u
    }

    // MARK: One-off events

    /// Records the moment `on` becomes true and forgets it when it turns false.
    func track(_ key: String, _ on: Bool) {
        if on {
            if marks[key] == nil { marks[key] = t }
        } else {
            marks[key] = nil
        }
    }

    /// Seconds since the tracked event started, or nil if it is not active.
    /// With Reduce Motion on, events report as long finished so scenes show their end state.
    func age(_ key: String) -> Double? {
        guard let start = marks[key] else { return nil }
        return reduceMotion ? 60 : t - start
    }

    // MARK: Accumulators (slow build-ups such as copper plating)

    func accumulate(_ key: String, perSecond rate: Double, cap: Double = 1) -> Double {
        if reduceMotion {
            let frozen = cap * 0.7
            accumulators[key] = frozen
            return frozen
        }
        let next = min(cap, (accumulators[key] ?? 0) + rate * dt)
        accumulators[key] = next
        return next
    }

    func accumulated(_ key: String) -> Double { accumulators[key] ?? 0 }

    func clearAccumulator(_ key: String) { accumulators[key] = nil }

    // MARK: Titration

    /// Watches the burette reading and spawns falling drops when it increases.
    func observeTitrant(_ reading: Double) {
        let delta = reading - lastReading
        if delta < -0.0005 {
            drops.removeAll()
            flowUntil = 0
        } else if delta > 0.0005 && !reduceMotion {
            if delta >= 0.12 {
                for i in 0..<5 {
                    drops.append(LabDrop(birth: t + Double(i) * 0.10, hang: 0.06))
                }
                flowUntil = t + 0.65
            } else {
                drops.append(LabDrop(birth: t, hang: 0.32))
                flowUntil = max(flowUntil, t + 0.4)
            }
        }
        lastReading = reading
        let now = t
        drops.removeAll { now - $0.birth > 4 }
    }

    // MARK: Reset

    /// Clears events and accumulators. Smoothed display values are kept so they glide back to their reset state.
    func reset() {
        drops.removeAll()
        marks.removeAll()
        accumulators.removeAll()
        tweens.removeAll()
        lastReading = 0
        swirl = 0
        flowUntil = 0
    }
}
