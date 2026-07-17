import Foundation

/// Pure, deterministic math behind the predicted-vs-actual piggy bank and the surprise jar.
/// Nothing here touches SwiftData, StoreKit, or the network, so every function is directly
/// unit-testable with hand-verified numbers.
enum PredictionEngine {
    /// Average seconds in one month (365.25 / 12 days), used so "elapsed months" is a plain,
    /// reproducible number rather than something that depends on `Calendar` component
    /// arithmetic (which varies with month length and time zone).
    static let secondsPerMonth: Double = 365.25 / 12 * 24 * 60 * 60 // 2,629,800

    /// Fractional months between two dates. Negative if `end` is before `start`.
    static func monthsBetween(_ start: Date, _ end: Date) -> Double {
        end.timeIntervalSince(start) / secondsPerMonth
    }

    /// How far into the pet's first predicted year "now" falls, clamped to [0, 1]. This
    /// fraction is both the height of the predicted-line marker in the piggy bank (as a
    /// fraction of the container) and the basis for `expectedSpendByNow`.
    static func elapsedFraction(adoptionDate: Date, now: Date, horizonMonths: Double = 12) -> Double {
        guard horizonMonths > 0 else { return 0 }
        let months = monthsBetween(adoptionDate, now)
        return min(max(months / horizonMonths, 0), 1)
    }

    /// The dollar amount the app expected to have been spent by now, linearly interpolated
    /// across the predicted annual (mid-estimate) total.
    static func expectedSpendByNow(predictedAnnualMid: Double, elapsedFraction: Double) -> Double {
        predictedAnnualMid * elapsedFraction
    }

    static func totalSpend(_ expenses: [ExpenseRecord]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    /// Only expenses the owner tagged against one of the pet's predicted risk flags — the
    /// entire point of the surprise jar is that it counts NONE of the routine spend.
    static func surpriseJarTotal(_ expenses: [ExpenseRecord]) -> Double {
        expenses.filter { $0.matchedRiskFlagTitle != nil }.reduce(0) { $0 + $1.amount }
    }

    static func routineSpend(_ expenses: [ExpenseRecord]) -> Double {
        totalSpend(expenses) - surpriseJarTotal(expenses)
    }

    /// Positive means actual spend is running ahead of (over) where the prediction expected
    /// it to be by now; negative means the pet is costing less than expected so far.
    static func paceDelta(actualSoFar: Double, expectedByNow: Double) -> Double {
        actualSoFar - expectedByNow
    }

    /// Piggy-bank fill height as a fraction of the container (which represents the full
    /// predicted annual mid-estimate). Allowed to run slightly past 1.0 so an over-budget
    /// pet visibly overflows the silhouette rather than silently capping at the rim; clamped
    /// at 1.25 so the view never has to draw an unbounded fill.
    static func fillFraction(actualSoFar: Double, predictedAnnualMid: Double) -> Double {
        guard predictedAnnualMid > 0 else { return 0 }
        return min(max(actualSoFar / predictedAnnualMid, 0), 1.25)
    }

    /// Per-risk-flag falsifiability check for the Predict vs Actual report: for each flag the
    /// prediction warned about, how much has actually been tagged against it so far (0 means
    /// that specific warning hasn't materialized yet).
    static func surpriseJarBreakdown(flags: [BreedRiskFlag], expenses: [ExpenseRecord]) -> [(flag: BreedRiskFlag, actualSoFar: Double)] {
        flags.map { flag in
            let matched = expenses.filter { $0.matchedRiskFlagTitle == flag.title }.reduce(0) { $0 + $1.amount }
            return (flag, matched)
        }
    }
}
