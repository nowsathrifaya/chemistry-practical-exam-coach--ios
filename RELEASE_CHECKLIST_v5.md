# Chemistry Practical Exam Coach v5 — Release Checklist

## Implemented
- [x] Adaptive Coach recommendations on Home and Progress
- [x] Adaptive routes into QA, calculations, ACE topic/skill, simulations, apparatus and graph practice
- [x] Advanced QA / water crystallisation / salt preparation results recorded in SwiftData
- [x] Dedicated 5-question Paper 3 practical mock with self-marking
- [x] Practical mock results recorded in SwiftData
- [x] Water-of-crystallisation mass-of-water calculation corrected
- [x] ACE Leitner state remains persistent per curriculum using UserDefaults
- [x] Version 1.2.0 / build 3
- [x] 65 Swift files syntax parsed successfully with swiftc -parse

## Before App Store submission
- [ ] Run XcodeGen on macOS to generate the .xcodeproj from project.yml
- [ ] Run a full Xcode archive on macOS
- [ ] Test StoreKit product com.chemistrycoach.all-experiments in the App Store Connect environment
- [ ] Test all adaptive navigation destinations on a physical iPhone
- [ ] Verify SwiftData migration/upgrade from previous installed build
- [ ] Review all chemistry answer keys against the intended 6092 source materials
