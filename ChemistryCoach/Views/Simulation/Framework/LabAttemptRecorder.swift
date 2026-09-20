import Foundation

@MainActor
struct LabAttemptRecorder {
    let repository: AttemptRepository
    let curriculum: Curriculum

    func record(experimentTitle: String, result: LabRunResult, maxScore: Int = 100) {
        repository.save(curriculum: curriculum, mode: .simulationLab, target: experimentTitle, score: result.score, maxScore: maxScore, feedback: result.feedback)
    }
}
