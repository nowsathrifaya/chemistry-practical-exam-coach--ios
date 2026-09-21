# Chemistry Practical Exam Coach — iOS

Native SwiftUI iOS 17 app for Singapore-Cambridge GCE O-Level Chemistry (6092), with a practical-exam workflow modelled on the Physics Practical Exam Coach.

## Current build

### Home
- Paper 3 practical dashboard
- live accuracy, points and streak
- Continue Learning and exam countdown
- quick access to practice modes

### Learn
12 syllabus-focused Chemistry topics plus Paper 3 practical skills, titration concordance, apparatus precision, planning and evaluation.

### Apparatus Trainer
Interactive Canvas drawings for:
- electronic balance
- burette
- pipette
- measuring cylinder
- thermometer
- gas syringe
- stopwatch

Students read the displayed instrument rather than relying on symbolic icons, then receive tolerance-based marking and an exam trap.

### Graph Coach
- titration data
- volume of gas vs time
- concentration vs time
- temperature vs time
- chromatography / Rf

### ACE / Planning Practice
Original exam-style questions covering Planning (P), Manipulation/Measurement/Observation (MMO), Presentation of Data/Observations (PDO), and Analysis/Conclusions/Evaluation (ACE).

### Practical Labs — upgraded from the Physics lab architecture
All eight Chemistry practical modules now use a shared graded-lab workflow:
- randomised task targets
- hands-on Canvas/drag interactions where appropriate
- repeated trials and a recorded data table
- tolerance-based grading
- teaching feedback and exam-technique tips
- finished sessions saved to Progress as `SIMULATION_LAB`

Experiments:
1. Acid–base titration — burette/end-point practice and concordance
2. Qualitative analysis — observation-first ion/gas testing
3. Rate of reaction — real elapsed-time gas collection
4. Electrolysis — electrode products and oxidation/reduction reasoning
5. Paper chromatography — solvent-front/spot measurement and Rf
6. Energy changes — measured temperature change and exothermic/endothermic interpretation
7. Separation & purification — property-based method sequencing
8. Solubility & crystallisation — temperature control and crystal recovery

### Progress
Attempts, accuracy, points, streak, mastery, badges and local-only SwiftData history. Practical lab attempts now count alongside apparatus, graph and ACE practice.

## Architecture

The practical layer follows the core Physics pattern:
- `LabReading` and `LabRunResult` define the shared experiment data contract.
- `LabAttemptRecorder` writes finished lab sessions through `AttemptRepository`.
- `ChemistryLabScaffold` provides a consistent instruction → apparatus → controls → data table → feedback flow.
- Experiment-specific logic lives in the Chemistry lab view model and Canvas apparatus, keeping the shared shell reusable.

## Lab animation architecture

The apparatus in every practical lab is animated by a small time-based engine:

- `Framework/LabMotion.swift` — monotonic clock, eased values (`smooth`), timed step transitions (`tween`), one-off event timers (`track`/`age`), falling titrant drops. Honors **Reduce Motion** (snaps to end states, freezes ambient motion).
- `Framework/LabDraw.swift` — glassware paths, wavy liquid surfaces, procedural bubble streams, flames, steam, crystals.
- `LabScenes*.swift` — one scene per experiment, drawn every frame from a `TimelineView` + `Canvas` in a fixed 360 × 330 design space that is scaled to fit (so the zoom control still works).

Scenes only *read* the lab view model; grading and recording logic are unchanged. To add or tweak a scene, edit the matching function in `LabScenes*.swift`.

## Build

On a Mac with Xcode:

```bash
brew install xcodegen
cd OLevelChemistryCoach
xcodegen generate
open ChemistryCoach.xcodeproj
```

Select the Apple Developer Team and run on an iPhone/iOS 17+ simulator.

The project uses SwiftUI, SwiftData, iOS 17+, no backend, no account, and no network dependency for learning content.

## Next development layer
- richer qualitative-analysis observation banks
- Paper 1 MCQ engine
- Paper 2 structured/data-based question engine
- full 6092 revision planner
- App Store purchase / entitlement layer


Revision materials bundle fix: the XcodeGen project explicitly includes ChemistryCoach/Resources/RevisionMaterials so the 10 .txt revision packs are copied into the app bundle.

## v9 simulation progression fix
Incorrect instrument readings/end-point decisions are now treated as scored mistakes rather than hard stops. In particular, after a titration endpoint is recorded—even if it is early or overshot—the practical workflow advances to the measured stage and the student can continue to the next attempt. The recorded reading remains in the data/history and is used for feedback; the app does not require a correct reading to proceed.
