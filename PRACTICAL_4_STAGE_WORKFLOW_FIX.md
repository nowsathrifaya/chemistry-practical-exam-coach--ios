# Practical 4-Stage Workflow Fix

## Mandatory workflow
Every chemistry practical now uses one authoritative state machine:

1. Prepare
2. Perform
3. Measure
4. Analyse

Domain-specific action states no longer determine or skip the exam stage.

## Fixed
- Added `PracticalWorkflowStage` as the single source of truth for the stage indicator.
- Prepare moves the student to Perform; it cannot skip ahead.
- Experimental completion moves to Measure.
- Measurement submission moves to Analyse.
- Analysis/feedback is blocked until Analyse is entered.
- Titration endpoint now ends in Measure, followed by an explicit Continue to Analyse step before concentration feedback.
- Rate-of-reaction reaches Measure only after the required three trials, then Analyse is explicit.
- Qualitative analysis, electrolysis, chromatography, energetics, separation, and solubility all have explicit Measure → Analyse transitions.
- Generic Record actions no longer grade immediately.
- Duplicate titration analysed-state assignment removed.
- Non-rate practicals use one final measurement submission instead of incorrectly requiring three generic readings.
- Stage display now shows `Stage n/4` and the complete workflow.

## Version
Marketing version: 1.4.0
Build: 6
Build: 5


## v1.4.0 whole-app quality upgrade

- Singapore O-Level is the only selectable curriculum; the old General value remains only for backwards compatibility.
- Paper 3 readiness now maps practice evidence to Planning, MMO, PDO and ACE, with recency weighting and a weakest-skill focus.
- Attempts now retain optional skill, error type, duration, hints and confidence metadata.
- Persistence no longer silently ignores important SwiftData save/fetch failures.
- Premium entitlement starts locked and is controlled by verified StoreKit entitlements.
- The full Paper 3 mock now uses criterion-by-criterion self-marking instead of an arbitrary numeric Stepper.
- Added unit-test target covering curriculum mapping, readiness scoring and error classification.
- Removed misleading General-curriculum UI and updated mock-exam catalog wording.
