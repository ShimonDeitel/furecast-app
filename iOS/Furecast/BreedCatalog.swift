import Foundation

/// One specific, falsifiable "surprise cost" risk tied to a breed trait (brachycephalic
/// airway, large-breed joints, a long coat, a long spine, etc). `lowAnnualCost`/
/// `highAnnualCost` are rough first-year dollar ranges for that risk actually materializing —
/// NOT a certainty, a thing to watch for. These titles are also the exact strings a logged
/// `Expense.matchedRiskFlagTitle` is tagged with, which is what makes the surprise jar
/// falsifiable: if a flag never gets tagged against a real expense, that specific warning
/// didn't come true for this pet.
struct BreedRiskFlag: Codable, Hashable, Identifiable {
    var id: String { title }
    let title: String
    let detail: String
    let lowAnnualCost: Double
    let highAnnualCost: Double
    var midAnnualCost: Double { (lowAnnualCost + highAnnualCost) / 2 }
}

/// A hand-written breed cost/health-risk profile. `baselineAnnualCost` covers routine,
/// non-breed-specific spend (food, litter, routine checkups, basic supplies) that every pet
/// of roughly this size/species needs regardless of breed — it is deliberately excluded from
/// the surprise jar. `riskFlags` are the breed-linked extras layered on top.
struct BreedProfile: Codable, Hashable, Identifiable {
    var id: String { "\(species.rawValue)|\(name)" }
    let species: PetSpecies
    let name: String
    /// Short note on why this breed carries its particular risk profile (body shape, coat,
    /// size class) — shown to the owner alongside the prediction so it reads as reasoning,
    /// not just a number.
    let notes: String
    let baselineAnnualCost: Double
    let riskFlags: [BreedRiskFlag]

    var predictedAnnualLow: Double { baselineAnnualCost + riskFlags.reduce(0) { $0 + $1.lowAnnualCost } }
    var predictedAnnualHigh: Double { baselineAnnualCost + riskFlags.reduce(0) { $0 + $1.highAnnualCost } }
    var predictedAnnualMid: Double { baselineAnnualCost + riskFlags.reduce(0) { $0 + $1.midAnnualCost } }
}

