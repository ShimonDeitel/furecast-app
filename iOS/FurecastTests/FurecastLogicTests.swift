import XCTest
@testable import Furecast

/// Every expected value below was hand-computed before being hardcoded here (see comments per
/// test) — this covers `PredictionEngine`'s pure math, the hand-written `BreedCatalog`
/// dataset, and `AICoach`'s JSON-in-a-string parser, none of which touch SwiftData, StoreKit,
/// or the network.
final class FurecastLogicTests: XCTestCase {

    private func fixedDate() -> Date {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 1; comps.hour = 0; comps.minute = 0; comps.second = 0
        let cal = Calendar(identifier: .gregorian)
        return cal.date(from: comps)!
    }

    private func monthsLater(_ n: Double, from start: Date) -> Date {
        start.addingTimeInterval(n * PredictionEngine.secondsPerMonth)
    }

    // MARK: BreedCatalog

    func testBreedCatalogFrenchBulldogPredictedCosts() {
        // baseline 1400 + risks (1500-4500, 200-600, 1500-4000):
        // low  = 1400 + 1500 + 200 + 1500 = 4600
        // high = 1400 + 4500 + 600 + 4000 = 10500
        // mid  = 1400 + 3000 + 400 + 2750 = 7550
        let profile = BreedCatalog.profile(species: .dog, name: "French Bulldog")
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.predictedAnnualLow, 4600)
        XCTAssertEqual(profile?.predictedAnnualHigh, 10500)
        XCTAssertEqual(profile?.predictedAnnualMid, 7550)
    }

    func testBreedCatalogCoverageCounts() {
        XCTAssertEqual(BreedCatalog.profiles.count, 18)
        XCTAssertEqual(BreedCatalog.profiles(for: .dog).count, 12)
        XCTAssertEqual(BreedCatalog.profiles(for: .cat).count, 6)
    }

    // MARK: PredictionEngine — elapsed time

    func testElapsedFractionAtHalfYear() {
        let start = fixedDate()
        let now = monthsLater(6, from: start)
        XCTAssertEqual(PredictionEngine.elapsedFraction(adoptionDate: start, now: now), 0.5, accuracy: 0.0001)
    }

    func testElapsedFractionClampsAtOneAfterFullYear() {
        let start = fixedDate()
        let now = monthsLater(18, from: start) // 1.5 years in, should clamp to 1.0
        XCTAssertEqual(PredictionEngine.elapsedFraction(adoptionDate: start, now: now), 1.0, accuracy: 0.0001)
    }

    func testExpectedSpendByNowScalesLinearly() {
        XCTAssertEqual(PredictionEngine.expectedSpendByNow(predictedAnnualMid: 6000, elapsedFraction: 0.5), 3000)
    }

    // MARK: PredictionEngine — surprise jar

    func testSurpriseJarOnlyCountsTaggedExpenses() {
        let records = [
            ExpenseRecord(amount: 50, matchedRiskFlagTitle: nil),
            ExpenseRecord(amount: 200, matchedRiskFlagTitle: "Hip dysplasia treatment"),
            ExpenseRecord(amount: 30, matchedRiskFlagTitle: nil)
        ]
        XCTAssertEqual(PredictionEngine.surpriseJarTotal(records), 200)
    }

    func testRoutineSpendExcludesTaggedExpenses() {
        let records = [
            ExpenseRecord(amount: 50, matchedRiskFlagTitle: nil),
            ExpenseRecord(amount: 200, matchedRiskFlagTitle: "Hip dysplasia treatment"),
            ExpenseRecord(amount: 30, matchedRiskFlagTitle: nil)
        ]
        // total 280, surprise jar 200 -> routine 80
        XCTAssertEqual(PredictionEngine.routineSpend(records), 80)
    }

    func testFillFractionClampsAboveOverspend() {
        // 9000 / 6000 = 1.5, clamped down to the view's 1.25 overflow ceiling
        XCTAssertEqual(PredictionEngine.fillFraction(actualSoFar: 9000, predictedAnnualMid: 6000), 1.25)
    }

    func testFillFractionIsZeroWithNoPrediction() {
        XCTAssertEqual(PredictionEngine.fillFraction(actualSoFar: 100, predictedAnnualMid: 0), 0)
    }

    // MARK: AICoach parsing

    func testAICoachParsesWellFormedJSON() {
        let content = """
        Sure, here you go:
        {"risks":[{"title":"Hip dysplasia","range":"$1500-$4000","why":"Large-breed joint risk."}],"tip":"Consider pet insurance while your pet is still young."}
        """
        let result = AICoach.parse(content)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.risks.count, 1)
        XCTAssertEqual(result?.risks.first?.title, "Hip dysplasia")
        XCTAssertEqual(result?.tip, "Consider pet insurance while your pet is still young.")
    }

    func testAICoachReturnsNilForGarbageContent() {
        let content = "Sorry, I can't help with that right now."
        XCTAssertNil(AICoach.parse(content))
    }
}
