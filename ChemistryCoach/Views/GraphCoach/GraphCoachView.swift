//
//  GraphCoachView.swift
//  ChemistryCoach
//
//  Replaces `GraphCoachListFragment` + `GraphCoachPracticeFragment`. Renders
//  the generated scatter dataset with a native `Canvas`, takes the
//  student's gradient estimate, and marks it via `GraphGradientMarker`.
//

import SwiftUI

struct GraphCoachListView: View {
    let profile: CurriculumProfile

    var body: some View {
        List(profile.graphTypes) { type in
            NavigationLink {
                GraphCoachPracticeContainerView(graphType: type, curriculum: profile.curriculum)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.label).font(.headline)
                    Text(type.definition.gradientMeaning).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Graph Coach")
    }
}

struct GraphCoachPracticeContainerView: View {
    let graphType: GraphCoachType
    let curriculum: Curriculum
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        GraphCoachPracticeView(
            graphType: graphType, curriculum: curriculum,
            repository: AttemptRepository(modelContext: modelContext)
        )
    }
}

@MainActor
@Observable
final class GraphCoachPracticeViewModel {
    private let generator = GraphDatasetGenerator()
    private let marker = GraphGradientMarker()
    private let repository: AttemptRepository
    let graphType: GraphCoachType
    let curriculum: Curriculum
    var taskKind: GraphTaskKind { graphType.definition.taskKind }

    private(set) var dataset: GraphDataset
    var studentGradientInput: String = ""
    private(set) var result: GraphGradientResult?

    // Axis-choice gate (Section 13: "choose axes" before the graph is revealed)
    private(set) var axisOptions: [String] = []
    private(set) var axisChosen: String?
    var axisChoiceCorrect: Bool { axisChosen == nil || axisChosen == graphType.definition.xLabel }
    var axisChoiceMade: Bool { axisChosen != nil }

    /// Collapsible exam-technique tip, shown once the graph is revealed and
    /// collapsed by default so it doesn't read as the answer being handed over.
    var showTechniqueTip: Bool = false

    // Tap-to-pick gradient triangle (Section 13: "plot points" / "gradient triangle").
    // For the titration `.equivalencePoint` task this holds at most one point —
    // a single tap on the volume where the curve is steepest — rather than two.
    private(set) var pickedPoints: [GraphPoint] = []
    private(set) var pointsTooClose: Bool = false
    private(set) var pointsExtrapolated: Bool = false

    init(graphType: GraphCoachType, curriculum: Curriculum, repository: AttemptRepository) {
        self.graphType = graphType
        self.curriculum = curriculum
        self.repository = repository
        self.dataset = generator.generate(type: graphType, seed: Int.random(in: 0...Int(Int32.max)), curriculum: curriculum)
        self.axisOptions = [graphType.definition.xLabel, graphType.definition.yLabel].shuffled()
    }

    func chooseAxis(_ label: String) {
        guard axisChosen == nil else { return }
        axisChosen = label
    }

    /// Records a tapped point (already converted to data coordinates).
    /// In `.gradient` mode, two taps form the gradient triangle and
    /// auto-fill the gradient field (still hand-editable afterwards). In
    /// `.equivalencePoint` mode (titration), a single tap marks the
    /// candidate end-point volume and can be re-tapped to move it right up
    /// until the student submits.
    func pickPoint(_ p: GraphPoint) {
        guard result == nil else { return }
        let xs = dataset.points.map(\.x)
        guard let minX = xs.min(), let maxX = xs.max(), maxX > minX else { return }
        let range = maxX - minX

        if taskKind == .equivalencePoint {
            pickedPoints = [p]
            pointsExtrapolated = p.x < minX - range * 0.02 || p.x > maxX + range * 0.02
            studentGradientInput = String(format: "%.1f", p.x)
            return
        }

        guard pickedPoints.count < 2 else { return }
        pickedPoints.append(p)
        guard pickedPoints.count == 2 else { return }
        // Signed on purpose: (y2 - y1) / (x2 - x1) is invariant to which point was
        // tapped first, since swapping the two points negates both the numerator and
        // the denominator. Using abs() only on the denominator (as before) broke that
        // invariance and silently flipped the sign of the auto-filled gradient whenever
        // the student happened to tap the right-hand point before the left-hand one.
        let signedDx = pickedPoints[1].x - pickedPoints[0].x
        pointsTooClose = abs(signedDx) < range * 0.25
        pointsExtrapolated = pickedPoints.contains { $0.x < minX - range * 0.02 || $0.x > maxX + range * 0.02 }
        if signedDx != 0 {
            let gradient = (pickedPoints[1].y - pickedPoints[0].y) / signedDx
            studentGradientInput = String(format: "%.3f", gradient)
        }
    }

