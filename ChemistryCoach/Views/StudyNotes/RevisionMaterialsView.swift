import SwiftUI

struct RevisionMaterialsView: View {
    @State private var selected: RevisionMaterial?
    var body: some View {
        List(RevisionMaterialCatalog.materials) { material in
            Button { selected = material } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(material.title).font(.headline)
                    Text("Open revision material").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("6092 Revision Materials")
        .sheet(item: $selected) { material in
            NavigationStack { RevisionMaterialReader(material: material) }
        }
    }
}

private struct RevisionMaterialReader: View {
    let material: RevisionMaterial
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            Text(content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding()
        }
        .navigationTitle(material.title)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
    }
    private var content: String {
        guard let url = Bundle.main.url(forResource: material.fileName, withExtension: "txt", subdirectory: "RevisionMaterials"), let text = try? String(contentsOf: url) else { return "Material unavailable." }
        return text
    }
}
