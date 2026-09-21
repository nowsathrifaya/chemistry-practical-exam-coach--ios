//
//  PracticeHubView.swift
//  ChemistryCoach
//
//  The "Practice" tab: fans out into every gradeable and exam-practice mode.
//

import SwiftUI

struct PracticeHubView: View {
    let homeViewModel: HomeViewModel
    @Environment(\.modelContext) private var modelContext
    private var profile: CurriculumProfile { CurriculumProfiles.forCurriculum(homeViewModel.curriculum) }

    var body: some View {
        List {
            Section("Graded practice") {
                NavigationLink {
                    ApparatusListView(profile: profile)
                } label: {
                    Label("Apparatus reading", systemImage: "ruler.fill")
                }
                NavigationLink {
                    GraphCoachListView(profile: profile)
                } label: {
                    Label("Graph Coach", systemImage: "chart.xyaxis.line")
                }
                NavigationLink {
                    AceListView(curriculum: homeViewModel.curriculum)
                } label: {
                    Label("ACE written practice", systemImage: "checkmark.seal.fill")
                }
                NavigationLink {
                    CalculationPracticeView()
                } label: {
                    Label("Calculation practice", systemImage: "function")
                }
            }

            Section("Practical labs") {
                NavigationLink {
                    SimulationListView(profile: profile)
                } label: {
                    Label("Graded practical labs", systemImage: "flask.fill")
                }
            }

            Section("Exam practice") {
                NavigationLink {
                    StructuredMockExamView()
                } label: {
                    Label("Full Paper 3 mock · 40 marks · 1h 50m", systemImage: "doc.text.fill")
                }
                NavigationLink {
                    MockPracticalView(curriculum: homeViewModel.curriculum)
                } label: {
                    Label("Practical mock questions", systemImage: "pencil.line")
                }
                NavigationLink {
                    AcePracticeSessionView(
                        repository: AttemptRepository(modelContext: modelContext),
                        curriculum: homeViewModel.curriculum, filterTopic: nil, filterSkill: nil,
                        isMockExam: true, mockExamMinutes: profile.durationMinutes
                    )
                } label: {
                    Label("Timed Paper 3 session", systemImage: "timer")
                }
            }

            Section("Reference") {
                NavigationLink {
                    CompleteReferenceView()
                } label: {
                    Label("Practical reference tables", systemImage: "text.book.closed.fill")
                }
            }
        }
        .navigationTitle("Practice")
    }
}
