import XCTest
@testable import ChemistryCoach

final class ErrorTaxonomyTests: XCTestCase {
    func testMeniscusErrorIsDetected() {
        XCTAssertEqual(ErrorTaxonomy.infer(from: ["Check the meniscus at eye level"], target: "Titration"), .meniscus)
    }

    func testGraphScaleErrorIsDetected() {
        XCTAssertEqual(ErrorTaxonomy.infer(from: ["Use a sensible scale on the graph"], target: "Graph"), .graphScale)
    }
}
