import SwiftUI

struct PracticalChecklistView: View {
    let topic: CurriculumTopic
    @State private var checked = Set<String>()
    private var items: [String] {
        switch topic.id {
        case "titration": return ["Rinse burette with solution and record initial reading", "Use a pipette safely and consistently", "Identify a rough titre, then obtain concordant titres", "Record readings to the correct precision", "Calculate mean titre only from concordant values", "State a suitable improvement or precaution"]
        case "qualitative": return ["Describe colour, precipitate and effervescence precisely", "Use small portions and separate tests", "Confirm gases with the appropriate test", "Distinguish observation from inference", "Use solubility in excess reagent where relevant", "Write a conclusion supported by observations"]
        case "rates": return ["State independent, dependent and controlled variables", "Choose a measurable endpoint", "Repeat measurements", "Tabulate values with units", "Plot a suitable graph and inspect anomalies", "Explain limitations and improvements"]
        default: return ["Identify hazards and precautions", "Select apparatus with suitable precision", "Record observations before explanations", "Include units and appropriate decimal places", "Show calculations clearly", "Evaluate accuracy, reliability and validity"]
        }
    }
    var body: some View {
        List {
            Section("Before you start") { Text(topic.notes).font(.subheadline).foregroundStyle(.secondary) }
            Section("Mastery checklist") {
                ForEach(items, id: \.self) { item in
                    Button { if checked.contains(item) { checked.remove(item) } else { checked.insert(item) } } label: {
                        Label(item, systemImage: checked.contains(item) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(checked.contains(item) ? Color.green : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            Section { Text("This checklist is a study aid, not an official SEAB mark scheme. Follow your school's laboratory safety rules and the instructions in the examination.").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("Practical checklist")
    }
}