    func clearPickedPoints() {
        pickedPoints = []
        pointsTooClose = false
        pointsExtrapolated = false
        studentGradientInput = ""
    }

    func submit(onSaved: () -> Void) {
        let value = Double(studentGradientInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        let outcome: GraphGradientResult
        if taskKind == .equivalencePoint {
            outcome = marker.markEquivalencePoint(dataset: dataset, studentVolume: value, pointExtrapolated: pointsExtrapolated, axisChoiceCorrect: axisChoiceCorrect, curriculum: curriculum)
        } else {
            outcome = marker.mark(dataset: dataset, studentGradient: value, pointsTooClose: pointsTooClose, pointsExtrapolated: pointsExtrapolated, axisChoiceCorrect: axisChoiceCorrect, curriculum: curriculum)
        }
        result = outcome
        SoundManager.shared.play(outcome.correct ? .success : .error)
        repository.save(
            curriculum: curriculum, mode: AttemptMode.graphCoach, target: graphType.label,
            score: outcome.score, maxScore: 100, feedback: outcome.feedback
        )
        onSaved()
    }

    func nextDataset() {
        SoundManager.shared.play(.tap)
        dataset = generator.generate(type: graphType, seed: Int.random(in: 0...Int(Int32.max)), curriculum: curriculum)
        axisOptions = [graphType.definition.xLabel, graphType.definition.yLabel].shuffled()
        axisChosen = nil
        showTechniqueTip = false
        studentGradientInput = ""
        pickedPoints = []
        pointsTooClose = false
        pointsExtrapolated = false
        result = nil
    }
}

struct GraphCoachPracticeView: View {
    @State private var viewModel: GraphCoachPracticeViewModel
    var onSaved: (() -> Void)?
    @FocusState private var inputFocused: Bool

    init(graphType: GraphCoachType, curriculum: Curriculum, repository: AttemptRepository, onSaved: (() -> Void)? = nil) {
        _viewModel = State(initialValue: GraphCoachPracticeViewModel(graphType: graphType, curriculum: curriculum, repository: repository))
        self.onSaved = onSaved
    }

    private var def: GraphCoachType.Definition { viewModel.graphType.definition }