/// The bundled reference dataset — 12 dog breeds + 6 cat breeds, hand-written from
/// well-documented breed health/cost tendencies (brachycephalic airway risk, large/giant
/// breed joint and bloat risk, long-spine IVDD risk, long-coat grooming load, breed-linked
/// cardiac/kidney screening). Every dollar range is a rough planning estimate, not a
/// veterinary quote — the app is always explicit about that in the UI copy.
enum BreedCatalog {
    static let profiles: [BreedProfile] = [
        // MARK: Dogs

        BreedProfile(
            species: .dog, name: "French Bulldog",
            notes: "Brachycephalic (flat-faced) with a short, curved spine.",
            baselineAnnualCost: 1400,
            riskFlags: [
                BreedRiskFlag(title: "Brachycephalic airway surgery (BOAS)",
                    detail: "Flat-faced breeds often need surgery to widen airways for normal breathing; watch for snoring, exercise intolerance, or overheating.",
                    lowAnnualCost: 1500, highAnnualCost: 4500),
                BreedRiskFlag(title: "Chronic skin-fold dermatitis",
                    detail: "Facial and tail-pocket skin folds trap moisture and need regular cleaning; infections are common if skipped.",
                    lowAnnualCost: 200, highAnnualCost: 600),
                BreedRiskFlag(title: "IVDD-linked back injury",
                    detail: "The short, curved spine common to the breed raises the risk of a slipped disc needing surgery or crate-rest recovery.",
                    lowAnnualCost: 1500, highAnnualCost: 4000)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Bulldog",
            notes: "Brachycephalic with a heavy, stocky frame on short legs.",
            baselineAnnualCost: 1500,
            riskFlags: [
                BreedRiskFlag(title: "Brachycephalic airway surgery",
                    detail: "An even flatter face and heavier frame make breathing surgery more common and pricier than in other brachycephalic breeds.",
                    lowAnnualCost: 1800, highAnnualCost: 5000),
                BreedRiskFlag(title: "Hip dysplasia treatment",
                    detail: "A stocky frame on short legs stresses hip joints; X-rays and joint treatment are common by middle age.",
                    lowAnnualCost: 1500, highAnnualCost: 4000),
                BreedRiskFlag(title: "Skin-fold pyoderma",
                    detail: "Deep facial and tail folds need regular cleaning; recurring infections are one of the breed's most common vet visits.",
                    lowAnnualCost: 250, highAnnualCost: 700)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Pug",
            notes: "Brachycephalic, small, prone to weight gain.",
            baselineAnnualCost: 1200,
            riskFlags: [
                BreedRiskFlag(title: "Brachycephalic airway relief surgery",
                    detail: "Pugs share the flat-faced breathing risk; heat intolerance and snoring are early warning signs.",
                    lowAnnualCost: 1200, highAnnualCost: 3500),
                BreedRiskFlag(title: "Corneal ulcer or eye injury",
                    detail: "Prominent, shallow eye sockets make pugs prone to scratches and ulcers that need same-week vet care.",
                    lowAnnualCost: 300, highAnnualCost: 1200),
                BreedRiskFlag(title: "Obesity-linked joint strain",
                    detail: "Pugs gain weight easily on a normal diet, which accelerates joint wear; portion control is a real cost lever.",
                    lowAnnualCost: 400, highAnnualCost: 1000)
            ]
        ),
        BreedProfile(
            species: .dog, name: "German Shepherd",
            notes: "Large working breed, deep-chested.",
            baselineAnnualCost: 1600,
            riskFlags: [
                BreedRiskFlag(title: "Hip and elbow dysplasia treatment",
                    detail: "One of the breed's best-documented risks; joint X-rays, supplements, or surgery are common by age five to seven.",
                    lowAnnualCost: 2000, highAnnualCost: 6000),
                BreedRiskFlag(title: "Degenerative myelopathy monitoring",
                    detail: "A breed-linked spinal condition that causes gradual hind-leg weakness; monitoring and mobility aids add up over time.",
                    lowAnnualCost: 500, highAnnualCost: 2000),
                BreedRiskFlag(title: "Bloat (GDV) emergency surgery",
                    detail: "Deep-chested large breeds are at elevated risk for this sudden, life-threatening emergency.",
                    lowAnnualCost: 2500, highAnnualCost: 6000)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Labrador Retriever",
            notes: "Large, water-loving, food-motivated.",
            baselineAnnualCost: 1500,
            riskFlags: [
                BreedRiskFlag(title: "Hip dysplasia and joint treatment",
                    detail: "A well-known Labrador risk; expect joint supplements at minimum and possibly surgery.",
                    lowAnnualCost: 1500, highAnnualCost: 4500),
                BreedRiskFlag(title: "Chronic ear infections",
                    detail: "Floppy ears plus a love of water trap moisture, making ear infections a recurring, low-grade cost.",
                    lowAnnualCost: 150, highAnnualCost: 400),
                BreedRiskFlag(title: "Obesity-linked diabetes management",
                    detail: "Labradors are prone to overeating; long-term weight-linked health management is a real annual cost.",
                    lowAnnualCost: 300, highAnnualCost: 900)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Golden Retriever",
            notes: "Large, long double coat, elevated cancer rate.",
            baselineAnnualCost: 1700,
            riskFlags: [
                BreedRiskFlag(title: "Cancer screening and treatment",
                    detail: "Golden Retrievers have one of the highest breed-linked cancer rates; many owners budget for screening from middle age.",
                    lowAnnualCost: 2000, highAnnualCost: 8000),
                BreedRiskFlag(title: "Hip dysplasia treatment",
                    detail: "Shares the large-breed joint risk common to retrievers.",
                    lowAnnualCost: 1500, highAnnualCost: 4500),
                BreedRiskFlag(title: "Long-coat grooming",
                    detail: "The dense double coat needs regular professional grooming to avoid matting and skin issues.",
                    lowAnnualCost: 600, highAnnualCost: 1200)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Great Dane",
            notes: "Giant breed, deep-chested, rapid growth.",
            baselineAnnualCost: 2200,
            riskFlags: [
                BreedRiskFlag(title: "Bloat (GDV) emergency and preventive surgery",
                    detail: "Giant, deep-chested breeds carry the highest bloat risk of any dog; many owners opt for preventive surgery.",
                    lowAnnualCost: 2500, highAnnualCost: 6000),
                BreedRiskFlag(title: "Hip and joint treatment",
                    detail: "Rapid growth to a giant adult size puts real strain on developing joints.",
                    lowAnnualCost: 1800, highAnnualCost: 5000),
                BreedRiskFlag(title: "Cardiomyopathy monitoring",
                    detail: "Great Danes have an elevated rate of heart muscle disease; periodic cardiac screening is a recurring cost.",
                    lowAnnualCost: 500, highAnnualCost: 1500)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Dachshund",
            notes: "Long spine, short legs (chondrodystrophic build).",
            baselineAnnualCost: 1100,
            riskFlags: [
                BreedRiskFlag(title: "IVDD back surgery",
                    detail: "The breed's long spine and short legs make slipped discs one of the most common — and costly — dachshund emergencies.",
                    lowAnnualCost: 1500, highAnnualCost: 4500),
                BreedRiskFlag(title: "Dental disease treatment",
                    detail: "Small jaws crowd teeth, making cleanings and extractions more frequent than in larger breeds.",
                    lowAnnualCost: 300, highAnnualCost: 900)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Standard Poodle",
            notes: "Continuous-growth coat, medium-large size.",
            baselineAnnualCost: 1500,
            riskFlags: [
                BreedRiskFlag(title: "Continuous-growth coat grooming",
                    detail: "Unlike shedding breeds, a poodle's coat grows continuously and needs professional grooming every four to six weeks.",
                    lowAnnualCost: 900, highAnnualCost: 1800),
                BreedRiskFlag(title: "Hip dysplasia and Addison's disease monitoring",
                    detail: "Standard Poodles carry an elevated rate of both joint issues and this hormonal condition needing lifelong monitoring.",
                    lowAnnualCost: 500, highAnnualCost: 2500)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Shih Tzu",
            notes: "Brachycephalic and long-haired, small.",
            baselineAnnualCost: 1300,
            riskFlags: [
                BreedRiskFlag(title: "Brachycephalic breathing management",
                    detail: "A flatter face than most small breeds brings the same overheating and airway risk as bulldogs, at a smaller scale.",
                    lowAnnualCost: 800, highAnnualCost: 2500),
                BreedRiskFlag(title: "Long-coat grooming",
                    detail: "The floor-length double coat mats quickly without frequent professional grooming.",
                    lowAnnualCost: 700, highAnnualCost: 1400),
                BreedRiskFlag(title: "Eye ulcers from prominent eyes",
                    detail: "Large, shallow eye sockets scratch and ulcerate more easily than average.",
                    lowAnnualCost: 300, highAnnualCost: 900)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Chihuahua",
            notes: "Toy breed, small mouth, delicate knees.",
            baselineAnnualCost: 1000,
            riskFlags: [
                BreedRiskFlag(title: "Dental disease treatment",
                    detail: "A small mouth crowds teeth severely; dental cleanings and extractions are one of the breed's most predictable costs.",
                    lowAnnualCost: 400, highAnnualCost: 1200),
                BreedRiskFlag(title: "Patellar luxation surgery",
                    detail: "Toy breeds are prone to kneecaps that slip out of place, sometimes needing surgical correction.",
                    lowAnnualCost: 1500, highAnnualCost: 3500)
            ]
        ),
        BreedProfile(
            species: .dog, name: "Mixed Breed Dog",
            notes: "No single breed standard — lower certainty, wider range.",
            baselineAnnualCost: 1200,
            riskFlags: [
                BreedRiskFlag(title: "Unpredictable adult size and joint strain",
                    detail: "Without a known breed standard, adult size and joint stress are harder to predict — budget a cushion for growth-related vet visits.",
                    lowAnnualCost: 300, highAnnualCost: 1500)
            ]
        ),

        // MARK: Cats

        BreedProfile(
            species: .cat, name: "Persian",
            notes: "Brachycephalic and long-haired.",
            baselineAnnualCost: 1100,
            riskFlags: [
                BreedRiskFlag(title: "Chronic eye tearing and infection",
                    detail: "The Persian's flat face restricts tear drainage, leading to staining and recurring eye infections.",
                    lowAnnualCost: 200, highAnnualCost: 700),
                BreedRiskFlag(title: "Daily long-coat grooming",
                    detail: "The dense, long coat mats within days without near-daily brushing or professional grooming.",
                    lowAnnualCost: 500, highAnnualCost: 1000),
                BreedRiskFlag(title: "Polycystic kidney disease screening",
                    detail: "A well-documented breed-linked genetic condition; ultrasound screening and monitoring are a recurring cost.",
                    lowAnnualCost: 300, highAnnualCost: 1500)
            ]
        ),
        BreedProfile(
            species: .cat, name: "Maine Coon",
            notes: "Large-bodied, long-haired.",
            baselineAnnualCost: 1200,
            riskFlags: [
                BreedRiskFlag(title: "Hypertrophic cardiomyopathy screening",
                    detail: "One of the most common breed-linked heart conditions in cats; periodic cardiac ultrasound is often recommended.",
                    lowAnnualCost: 400, highAnnualCost: 2000),
                BreedRiskFlag(title: "Hip dysplasia treatment",
                    detail: "Unusually for a cat breed, Maine Coons' large size brings a dog-like risk of hip joint problems.",
                    lowAnnualCost: 800, highAnnualCost: 2500),
                BreedRiskFlag(title: "Heavy-coat grooming",
                    detail: "The long, shaggy coat needs more frequent brushing than a typical shorthair to prevent mats.",
                    lowAnnualCost: 300, highAnnualCost: 700)
            ]
        ),
        BreedProfile(
            species: .cat, name: "Siamese",
            notes: "Short-haired, vocal, active.",
            baselineAnnualCost: 900,
            riskFlags: [
                BreedRiskFlag(title: "Dental disease treatment",
                    detail: "Siamese cats are noted for above-average rates of gum disease requiring earlier, more frequent cleanings.",
                    lowAnnualCost: 300, highAnnualCost: 900),
                BreedRiskFlag(title: "Respiratory sensitivity",
                    detail: "The breed is prone to upper respiratory sensitivity that can mean more frequent vet visits for colds and coughs.",
                    lowAnnualCost: 200, highAnnualCost: 800)
            ]
        ),
        BreedProfile(
            species: .cat, name: "British Shorthair",
            notes: "Stocky build, calm temperament.",
            baselineAnnualCost: 950,
            riskFlags: [
                BreedRiskFlag(title: "Obesity-linked joint and diabetes management",
                    detail: "A stocky build and calm temperament make weight gain common, bringing joint and metabolic costs with it.",
                    lowAnnualCost: 300, highAnnualCost: 1200),
                BreedRiskFlag(title: "Cardiomyopathy screening",
                    detail: "British Shorthairs carry an elevated rate of the same heart condition seen in Maine Coons.",
                    lowAnnualCost: 400, highAnnualCost: 1800)
            ]
        ),
        BreedProfile(
            species: .cat, name: "Sphynx",
            notes: "Hairless, needs skin and temperature care.",
            baselineAnnualCost: 1300,
            riskFlags: [
                BreedRiskFlag(title: "Skin care for oil buildup and dermatitis",
                    detail: "With no coat to absorb natural oils, sphynx cats need regular bathing to prevent skin infections.",
                    lowAnnualCost: 300, highAnnualCost: 800),
                BreedRiskFlag(title: "Temperature regulation vet visits",
                    detail: "Hairlessness makes sphynx cats prone to both cold stress and sunburn, sometimes needing vet care.",
                    lowAnnualCost: 200, highAnnualCost: 600),
                BreedRiskFlag(title: "Cardiomyopathy screening",
                    detail: "Sphynx cats also carry an elevated rate of hypertrophic cardiomyopathy.",
                    lowAnnualCost: 400, highAnnualCost: 1800)
            ]
        ),
        BreedProfile(
            species: .cat, name: "Domestic Shorthair",
            notes: "Mixed breed — lower certainty, general baseline.",
            baselineAnnualCost: 800,
            riskFlags: [
                BreedRiskFlag(title: "Dental disease treatment",
                    detail: "Not a breed-specific risk so much as a general baseline — dental cleanings are the most common cost for any cat as it ages.",
                    lowAnnualCost: 250, highAnnualCost: 700)
            ]
        )
    ]

    static func profiles(for species: PetSpecies) -> [BreedProfile] {
        profiles.filter { $0.species == species }.sorted { $0.name < $1.name }
    }

    static func profile(species: PetSpecies, name: String) -> BreedProfile? {
        profiles.first { $0.species == species && $0.name == name }
    }
}
