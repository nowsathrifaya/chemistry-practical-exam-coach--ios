//
//  LinearRegression.swift
//  ChemistryCoach
//
//  Direct port of `core.math.LinearRegression.kt`. Least-squares fit used by
//  both the Graph Coach gradient marker and (indirectly) by any future
//  best-fit-line visualisation.
//

import Foundation

struct RegressionPoint {
    let x: Double
    let y: Double
}

struct RegressionResult {
    let slope: Double
    let intercept: Double
}

enum LinearRegression {
    /// - Precondition: `points.count >= 2`, matching the Kotlin `require`.
    static func fit(_ points: [RegressionPoint]) -> RegressionResult {
        precondition(points.count >= 2, "At least two points are required for regression.")
        let n = Double(points.count)
        let sumX = points.reduce(0.0) { $0 + $1.x }
        let sumY = points.reduce(0.0) { $0 + $1.y }
        let sumXY = points.reduce(0.0) { $0 + ($1.x * $1.y) }
        let sumXX = points.reduce(0.0) { $0 + ($1.x * $1.x) }
        let denominator = max((n * sumXX) - (sumX * sumX), 1e-9)
        let slope = ((n * sumXY) - (sumX * sumY)) / denominator
        let intercept = (sumY - (slope * sumX)) / n
        return RegressionResult(slope: slope, intercept: intercept)
    }

    static func gradient(_ points: [RegressionPoint]) -> Double {
        fit(points).slope
    }

    static func yAt(_ x: Double, result: RegressionResult) -> Double {
        (result.slope * x) + result.intercept
    }
}
