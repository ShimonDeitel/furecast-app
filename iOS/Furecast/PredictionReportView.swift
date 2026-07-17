import SwiftUI

/// Pro-only: the full predict-vs-actual breakdown, including a falsifiability check on every
/// single predicted risk flag (did this specific warning ever show up as a tagged expense).
struct PredictionReportView: View {
    let pet: Pet
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    private var expenses: [Expense] { model.expenses(for: pet) }
    private var records: [ExpenseRecord] { expenses.map { $0.asRecord } }
    private var totalSpend: Double { PredictionEngine.totalSpend(records) }
    private var elapsedFraction: Double { PredictionEngine.elapsedFraction(adoptionDate: pet.adoptionDate, now: .now) }
    private var expectedByNow: Double {
        guard let mid = pet.predictedAnnualMid else { return 0 }
        return PredictionEngine.expectedSpendByNow(predictedAnnualMid: mid, elapsedFraction: elapsedFraction)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    rangeCard
                    paceCard
                    riskFlagCard
                    categoryCard
                }
                .padding(16)
            }
            .background(FurecastColor.canvas.ignoresSafeArea())
            .navigationTitle("Predict vs Actual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private var rangeCard: some View {
        PawCard {
            Text("PREDICTED FIRST-YEAR RANGE").font(FurecastFont.caption()).foregroundStyle(FurecastColor.inkMuted).tracking(1.0)
            HStack {
                StatTile(label: "Low", value: Money.format(pet.predictedAnnualLow ?? 0))
                StatTile(label: "Expected", value: Money.format(pet.predictedAnnualMid ?? 0), valueColor: FurecastColor.coralDeep)
                StatTile(label: "High", value: Money.format(pet.predictedAnnualHigh ?? 0))
            }
        }
    }

    private var paceCard: some View {
        PawCard {
            Text("PACE SO FAR").font(FurecastFont.caption()).foregroundStyle(FurecastColor.inkMuted).tracking(1.0)
            HStack {
                StatTile(label: "Elapsed", value: "\(Int(elapsedFraction * 100))% of year")
                StatTile(label: "Expected by now", value: Money.format(expectedByNow))
                StatTile(label: "Actual so far", value: Money.format(totalSpend), valueColor: FurecastColor.coralDeep)
            }
        }
    }

    private var riskFlagCard: some View {
        PawCard {
            Text("RISK FLAG FALSIFIABILITY").font(FurecastFont.caption()).foregroundStyle(FurecastColor.inkMuted).tracking(1.0)
            Text("Every risk Furecast predicted for \(pet.name)'s breed, checked against what actually happened.")
                .font(.footnote).foregroundStyle(FurecastColor.inkMuted)

            let breakdown = PredictionEngine.surpriseJarBreakdown(flags: pet.riskFlags, expenses: records)
            ForEach(breakdown, id: \.flag.id) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.flag.title).font(FurecastFont.headline(14)).foregroundStyle(FurecastColor.ink)
                        Spacer(minLength: 8)
                        FurecastPill(
                            text: item.actualSoFar > 0 ? "Materialized" : "Not yet",
                            color: item.actualSoFar > 0 ? FurecastColor.jarAmber : FurecastColor.sage
                        )
                    }
                    Text("Predicted \(Money.format(item.flag.lowAnnualCost))–\(Money.format(item.flag.highAnnualCost)) · Logged \(Money.format(item.actualSoFar))")
                        .font(.caption)
                        .foregroundStyle(FurecastColor.inkMuted)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var categoryCard: some View {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        let rows = ExpenseCategory.allCases.compactMap { category -> (ExpenseCategory, Double)? in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items.reduce(0) { $0 + $1.amount })
        }
        return PawCard {
            Text("SPEND BY CATEGORY").font(FurecastFont.caption()).foregroundStyle(FurecastColor.inkMuted).tracking(1.0)
            if rows.isEmpty {
                Text("No expenses logged yet.").font(.footnote).foregroundStyle(FurecastColor.inkMuted)
            } else {
                ForEach(rows, id: \.0) { category, total in
                    HStack {
                        Image(systemName: category.icon).foregroundStyle(FurecastColor.sage).frame(width: 20)
                        Text(category.label).font(FurecastFont.body(14)).foregroundStyle(FurecastColor.ink)
                        Spacer()
                        Text(Money.format(total)).font(FurecastFont.body()).foregroundStyle(FurecastColor.ink)
                    }
                }
            }
        }
    }
}
