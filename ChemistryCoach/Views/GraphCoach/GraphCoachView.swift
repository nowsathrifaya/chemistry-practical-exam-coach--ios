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

    private(set) var dataset: GraphDataset
    var studentGradientInput: String = ""
    private(set) var result: GraphGradientResult?

    // Axis-choice gate (Section 13: "choose axes" before the graph is revealed)
    private(set) var axisOptions: [String] = []
    private(set) var axisChosen: String?
    var axisChoiceCorrect: Bool { axisChosen == nil || axisChosen == graphType.definition.xLabel }
    var axisChoiceMade: Bool { axisChosen != nil }

    // Tap-to-pick gradient triangle (Section 13: "plot points" / "gradient triangle")
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

    /// Records a tapped point (already converted to data coordinates) as part of the
    /// student's chosen gradient triangle. The second tap evaluates the triangle and
    /// auto-fills the gradient field — the student can still edit it by hand.
    func pickPoint(_ p: GraphPoint) {
        guard pickedPoints.count < 2, result == nil else { return }
        pickedPoints.append(p)
        guard pickedPoints.count == 2 else { return }
        let xs = dataset.points.map(\.x)
        guard let minX = xs.min(), let maxX = xs.max(), maxX > minX else { return }
        let range = maxX - minX
        let dx = abs(pickedPoints[1].x - pickedPoints[0].x)
        pointsTooClose = dx < range * 0.25
        pointsExtrapolated = pickedPoints.contains { $0.x < minX - range * 0.02 || $0.x > maxX + range * 0.02 }
        if dx > 0 {
            let gradient = (pickedPoints[1].y - pickedPoints[0].y) / dx
            studentGradientInput = String(format: "%.3f", gradient)
        }
    }

    func clearPickedPoints() {
        pickedPoints = []
        pointsTooClose = false
        pointsExtrapolated = false
    }

    func submit(onSaved: () -> Void) {
        let gradient = Double(studentGradientInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        let outcome = marker.mark(dataset: dataset, studentGradient: gradient, pointsTooClose: pointsTooClose, pointsExtrapolated: pointsExtrapolated, axisChoiceCorrect: axisChoiceCorrect, curriculum: curriculum)
        result = outcome
        SoundManager.shared.play(outcome.correct ? .success : .error)
        repository.save(
            curriculum: curriculum, mode: .graphCoach, target: graphType.label,
            score: outcome.score, maxScore: 100, feedback: outcome.feedback
        )
        onSaved()
    }

    func nextDataset() {
        SoundManager.shared.play(.tap)
        dataset = generator.generate(type: graphType, seed: Int.random(in: 0...Int(Int32.max)), curriculum: curriculum)
        axisOptions = [graphType.definition.xLabel, graphType.definition.yLabel].shuffled()
        axisChosen = nil
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
                    ScatterPlotCanvasView(dataset: viewModel.dataset, definition: def, pickedPoints: viewModel.pickedPoints) { dataPoint in
                        viewModel.pickPoint(dataPoint)
                    }
                    .frame(height: 260)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("Tap two well-separated points on your best-fit line to form a gradient triangle, or type a value directly.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !viewModel.pickedPoints.isEmpty {
                        HStack {
                            Text("Picked \(viewModel.pickedPoints.count)/2 point(s)").font(.caption)
                            Spacer()
                            Button("Clear points") { viewModel.clearPickedPoints() }.font(.caption)
                        }
                    }

                    HStack {
                        TextField("Your gradient", text: $viewModel.studentGradientInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .focused($inputFocused)
                        Text("\(def.yUnit)/\(def.xUnit)")
                            .foregroundStyle(.secondary)
                    }

                    if let result = viewModel.result {
                        GraphResultCard(result: result)
                    }

                    Button(viewModel.result == nil ? "Check gradient" : "New dataset") {
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
    var onTap: ((GraphPoint) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let margin: CGFloat = 36
            let plotRect = CGRect(x: margin, y: 12, width: size.width - margin - 12, height: size.height - margin - 24)
            let maxX = dataset.points.map(\.x).max() ?? 1
            let maxY = dataset.points.map(\.y).max() ?? 1

            Canvas { context, _ in
                var axes = Path()
                axes.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
                axes.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
                axes.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
                context.stroke(axes, with: .color(.primary), lineWidth: 1.5)

                guard maxX > 0, maxY > 0 else { return }

                func point(_ p: GraphPoint) -> CGPoint {
                    CGPoint(
                        x: plotRect.minX + CGFloat(p.x / maxX) * plotRect.width,
                        y: plotRect.maxY - CGFloat(p.y / maxY) * plotRect.height
                    )
                }

                for p in dataset.points {
                    let center = point(p)
                    var cross = Path()
                    cross.move(to: CGPoint(x: center.x - 4, y: center.y - 4))
                    cross.addLine(to: CGPoint(x: center.x + 4, y: center.y + 4))
                    cross.move(to: CGPoint(x: center.x - 4, y: center.y + 4))
                    cross.addLine(to: CGPoint(x: center.x + 4, y: center.y - 4))
                    context.stroke(cross, with: .color(.blue), lineWidth: 2)
                }

                if pickedPoints.count == 2 {
                    var triangle = Path()
                    triangle.move(to: point(pickedPoints[0]))
                    triangle.addLine(to: point(pickedPoints[1]))
                    context.stroke(triangle, with: .color(.orange), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                }
                for p in pickedPoints {
                    let center = point(p)
                    context.fill(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)), with: .color(.orange))
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
                    guard maxX > 0, maxY > 0, let onTap else { return }
                    let loc = value.location
                    guard plotRect.insetBy(dx: -10, dy: -10).contains(loc) else { return }
                    let dataX = Double((loc.x - plotRect.minX) / plotRect.width) * maxX
                    let dataY = Double((plotRect.maxY - loc.y) / plotRect.height) * maxY
                    onTap(GraphPoint(x: dataX, y: dataY))
                }
            )
        }
        .accessibilityLabel("Scatter plot of \(definition.label). Tap two points to form a gradient triangle.")
        .padding(12)
    }
}
