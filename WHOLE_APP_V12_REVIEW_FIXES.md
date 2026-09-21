# Whole-app review fixes — v1.4.0 (Build 6)

## Product direction
The app is now explicitly positioned as a Singapore-Cambridge O-Level Chemistry Paper 3 practical coach. The old General curriculum remains only as a migration-safe stored enum value and is not presented as a selectable curriculum.

## Learning loop
Practice evidence is mapped to four exam skill areas:

1. Planning
2. Manipulation, Measurement & Observation (MMO)
3. Presentation of Data & Observations (PDO)
4. Analysis, Conclusions & Evaluation (ACE)

A Paper 3 readiness card uses recent performance and shows the weakest evidenced skill rather than presenting an unsupported single score when there is insufficient data.

## Adaptive coaching
Attempts now capture optional skill/error metadata. Existing attempts are classified safely from mode/target text. The coach surfaces the most common detected error pattern for a weak area.

## Persistence
Important SwiftData fetch/save/reset operations now handle errors explicitly. Failed inserts are rolled back instead of silently pretending that progress was saved.

## Premium
Premium starts locked. Verified StoreKit current entitlements and transaction updates control access. Product-loading and pending-purchase states surface user-facing errors.

## Mock examination
The 40-mark / 110-minute mock remains self-assessed, but each marking point is now independently tickable. This is criterion-level self-marking and is more transparent than manually entering an arbitrary mark total.

## Testing
A unit-test target covers:
- Singapore curriculum resolution
- empty and populated Paper 3 readiness
- mode-to-skill classification
- common practical error classification

## Remaining production verification
This environment does not contain Xcode/xcodebuild, so the source was syntax-parsed with Swift 6.2.1 but an iOS device/simulator archive was not performed here. The next CI/Xcode run should generate the project from `project.yml`, run `ChemistryCoachTests`, then archive Release for device.
