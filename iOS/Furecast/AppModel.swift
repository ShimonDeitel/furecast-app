import Foundation
import SwiftData
import SwiftUI

/// App state: owns the SwiftData store (pets/expenses), CRUD for both, and the free/Pro pet
/// cap. Pro itself is always read live from `Store` — never persisted here.
@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    /// Free tier: manual expense logging for exactly one pet, no breed prediction. Pro:
    /// unlimited pets, each optionally carrying a breed-based prediction.
    static let freeMaxPets = 1

    private static let selectedPetKey = "furecast.selectedPetID"

    @Published var selectedPetIDString: String? {
        didSet { UserDefaults.standard.set(selectedPetIDString, forKey: Self.selectedPetKey) }
    }

    init(container: ModelContainer) {
        self.container = container
        self.selectedPetIDString = UserDefaults.standard.string(forKey: Self.selectedPetKey)
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([Pet.self, Expense.self])
        let local = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    // MARK: Pets

    func pets() -> [Pet] {
        var descriptor = FetchDescriptor<Pet>()
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .forward)]
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }

    var selectedPet: Pet? {
        let all = pets()
        if let idString = selectedPetIDString, let match = all.first(where: { $0.id.uuidString == idString }) {
            return match
        }
        return all.first
    }

    func canAddPet(isPro: Bool) -> Bool {
        isPro || pets().count < Self.freeMaxPets
    }

    /// Free-tier pets may never carry a breed prediction, regardless of what's passed in —
    /// the prediction itself is the Pro feature, not just having more than one pet.
    @discardableResult
    func addPet(name: String, species: PetSpecies, adoptionDate: Date, breedProfile: BreedProfile?, isPro: Bool) -> Pet {
        let profile = isPro ? breedProfile : nil
        let pet = Pet(name: name.trimmingCharacters(in: .whitespacesAndNewlines), species: species, adoptionDate: adoptionDate, breedProfile: profile)
        container.mainContext.insert(pet)
        try? container.mainContext.save()
        selectedPetIDString = pet.id.uuidString
        objectWillChange.send()
        return pet
    }

    func selectPet(_ pet: Pet) {
        selectedPetIDString = pet.id.uuidString
    }

    func deletePet(_ pet: Pet) {
        if selectedPetIDString == pet.id.uuidString { selectedPetIDString = nil }
        container.mainContext.delete(pet)
        try? container.mainContext.save()
        objectWillChange.send()
    }

    // MARK: Expenses

    @discardableResult
    func addExpense(to pet: Pet, date: Date, amount: Double, category: ExpenseCategory, note: String, matchedRiskFlagTitle: String?) -> Expense {
        let expense = Expense(date: date, amount: amount, category: category, note: note.trimmingCharacters(in: .whitespacesAndNewlines), matchedRiskFlagTitle: matchedRiskFlagTitle, pet: pet)
        container.mainContext.insert(expense)
        try? container.mainContext.save()
        objectWillChange.send()
        return expense
    }

    func deleteExpense(_ expense: Expense) {
        container.mainContext.delete(expense)
        try? container.mainContext.save()
        objectWillChange.send()
    }

    func expenses(for pet: Pet) -> [Expense] {
        pet.expenses.sorted { $0.date > $1.date }
    }

    // MARK: Data

    func deleteAllData() {
        try? container.mainContext.delete(model: Expense.self)
        try? container.mainContext.delete(model: Pet.self)
        try? container.mainContext.save()
        selectedPetIDString = nil
        objectWillChange.send()
    }
}
