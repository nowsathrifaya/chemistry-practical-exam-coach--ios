//
//  FeatureFlags.swift
//  ChemistryCoach
//
//  Port of `core.config.FeatureFlags.kt`.
//

import Foundation

enum FeatureFlags {
    /// Real ad integration (Google Mobile Ads SDK) is gated until core
    /// training modules are stable, matching the Android flag.
    static let adsEnabled = false

    /// Full experiment simulation is live; kept as a flag for parity with
    /// Android in case a curriculum needs it toggled per build.
    static let experimentModeEnabled = true
}
