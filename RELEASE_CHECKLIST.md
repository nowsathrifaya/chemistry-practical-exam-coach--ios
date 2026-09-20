# Chemistry Practical Exam Coach — Release Checklist

## Before submission
- [ ] Set the bundle identifier and signing team in Xcode.
- [ ] Add `StoreKit/ChemistryCoach.storekit` to the Xcode target for local purchase testing.
- [ ] Create non-consumable product `com.chemistrycoach.all-experiments` in App Store Connect.
- [ ] Replace the test price with the approved App Store price.
- [ ] Test purchase, cancellation, pending purchase, restore, and offline launch.
- [ ] Test Titration remains free and all other experiments require entitlement.
- [ ] Test iPhone, iPad, dark mode, Dynamic Type, and VoiceOver.
- [ ] Add privacy policy and support URLs in App Store Connect.
- [ ] Archive on macOS/Xcode and upload a TestFlight build.
- [ ] Run TestFlight testing with a sandbox Apple ID.

## Content QA
- [ ] Verify every observation, equation, safety note, and marking point against the current SEAB syllabus.
- [ ] Use original exam-style questions; do not redistribute copyrighted papers.
- [ ] Confirm all units, significant figures, graph scales, and chemical formulae.
