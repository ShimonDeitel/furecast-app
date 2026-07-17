import Foundation
import SwiftData
import SwiftUI

/// The two species this batch's hand-written breed catalog covers. Kept as a small closed
/// enum (rather than free text) so every breed profile and pet is always in sync with the
/// catalog's lookup keys.
enum PetSpecies: String, Codable, CaseIterable, Identifiable {
    case dog = "Dog"
    case cat = "Cat"
    var id: String { rawValue }
}

/// Manual expense categories. `food`/`supplies` and similar routine categories are never
/// breed-risk flagged — only an expense the owner explicitly ties to one of the pet's
/// predicted `BreedRiskFlag`s counts toward the surprise jar.
enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food, routineVet, emergencyVet, grooming, supplies, medication, insurance, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .food: return "Food"
        case .routineVet: return "Routine Vet"
        case .emergencyVet: return "Emergency Vet"
        case .grooming: return "Grooming"
        case .supplies: return "Supplies"
        case .medication: return "Medication"
        case .insurance: return "Insurance"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .routineVet: return "stethoscope"
        case .emergencyVet: return "cross.case.fill"
        case .grooming: return "scissors"
        case .supplies: return "bag.fill"
        case .medication: return "pills.fill"
        case .insurance: return "shield.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// A pet the owner tracks. Free tier allows exactly one `Pet` with no `breedName` (no
/// prediction). Pro unlocks additional pets and a breed-based prediction snapshot, captured
/// at creation time so later edits to `BreedCatalog` never silently rewrite a pet's history.
@Model
final class Pet {
    var id: UUID
    var name: String
    var speciesRaw: String
    var breedName: String?
    var adoptionDate: Date
    var createdAt: Date

    /// Prediction snapshot — all nil for a free-tier, no-prediction pet.
    var predictedAnnualLow: Double?
    var predictedAnnualMid: Double?
    var predictedAnnualHigh: Double?
    var riskFlagsData: Data?

    @Relationship(deleteRule: .cascade, inverse: \Expense.pet)
    var expenses: [Expense] = []

    init(name: String, species: PetSpecies, adoptionDate: Date, breedProfile: BreedProfile? = nil) {
        self.id = UUID()
        self.name = name
        self.speciesRaw = species.rawValue
        self.adoptionDate = adoptionDate
        self.createdAt = .now
        if let breedProfile {
            self.breedName = breedProfile.name
            self.predictedAnnualLow = breedProfile.predictedAnnualLow
            self.predictedAnnualMid = breedProfile.predictedAnnualMid
            self.predictedAnnualHigh = breedProfile.predictedAnnualHigh
            self.riskFlagsData = try? JSONEncoder().encode(breedProfile.riskFlags)
        }
    }

    var species: PetSpecies { PetSpecies(rawValue: speciesRaw) ?? .dog }

    var hasPrediction: Bool { predictedAnnualMid != nil }

    var riskFlags: [BreedRiskFlag] {
        guard let riskFlagsData else { return [] }
        return (try? JSONDecoder().decode([BreedRiskFlag].self, from: riskFlagsData)) ?? []
    }
}

/// One manually-logged expense. `matchedRiskFlagTitle` is set only when the owner ties this
/// expense to one of the pet's predicted risk flags — that's the entire surprise-jar
/// mechanism: routine costs are never counted, only flagged ones the owner confirms.
@Model
final class Expense {
    var id: UUID
    var date: Date
    var amount: Double
    var categoryRaw: String
    var note: String
    var matchedRiskFlagTitle: String?
    var createdAt: Date
    var pet: Pet?

    init(date: Date, amount: Double, category: ExpenseCategory, note: String, matchedRiskFlagTitle: String?, pet: Pet?) {
        self.id = UUID()
        self.date = date
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.note = note
        self.matchedRiskFlagTitle = matchedRiskFlagTitle
        self.createdAt = .now
        self.pet = pet
    }

    var category: ExpenseCategory { ExpenseCategory(rawValue: categoryRaw) ?? .other }
}

/// Plain, `Codable`, non-SwiftData mirror of the fields `PredictionEngine` needs from an
/// `Expense`. Keeping the pure logic decoupled from `@Model` types is what makes
/// `PredictionEngine` trivially unit-testable without a `ModelContainer`.
struct ExpenseRecord: Hashable {
    let amount: Double
    let matchedRiskFlagTitle: String?
}

extension Expense {
    var asRecord: ExpenseRecord { ExpenseRecord(amount: amount, matchedRiskFlagTitle: matchedRiskFlagTitle) }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
