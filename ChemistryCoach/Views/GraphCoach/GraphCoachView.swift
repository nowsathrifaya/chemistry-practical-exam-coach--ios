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

    init(graphType: GraphCoachType, curriculum: Curriculum, repository: AttemptRepository) {
        self.graphType = graphType
        self.curriculum = curriculum
        self.repository = repository
        self.dataset = generator.generate(type: graphType, seed: Int.random(in: 0...Int(Int32.max)), curriculum: curriculum)
    }

    func submit(onSaved: () -> Void) {
        let gradient = Double(studentGradientInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        let outcome = marker.mark(dataset: dataset, studentGradient: gradient, curriculum: curriculum)
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
        studentGradientInput = ""
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
                ScatterPlotCanvasView(dataset: viewModel.dataset, definition: def)
                    .frame(height: 260)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Plot the best-fit line through these points, then estimate its gradient.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

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

    var body: some View {
        Canvas { context, size in
            let margin: CGFloat = 36
            let plotRect = CGRect(x: margin, y: 12, width: size.width - margin - 12, height: size.height - margin - 24)

            var axes = Path()
            axes.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
            axes.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
            axes.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
            context.stroke(axes, with: .color(.primary), lineWidth: 1.5)

            guard let maxX = dataset.points.map(\.x).max(), let maxY = dataset.points.map(\.y).max(), maxX > 0, maxY > 0 else { return }

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

            context.draw(Text(definition.xLabel).font(.caption2), at: CGPoint(x: plotRect.midX, y: size.height - 8))
            context.draw(
                Text(definition.yLabel).font(.caption2).italic(),
                at: CGPoint(x: 14, y: plotRect.midY),
                anchor: .center
            )
        }
        .accessibilityLabel("Scatter plot of \(definition.label)")
        .padding(12)
    }
}