    private var instructionText: String {
        viewModel.taskKind == .equivalencePoint
            ? "Tap the curve where it's rising most steeply — the middle of the jump — to mark the equivalence point, or type a volume directly."
            : "Tap two well-separated points on your best-fit line to form a gradient triangle, or type a value directly."
    }
    private var fieldLabel: String {
        viewModel.taskKind == .equivalencePoint ? "Equivalence volume" : "Your gradient"
    }
    private var confirmButtonLabel: String {
        viewModel.taskKind == .equivalencePoint ? "Check end-point" : "Check gradient"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.axisChoiceMade {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Before you see the graph: which variable belongs on the x-axis (horizontal)?").font(.headline)
                        Text("The x-axis carries the independent variable — the one you controlled or measured as time.").font(.caption).foregroundStyle(.secondary)
                        ForEach(viewModel.axisOptions, id: \.self) { option in
                            Button(option) { viewModel.chooseAxis(option) }.buttonStyle(.bordered).frame(maxWidth: .infinity)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                } else {
                    if !viewModel.axisChoiceCorrect {
                        Label("Convention places \(def.xLabel) on the x-axis — keep this in mind below.", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundStyle(.orange)
                    }

                    TechniqueTipCard(tip: def.techniqueTip, isExpanded: $viewModel.showTechniqueTip)

                    ScatterPlotCanvasView(
                        dataset: viewModel.dataset, definition: def, pickedPoints: viewModel.pickedPoints,
                        referenceLine: viewModel.result != nil ? (viewModel.dataset.referenceStart, viewModel.dataset.referenceEnd) : nil
                    ) { dataPoint in
                        viewModel.pickPoint(dataPoint)
                    }
                    .frame(height: 260)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if viewModel.result != nil {
                        Label("Green line shows the true trend for comparison.", systemImage: "line.diagonal")
                            .font(.caption2).foregroundStyle(.green)
                    }

                    Text(instructionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !viewModel.pickedPoints.isEmpty {
                        HStack {
                            Text(viewModel.taskKind == .equivalencePoint ? "Marked at \(String(format: "%.1f", viewModel.pickedPoints[0].x)) \(def.xUnit)" : "Picked \(viewModel.pickedPoints.count)/2 point(s)")
                                .font(.caption)
                            Spacer()
                            Button(viewModel.taskKind == .equivalencePoint ? "Clear mark" : "Clear points") { viewModel.clearPickedPoints() }.font(.caption)
                        }
                    }

                    HStack {
                        TextField(fieldLabel, text: $viewModel.studentGradientInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .focused($inputFocused)
                        if viewModel.taskKind == .equivalencePoint {
                            Text(def.xUnit).foregroundStyle(.secondary)
                        } else {
                            Text("\(def.yUnit)/\(def.xUnit)").foregroundStyle(.secondary)
                        }
                    }

                    if let result = viewModel.result {
                        GraphResultCard(result: result)
                    }

                    Button(viewModel.result == nil ? confirmButtonLabel : "New dataset") {
                        if viewModel.result == nil {
                            inputFocused = false
                            viewModel.submit(onSaved: { onSaved?() })
                        } else {
                            viewModel.nextDataset()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.graphType.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Collapsed by default so it reads as an optional nudge on exam technique
/// rather than the answer being handed over before the student has tried.
private struct TechniqueTipCard: View {
    let tip: String
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(tip)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        } label: {
            Label("Technique tip", systemImage: "lightbulb.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.yellow)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct GraphResultCard: View {
    let result: GraphGradientResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(result.correct ? "Within tolerance" : "Outside tolerance", systemImage: result.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(result.correct ? .green : .red)
            ForEach(result.feedback, id: \.self) { line in
                Text(line).font(.footnote)
            }
            if !result.skillMarks.isEmpty {
                Divider()
                ForEach(result.skillMarks) { mark in
                    HStack {
                        Text(mark.skill).font(.caption2)
                        Spacer()
                        Text("\(mark.scored)/\(mark.outOf)").font(.caption2.monospacedDigit())
                    }
                }
            }
            if !result.mistakes.isEmpty {
                Divider()
                ForEach(result.mistakes) { mistake in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mistake.title).font(.caption.weight(.semibold))
                        Text(mistake.consequence).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Divider()
            Text(result.explanation).font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((result.correct ? Color.green : Color.red).opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ScatterPlotCanvasView: View {
    let dataset: GraphDataset
    let definition: GraphCoachType.Definition
    var pickedPoints: [GraphPoint] = []
    /// Two clean points describing the true trend, drawn as a dashed green
    /// reference once the student has submitted an answer. Pass nil to hide
    /// it (i.e. before marking, so it can't be used to read off the answer).
    var referenceLine: (GraphPoint, GraphPoint)? = nil
    var onTap: ((GraphPoint) -> Void)? = nil

    /// Number of gridlines/tick labels drawn along each axis.
    private let tickCount = 4

    /// Picks a sensible number of decimal places for a tick label given the
    /// span it needs to distinguish between neighbouring ticks.
    private func formatTick(_ value: Double, span: Double) -> String {
        if span < 1 { return String(format: "%.2f", value) }
        if span < 10 { return String(format: "%.1f", value) }
        return String(format: "%.0f", value)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let margin: CGFloat = 42
            let plotRect = CGRect(x: margin, y: 12, width: size.width - margin - 12, height: size.height - margin - 24)

            let xs = dataset.points.map(\.x)
            let ys = dataset.points.map(\.y)
            let dataMinX = xs.min() ?? 0, dataMaxX = xs.max() ?? 1
            let dataMinY = ys.min() ?? 0, dataMaxY = ys.max() ?? 1
            let rawRangeX = dataMaxX - dataMinX
            let rawRangeY = dataMaxY - dataMinY
            // A small margin around the data so points near the edge aren't drawn right
            // on top of the axes, and — importantly — so a dataset whose values don't
            // start near zero (e.g. temperature climbing from 24°C) isn't squashed into
            // a sliver at the top of a chart that always starts at (0, 0). The x-axis
            // still floors at zero, since every x-quantity here (time, volume, distance)
            // is physically non-negative and naturally starts there.
            let padX = rawRangeX > 0 ? rawRangeX * 0.08 : max(abs(dataMaxX), 1) * 0.1
            let padY = rawRangeY > 0 ? rawRangeY * 0.12 : max(abs(dataMaxY), 1) * 0.1
            let axisMinX = max(0, dataMinX - padX)
            let axisMaxX = dataMaxX + padX
            let axisMinY = max(0, dataMinY - padY)
            let axisMaxY = dataMaxY + padY
            let rangeX = max(axisMaxX - axisMinX, 0.0001)
            let rangeY = max(axisMaxY - axisMinY, 0.0001)

            let point: (GraphPoint) -> CGPoint = { p in
                CGPoint(
                    x: plotRect.minX + CGFloat((p.x - axisMinX) / rangeX) * plotRect.width,
                    y: plotRect.maxY - CGFloat((p.y - axisMinY) / rangeY) * plotRect.height
                )
            }

            Canvas { context, _ in
                // Gridlines + numeric tick labels, drawn first so data sits on top.
                for i in 0...tickCount {
                    let t = Double(i) / Double(tickCount)
                    let xVal = axisMinX + t * rangeX
                    let xPos = plotRect.minX + CGFloat(t) * plotRect.width
                    var gridX = Path()
                    gridX.move(to: CGPoint(x: xPos, y: plotRect.minY))
                    gridX.addLine(to: CGPoint(x: xPos, y: plotRect.maxY))
                    context.stroke(gridX, with: .color(.primary.opacity(i == 0 ? 0 : 0.08)), lineWidth: 1)
                    context.draw(Text(formatTick(xVal, span: rangeX)).font(.system(size: 8)), at: CGPoint(x: xPos, y: plotRect.maxY + 10))

                    let yVal = axisMinY + t * rangeY
                    let yPos = plotRect.maxY - CGFloat(t) * plotRect.height
                    var gridY = Path()
                    gridY.move(to: CGPoint(x: plotRect.minX, y: yPos))
                    gridY.addLine(to: CGPoint(x: plotRect.maxX, y: yPos))
                    context.stroke(gridY, with: .color(.primary.opacity(i == 0 ? 0 : 0.08)), lineWidth: 1)
                    context.draw(Text(formatTick(yVal, span: rangeY)).font(.system(size: 8)), at: CGPoint(x: plotRect.minX - 16, y: yPos))
                }

                var axes = Path()
                axes.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
                axes.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
                axes.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
                context.stroke(axes, with: .color(.primary), lineWidth: 1.5)

                for p in dataset.points {
                    let center = point(p)
                    var cross = Path()
                    cross.move(to: CGPoint(x: center.x - 4, y: center.y - 4))
                    cross.addLine(to: CGPoint(x: center.x + 4, y: center.y + 4))
                    cross.move(to: CGPoint(x: center.x - 4, y: center.y + 4))
                    cross.addLine(to: CGPoint(x: center.x + 4, y: center.y - 4))
                    context.stroke(cross, with: .color(.blue), lineWidth: 2)
                }

                if definition.taskKind == .equivalencePoint, let mark = pickedPoints.first {
                    let x = point(GraphPoint(x: mark.x, y: 0)).x
                    var marker = Path()
                    marker.move(to: CGPoint(x: x, y: plotRect.minY))
                    marker.addLine(to: CGPoint(x: x, y: plotRect.maxY))
                    context.stroke(marker, with: .color(.orange), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                } else if pickedPoints.count == 2 {
                    var triangle = Path()
                    triangle.move(to: point(pickedPoints[0]))
                    triangle.addLine(to: point(pickedPoints[1]))
                    context.stroke(triangle, with: .color(.orange), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                }
                for p in pickedPoints {
                    let center = point(p)
                    context.fill(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)), with: .color(.orange))
                }

                // True-trend reference, only revealed after the student has submitted.
                if let (refA, refB) = referenceLine {
                    var refPath = Path()
                    refPath.move(to: point(refA))
                    refPath.addLine(to: point(refB))
                    context.stroke(refPath, with: .color(.green), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }

                context.draw(Text(definition.xLabel).font(.caption2), at: CGPoint(x: plotRect.midX, y: size.height - 8))
                context.draw(
                    Text(definition.yLabel).font(.caption2).italic(),
                    at: CGPoint(x: 14, y: plotRect.midY),
                    anchor: .center
                )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onEnded { value in
                    guard let onTap else { return }
                    let loc = value.location
                    guard plotRect.insetBy(dx: -10, dy: -10).contains(loc) else { return }
                    let dataX = axisMinX + Double((loc.x - plotRect.minX) / plotRect.width) * rangeX
                    let dataY = axisMinY + Double((plotRect.maxY - loc.y) / plotRect.height) * rangeY
                    onTap(GraphPoint(x: dataX, y: dataY))
                }
            )
        }
        .accessibilityLabel(
            definition.taskKind == .equivalencePoint
                ? "Scatter plot of \(definition.label). Tap the steepest part of the curve to mark the equivalence point."
                : "Scatter plot of \(definition.label). Tap two points to form a gradient triangle."
        )
        .padding(12)
    }
}
