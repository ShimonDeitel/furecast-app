import SwiftUI

/// Manual expense entry — available on every tier. The one Pro-adjacent twist is the
/// "surprise jar" tag: if this pet has a breed prediction, the owner can tie this expense to
/// one of its specific predicted risk flags, which is the only thing that ever counts toward
/// the surprise jar.
struct ExpenseLogView: View {
    let pet: Pet
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var date = Date()
    @State private var note = ""
    @State private var matchedFlagTitle: String?

    private var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.label, systemImage: cat.icon).tag(cat)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note)
                }

                if pet.hasPrediction, !pet.riskFlags.isEmpty {
                    Section {
                        Picker("Tag as predicted risk", selection: $matchedFlagTitle) {
                            Text("Not a flagged risk").tag(String?.none)
                            ForEach(pet.riskFlags) { flag in
                                Text(flag.title).tag(Optional(flag.title))
                            }
                        }
                    } header: {
                        Text("Surprise Jar")
                    } footer: {
                        Text("Only tag this if it's genuinely one of the specific risks Furecast predicted for \(pet.name)'s breed — that's what keeps the surprise jar honest.")
                    }
                }
            }
            .navigationTitle("Log Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount, amount > 0 else { return }
                        model.addExpense(to: pet, date: date, amount: amount, category: category, note: note, matchedRiskFlagTitle: matchedFlagTitle)
                        Haptics.success()
                        dismiss()
                    }
                    .disabled((amount ?? 0) <= 0)
                }
            }
        }
    }
}
