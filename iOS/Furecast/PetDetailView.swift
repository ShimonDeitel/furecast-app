import SwiftUI

struct PetDetailView: View {
    let pet: Pet
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: Store

    @State private var showLogExpense = false
    @State private var showPaywall = false
    @State private var showReport = false
    @State private var showDeleteConfirm = false

    @State private var aiResult: AICoachingResult?
    @State private var aiRawFallback: String?
    @State private var aiError: String?
    @State private var aiLoading = false

    private var expenses: [Expense] { model.expenses(for: pet) }
    private var records: [ExpenseRecord] { expenses.map { $0.asRecord } }

    private var totalSpend: Double { PredictionEngine.totalSpend(records) }
    private var surpriseJarTotal: Double { PredictionEngine.surpriseJarTotal(records) }
    private var routineSpend: Double { PredictionEngine.routineSpend(records) }

    private var elapsedFraction: Double {
        PredictionEngine.elapsedFraction(adoptionDate: pet.adoptionDate, now: .now)
    }
    private var expectedByNow: Double {
        guard let mid = pet.predictedAnnualMid else { return 0 }
        return PredictionEngine.expectedSpendByNow(predictedAnnualMid: mid, elapsedFraction: elapsedFraction)
    }
    private var paceDelta: Double { PredictionEngine.paceDelta(actualSoFar: totalSpend, expectedByNow: expectedByNow) }
    private var fillFraction: Double {
        guard let mid = pet.predictedAnnualMid else { return 0 }
        return PredictionEngine.fillFraction(actualSoFar: totalSpend, predictedAnnualMid: mid)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if pet.hasPrediction {
                    piggyBankCard
                    surpriseJarCard
                    aiCoachingCard
                    reportLink
                } else {
                    noPredictionUpsell
                }

                statsCard
                logExpenseButton
                expenseHistoryCard

                Button("Remove This Pet", role: .destructive) { showDeleteConfirm = true }
                    .font(.footnote)
                    .foregroundStyle(FurecastColor.inkMuted)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
            .padding(.top, 8)
        }
        .background(FurecastColor.canvas.ignoresSafeArea())
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogExpense) { ExpenseLogView(pet: pet) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showReport) { PredictionReportView(pet: pet) }
        .alert("Remove \(pet.name)?", isPresented: $showDeleteConfirm) {
            Button("Remove", role: .destructive) { model.deletePet(pet) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes \(pet.name) and every logged expense. This can't be undone.")
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(pet.breedName ?? pet.species.rawValue)
                .font(.subheadline)
                .foregroundStyle(FurecastColor.inkMuted)
            Text("Adopted \(pet.adoptionDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(FurecastColor.inkMuted)
        }
    }

    private var piggyBankCard: some View {
        PawCard {
            Text("PREDICTED VS ACTUAL").font(FurecastFont.caption()).foregroundStyle(FurecastColor.inkMuted).tracking(1.0)
            HStack(alignment: .top, spacing: 20) {
                PiggyBankView(fillFraction: fillFraction, predictedFraction: elapsedFraction, isOverPace: paceDelta > 0)
                    .frame(width: 130, height: 170)
                VStack(alignment: .leading, spacing: 12) {
                    StatTile(label: "Spent so far", value: Money.format(totalSpend), valueColor: FurecastColor.coralDeep)
                    StatTile(label: "Expected by now", value: Money.format(expectedByNow), valueColor: FurecastColor.sageDeep)
                    StatTile(label: "Predicted year", value: Money.format(pet.predictedAnnualMid ?? 0))
                }
            }
            Text(paceDescription)
                .font(.footnote)
                .foregroundStyle(paceDelta > 0 ? FurecastColor.jarAmber : FurecastColor.sageDeep)
        }
    }

    private var paceDescription: String {
        let amount = Money.format(abs(paceDelta))
        if abs(paceDelta) < 1 { return "Right on the predicted pace so far." }
        return paceDelta > 0
            ? "\(amount) ahead of what was expected by now."
            : "\(amount) under what was expected by now."
    }

    private var surpriseJarCard: some View {
        PawCard {
            HStack {
                Image(systemName: "seal.fill").foregroundStyle(FurecastColor.jarAmber)
                Text("SURPRISE JAR").font(FurecastFont.caption()).foregroundStyle(FurecastColor.inkMuted).tracking(1.0)
                Spacer()
                Text(Money.format(surpriseJarTotal)).font(FurecastFont.value(18)).foregroundStyle(FurecastColor.jarAmber)
            }
            Text("Only expenses tagged to a specific predicted risk land here — never routine food, litter, or supplies. It's the falsifiable test of \(pet.name)'s prediction.")
                .font(.footnote).foregroundStyle(FurecastColor.inkMuted)

            let breakdown = PredictionEngine.surpriseJarBreakdown(flags: pet.riskFlags, expenses: records)
            ForEach(breakdown, id: \.flag.id) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.flag.title).font(FurecastFont.headline(14)).foregroundStyle(FurecastColor.ink)
                        Text(item.actualSoFar > 0 ? "Materialized" : "Not seen yet")
                            .font(.caption)
                            .foregroundStyle(item.actualSoFar > 0 ? FurecastColor.jarAmber : FurecastColor.inkMuted)
                    }
                    Spacer(minLength: 8)
                    Text(Money.format(item.actualSoFar)).font(FurecastFont.body()).foregroundStyle(FurecastColor.ink)
                }
            }
        }
    }

    @ViewBuilder
    private var aiCoachingCard: some View {
        PawCard {
            Text("AI SURPRISE-RISK COACH").font(FurecastFont.caption()).foregroundStyle(FurecastColor.inkMuted).tracking(1.0)

            if !store.isPro {
                ProLockedRow(title: "AI coaching", subtitle: "Get tailored risk flags and a savings tip.") {
                    Haptics.tap(); showPaywall = true
                }
            } else if aiLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Asking the AI coach…").font(.footnote).foregroundStyle(FurecastColor.inkMuted)
                }
            } else if let aiResult {
                ForEach(aiResult.risks) { risk in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(risk.title).font(FurecastFont.headline(14)).foregroundStyle(FurecastColor.ink)
                            Spacer(minLength: 8)
                            Text(risk.range).font(.footnote).foregroundStyle(FurecastColor.jarAmber)
                        }
                        Text(risk.why).font(.caption).foregroundStyle(FurecastColor.inkMuted)
                    }
                }
                Divider().overlay(FurecastColor.hairline)
                Label(aiResult.tip, systemImage: "lightbulb.fill")
                    .font(.footnote)
                    .foregroundStyle(FurecastColor.sageDeep)
                Button("Ask Again") { Task { await runAI() } }.pawPanelButton()
            } else if let aiRawFallback {
                Text(aiRawFallback).font(.footnote).foregroundStyle(FurecastColor.ink)
                Button("Ask Again") { Task { await runAI() } }.pawPanelButton()
            } else if let aiError {
                Text(aiError).font(.footnote).foregroundStyle(FurecastColor.inkMuted)
                Button("Try Again") { Task { await runAI() } }.pawPanelButton()
            } else {
                Button {
                    Task { await runAI() }
                } label: {
                    Label("Get AI Insights", systemImage: "sparkles").frame(maxWidth: .infinity)
                }
                .prominentCoralButton()
            }
        }
    }

    private var reportLink: some View {
        Button {
            if store.isPro { Haptics.click(); showReport = true } else { Haptics.tap(); showPaywall = true }
        } label: {
            Label(store.isPro ? "Predict vs Actual Report" : "Predict vs Actual Report (Pro)", systemImage: "chart.xyaxis.line")
                .frame(maxWidth: .infinity)
        }
        .pawPanelButton()
    }

    private var noPredictionUpsell: some View {
        PawCard {
            Text("No cost prediction yet").font(FurecastFont.headline(16)).foregroundStyle(FurecastColor.ink)
            Text("Furecast can only predict \(pet.name)'s true cost, run the surprise jar, and coach you on risks once it knows the breed. Free plan tracks manual expenses only.")
                .font(.footnote).foregroundStyle(FurecastColor.inkMuted)
            Button {
                Haptics.tap(); showPaywall = true
            } label: {
                Label("Unlock Breed Prediction", systemImage: "sparkles").frame(maxWidth: .infinity)
            }
            .prominentCoralButton()
        }
    }

    private var statsCard: some View {
        PawCard {
            HStack {
                StatTile(label: "Total Spent", value: Money.format(totalSpend))
                StatTile(label: "Routine", value: Money.format(routineSpend))
                StatTile(label: "Surprise Jar", value: Money.format(surpriseJarTotal), valueColor: FurecastColor.jarAmber)
            }
        }
    }

    private var logExpenseButton: some View {
        Button {
            Haptics.tap(); showLogExpense = true
        } label: {
            Label("Log an Expense", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
        }
        .prominentCoralButton()
    }

    @ViewBuilder
    private var expenseHistoryCard: some View {
        if !expenses.isEmpty {
            PawCard {
                Text("RECENT EXPENSES").font(FurecastFont.caption()).foregroundStyle(FurecastColor.inkMuted).tracking(1.0)
                ForEach(expenses.prefix(8), id: \.id) { expense in
                    HStack(spacing: 10) {
                        Image(systemName: expense.category.icon).foregroundStyle(FurecastColor.sage).frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(expense.note.isEmpty ? expense.category.label : expense.note)
                                .font(FurecastFont.body(14)).foregroundStyle(FurecastColor.ink)
                            Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2).foregroundStyle(FurecastColor.inkMuted)
                        }
                        Spacer(minLength: 8)
                        if expense.matchedRiskFlagTitle != nil {
                            Image(systemName: "seal.fill").font(.caption).foregroundStyle(FurecastColor.jarAmber)
                        }
                        Text(Money.format(expense.amount)).font(FurecastFont.body()).foregroundStyle(FurecastColor.ink)
                        Button {
                            Haptics.warning()
                            model.deleteExpense(expense)
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(FurecastColor.inkMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func runAI() async {
        aiLoading = true
        aiError = nil
        aiResult = nil
        aiRawFallback = nil
        defer { aiLoading = false }

        let months = PredictionEngine.monthsBetween(pet.adoptionDate, .now)
        let ageDescription = months < 1 ? "just adopted" : String(format: "%.0f months since adoption", months)

        let summary: String
        if expenses.isEmpty {
            summary = "no expenses logged yet"
        } else {
            let grouped = Dictionary(grouping: expenses, by: { $0.category })
            let parts = grouped.map { "\($0.key.label): \(Money.format($0.value.reduce(0) { $0 + $1.amount }))" }
            summary = parts.joined(separator: ", ") + "; surprise jar so far: \(Money.format(surpriseJarTotal))"
        }

        do {
            let content = try await AIProxyClient().complete(
                systemPrompt: AICoach.systemPrompt(),
                userPrompt: AICoach.userPrompt(
                    species: pet.species.rawValue,
                    breed: pet.breedName ?? "unknown",
                    ageDescription: ageDescription,
                    expenseSummary: summary
                )
            )
            if let parsed = AICoach.parse(content) {
                aiResult = parsed
            } else {
                aiRawFallback = content
            }
        } catch let error as AIProxyError {
            aiError = error.userMessage
        } catch {
            aiError = "Something went wrong reaching the AI coach. Try again in a moment."
        }
    }
}
