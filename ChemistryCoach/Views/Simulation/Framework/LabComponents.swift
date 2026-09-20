import SwiftUI

struct ChemistryLabScaffold<Apparatus: View, Controls: View>: View {
    let title: String
    let instructionText: String
    let apparatusHeight: CGFloat
    let readings: [LabReading]
    let stages: [VirtualLabStage]
    let stageIndex: Int
    let result: LabRunResult?
    @ViewBuilder let apparatus: () -> Apparatus
    @ViewBuilder let controls: () -> Controls

    init(title: String, instructionText: String, apparatusHeight: CGFloat = 330, readings: [LabReading] = [], stages: [VirtualLabStage] = [], stageIndex: Int = 0, result: LabRunResult? = nil, @ViewBuilder apparatus: @escaping () -> Apparatus, @ViewBuilder controls: @escaping () -> Controls) {
        self.title = title; self.instructionText = instructionText; self.apparatusHeight = apparatusHeight
        self.readings = readings; self.stages = stages; self.stageIndex = stageIndex; self.result = result; self.apparatus = apparatus; self.controls = controls
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Paper 3 practical", systemImage: "flask.fill").font(.caption.weight(.semibold)).foregroundStyle(.tint)
                    Text(instructionText).font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

                if !stages.isEmpty { VirtualLabStageBar(stages: stages, current: stageIndex) }
                ChemistryLabZoomView(height: apparatusHeight, content: apparatus)
                controls()
                if !readings.isEmpty { ChemistryLabDataTable(readings: readings) }
                if let result { ChemistryLabFeedback(result: result) }
            }.padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ChemistryLabZoomView<Content: View>: View {
    let height: CGFloat
    @ViewBuilder let content: () -> Content
    @State private var zoomed = false

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ScrollView([.horizontal, .vertical], showsIndicators: zoomed) {
                    content()
                        .frame(width: geo.size.width * (zoomed ? 1.75 : 1), height: geo.size.height * (zoomed ? 1.75 : 1))
                }.scrollDisabled(!zoomed)
            }
            .frame(height: height)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Button { withAnimation(.easeInOut(duration: 0.2)) { zoomed.toggle() } } label: {
                Label(zoomed ? "Zoom out" : "Zoom in to read apparatus", systemImage: zoomed ? "minus.magnifyingglass" : "plus.magnifyingglass")
                    .font(.caption.weight(.semibold))
            }.buttonStyle(.bordered)
        }
    }
}

struct ChemistryLabDataTable: View {
    let readings: [LabReading]
    private var derived: Bool { readings.contains { $0.derivedValue != nil } }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recorded observations / trials").font(.subheadline.weight(.semibold)).padding(.bottom, 8)
            HStack { Text("Trial").frame(width: 42, alignment: .leading); Text("Measurement").frame(maxWidth: .infinity, alignment: .leading); if derived { Text("Derived").frame(width: 90, alignment: .trailing) } }.font(.caption.bold()).foregroundStyle(.secondary).padding(.vertical, 6)
            ForEach(readings) { r in
                HStack { Text("\(r.trialNumber)").frame(width: 42, alignment: .leading); Text(String(format: "%.2f %@", r.value, r.unit)).frame(maxWidth: .infinity, alignment: .leading); if derived, let dv = r.derivedValue { Text(String(format: "%.3f %@", dv, r.derivedUnit ?? "")).frame(width: 90, alignment: .trailing) } }.font(.footnote).padding(.vertical, 8)
                if r.id != readings.last?.id { Divider() }
            }
        }.padding(14).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ChemistryLabFeedback: View {
    let result: LabRunResult
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(result.correct ? "Practical skill demonstrated" : "Review this practical", systemImage: result.correct ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath.circle.fill").font(.headline).foregroundStyle(result.correct ? .green : .orange)
            ForEach(result.feedback, id: \.self) { Text($0).font(.footnote) }
            if !result.skillMarks.isEmpty {
                Divider()
                Text("Practical skills breakdown").font(.caption.bold())
                ForEach(result.skillMarks) { mark in
                    HStack {
                        Text(mark.skill).font(.footnote)
                        Spacer()
                        Text("\(mark.scored)/\(mark.outOf)").font(.footnote.monospacedDigit().weight(.semibold))
                    }
                }
            }
            if !result.mistakes.isEmpty {
                Divider()
                Text("What happened").font(.caption.bold())
                ForEach(result.mistakes) { mistake in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mistake.title).font(.footnote.weight(.semibold))
                        Text(mistake.consequence).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            Divider(); Text("Exam technique").font(.caption.bold()); Text(result.examTip).font(.footnote).foregroundStyle(.secondary)
        }.padding(16).background((result.correct ? Color.green : Color.orange).opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct TrialProgressView: View {
    let completed: Int; let target: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...max(target, 1), id: \.self) { n in Circle().fill(n <= completed ? Color.green : Color.secondary.opacity(0.2)).frame(width: 10, height: 10) }
            Text("\(completed)/\(target) trials").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }
}


struct VirtualLabStageBar: View {
    let stages: [VirtualLabStage]
    let current: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Practical workflow").font(.subheadline.weight(.semibold)); Spacer(); Text("Stage \(min(current + 1, stages.count))/\(stages.count)").font(.caption).foregroundStyle(.secondary) }
            ProgressView(value: Double(min(current, stages.count)), total: Double(max(stages.count, 1)))
            HStack(spacing: 6) { ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in Label(stage.title, systemImage: index < current ? "checkmark.circle.fill" : index == current ? "circle.fill" : "circle").font(.caption2).foregroundStyle(index <= current ? Color.accentColor : .secondary) } }
            if current < stages.count { Text(stages[current].instruction).font(.caption).foregroundStyle(.secondary) }
        }.padding(12).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
