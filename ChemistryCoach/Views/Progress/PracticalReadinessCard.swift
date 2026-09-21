import SwiftUI

struct PracticalReadinessCard: View {
    let attempts: [Attempt]
    let curriculum: Curriculum

    private var readiness: PracticalReadiness { PracticalReadinessCalculator.compute(attempts: attempts, curriculum: curriculum) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Paper 3 readiness")
                        .font(.headline)
                    Text("Mapped to Planning, MMO, PDO and ACE")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let overall = readiness.overall {
                    Text("\(overall)%")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(readinessColor(overall))
                } else {
                    Text("—")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }
            }

            if let overall = readiness.overall {
                ProgressView(value: Double(overall), total: 100)
                    .tint(readinessColor(overall))
            } else {
                Text("Complete a few practical, apparatus, graph or ACE activities to build your readiness profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(readiness.skills, id: \.id) { item in
                HStack(spacing: 10) {
                    Text(item.skill.shortLabel)
                        .font(.caption.weight(.bold))
                        .frame(width: 52, alignment: .leading)
                    if let score = item.score {
                        ProgressView(value: Double(score), total: 100)
                        Text("\(score)%")
                            .font(.caption.monospacedDigit())
                            .frame(width: 42, alignment: .trailing)
                    } else {
                        Text("Not enough evidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }

            if let weakest = readiness.weakest {
                Label("Next focus: \(weakest.skill.label)", systemImage: "scope")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func readinessColor(_ value: Int) -> Color {
        switch value {
        case 80...: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}
