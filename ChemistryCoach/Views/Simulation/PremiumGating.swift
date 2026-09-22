//
//  PremiumGating.swift
//  ChemistryCoach
//
//  Single source of truth for which practical-lab destination a student
//  actually lands on: the real lab, or the paywall.
//
//  Before this file existed, every entry point (the Simulations list,
//  Home's Continue-Learning card, Adaptive Coach's recommendations) wrote
//  its own `if type.isFree || purchases.isPremium { lab } else { paywall }`
//  check inline — nine near-identical copies in total. That duplication is
//  exactly how a lab can end up unlocked for free by accident: the
//  `ChemistrySimulationView` compatibility wrapper in SimulationView.swift
//  builds the real lab with no gating of its own, relying entirely on every
//  caller remembering to check first. One missed copy at a future call site
//  (a new quick-action button, a deep link, a widget) would leak every
//  non-free experiment.
//
//  Routing every entry point through `integratedLabDestination` and
//  `advancedLabDestination` instead means there is exactly one place left
//  that decides what's locked, so it can't drift out of sync with itself.
//

import SwiftUI

@ViewBuilder
func integratedLabDestination(
    for type: SimulationType,
    curriculum: Curriculum,
    repository: AttemptRepository,
    purchases: PurchaseManager
) -> some View {
    if type.isFree || purchases.isPremium {
        ChemistryPracticalLabView(type: type, curriculum: curriculum, repository: repository)
    } else {
        PremiumPaywallView(purchases: purchases)
    }
}

@ViewBuilder
func advancedLabDestination(
    for kind: AdvancedSimulationKind,
    curriculum: Curriculum,
    purchases: PurchaseManager
) -> some View {
    if purchases.isPremium {
        switch kind {
        case .qualitativeUnknown:
            QualitativeAnalysisLabView(curriculum: curriculum)
        case .waterOfCrystallisation:
            WaterOfCrystallisationView(curriculum: curriculum)
        case .saltPreparation:
            SaltPreparationView(curriculum: curriculum)
        }
    } else {
        PremiumPaywallView(purchases: purchases)
    }
}
