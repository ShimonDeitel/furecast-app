import SwiftUI

/// Add-a-pet flow. Free tier can name a pet and set its species with no breed prediction
/// (the free tier's whole definition: manual logging, no prediction). Pro unlocks the breed
/// picker and shows a live predicted-cost preview before the pet is even saved — the
/// pre-adoption use case the brief is built around.
struct AddPetView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var species: PetSpecies = .dog
    @State private var adoptionDate = Date()
    @State private var selectedBreed: BreedProfile?
    @State private var showPaywall = false

    private var breeds: [BreedProfile] { BreedCatalog.profiles(for: species) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    TextField("Name", text: $name)
                    Picker("Species", selection: $species) {
                        ForEach(PetSpecies.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: species) { _, _ in selectedBreed = nil }
                    DatePicker("Adoption date", selection: $adoptionDate, displayedComponents: .date)
                }

                Section {
                    if store.isPro {
                        Picker("Breed", selection: $selectedBreed) {
                            Text("Not sure / skip").tag(BreedProfile?.none)
                            ForEach(breeds) { breed in
                                Text(breed.name).tag(Optional(breed))
                            }
                        }
                    } else {
                        ProLockedRow(
                            title: "Breed-specific prediction",
                            subtitle: "Unlock a pre-adoption true-cost estimate for this breed."
                        ) {
                            Haptics.tap()
                            showPaywall = true
                        }
                    }
                } header: {
                    Text("Cost Prediction")
                } footer: {
                    if !store.isPro {
                        Text("Free plan tracks manual expenses only, with no prediction.")
                    }
                }

                if let selectedBreed, store.isPro {
                    predictionPreview(selectedBreed)
                }
            }
            .navigationTitle("Add a Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        model.addPet(name: trimmed, species: species, adoptionDate: adoptionDate, breedProfile: selectedBreed, isPro: store.isPro)
                        Haptics.success()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func predictionPreview(_ breed: BreedProfile) -> some View {
        Section("Predicted First Year") {
            HStack {
                StatTile(label: "Low", value: Money.format(breed.predictedAnnualLow))
                StatTile(label: "Expected", value: Money.format(breed.predictedAnnualMid), valueColor: FurecastColor.coralDeep)
                StatTile(label: "High", value: Money.format(breed.predictedAnnualHigh))
            }
            Text(breed.notes)
                .font(.footnote)
                .foregroundStyle(FurecastColor.inkMuted)
            ForEach(breed.riskFlags) { flag in
                VStack(alignment: .leading, spacing: 2) {
                    Text(flag.title).font(FurecastFont.headline(14)).foregroundStyle(FurecastColor.ink)
                    Text("\(Money.format(flag.lowAnnualCost)) – \(Money.format(flag.highAnnualCost))")
                        .font(.footnote).foregroundStyle(FurecastColor.jarAmber)
                    Text(flag.detail).font(.caption).foregroundStyle(FurecastColor.inkMuted)
                }
                .padding(.vertical, 2)
            }
        }
    }
}
