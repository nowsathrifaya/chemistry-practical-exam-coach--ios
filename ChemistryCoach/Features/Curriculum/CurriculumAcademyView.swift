import SwiftUI

struct CurriculumAcademyView: View {
    var body: some View {
        NavigationStack {
            List(OLevelPracticalCurriculum.topics) { topic in
                NavigationLink(topic.title) {
                    TopicStudyView(topic: topic)
                }
            }
            .navigationTitle("O-Level Practical Academy")
        }
    }
}

struct TopicStudyView: View {
    let topic: CurriculumTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(topic.title)
                    .font(.largeTitle.bold())

                Text(topic.notes)
                    .font(.body)

                Text("Skills to master")
                    .font(.headline)

                ForEach(topic.skills) { skill in
                    Text("• \(skill.rawValue.capitalized)")
                }

                Text("Practice rule")
                    .font(.headline)

                Text("Complete the guided lab, review mistakes, then attempt an exam-style question without hints.")

                NavigationLink {
                    PracticalChecklistView(topic: topic)
                } label: {
                    Label("Open mastery checklist", systemImage: "checklist")
                }
            }
            .padding()
        }
        .navigationTitle("Study")
    }
}
