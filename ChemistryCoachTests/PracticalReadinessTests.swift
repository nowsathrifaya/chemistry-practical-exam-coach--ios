import XCTest
@testable import ChemistryCoach

final class PracticalReadinessTests: XCTestCase {
    func testSingaporeProfileIsTheOnlySelectableCurriculum() {
        XCTAssertEqual(CurriculumProfiles.forCurriculum(.singapore).paperCode, "6092")
        XCTAssertEqual(CurriculumProfiles.forCurriculum(.general).paperCode, "6092")
    }

    func testReadinessIsEmptyWithoutEvidence() {
        let result = PracticalReadinessCalculator.compute(attempts: [], curriculum: .singapore)
        XCTAssertNil(result.overall)
        XCTAssertNil(result.weakest)
    }

    func testReadinessClassifiesModesIntoExamSkills() {
        let apparatus = Attempt(curriculum: .singapore, mode: .apparatusPractice, target: "Burette", startedAt: .now, completedAt: .now, score: 8, maxScore: 10, feedback: [])
        let graph = Attempt(curriculum: .singapore, mode: .graphCoach, target: "Graph", startedAt: .now, completedAt: .now, score: 7, maxScore: 10, feedback: [])
        let ace = Attempt(curriculum: .singapore, mode: .acePractice, target: "ACE", startedAt: .now, completedAt: .now, score: 6, maxScore: 10, feedback: [])
        let result = PracticalReadinessCalculator.compute(attempts: [apparatus, graph, ace], curriculum: .singapore)
        XCTAssertNotNil(result.overall)
        XCTAssertEqual(result.skills.first(where: { $0.skill == .mmo })?.score, 80)
        XCTAssertEqual(result.skills.first(where: { $0.skill == .pdo })?.score, 70)
        XCTAssertEqual(result.skills.first(where: { $0.skill == .ace })?.score, 60)
    }
}
