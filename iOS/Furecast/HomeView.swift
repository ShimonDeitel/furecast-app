import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showAddPet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header

                    let pets = model.pets()
                    if pets.isEmpty {
                        emptyState
                    } else {
                        ForEach(pets, id: \.id) { pet in
                            NavigationLink(value: pet.id) {
                                PetRow(pet: pet)
                            }
                            .buttonStyle(.plain)
                        }

                        addPetButton

                        if !store.isPro {
                            Text("Free plan: 1 pet, manual expense logging, no breed prediction.")
                                .font(.footnote)
                                .foregroundStyle(FurecastColor.inkMuted)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .background(FurecastColor.canvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .navigationDestination(for: UUID.self) { petID in
                if let pet = model.pets().first(where: { $0.id == petID }) {
                    PetDetailView(pet: pet)
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAddPet) { AddPetView() }
        }
        .tint(FurecastColor.coral)
    }

    private var header: some View {
        VStack(spacing: 8) {
            PawPrintShape()
                .fill(FurecastColor.coral)
                .frame(width: 40, height: 40)
            Text("Furecast").font(FurecastFont.title(30)).foregroundStyle(FurecastColor.ink)
            Text("Know the true cost before — and after — you adopt.")
                .font(.subheadline)
                .foregroundStyle(FurecastColor.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            PawPrintShape()
                .fill(FurecastColor.sage)
                .frame(width: 44, height: 44)
            Text("No pets yet").font(FurecastFont.headline(18)).foregroundStyle(FurecastColor.ink)
            Text("Add a pet to start tracking expenses. Go Pro to see a breed-specific cost prediction before you even adopt.")
                .font(.subheadline)
                .foregroundStyle(FurecastColor.inkMuted)
                .multilineTextAlignment(.center)
            Button {
                Haptics.tap()
                showAddPet = true
            } label: {
                Label("Add Your First Pet", systemImage: "plus.circle.fill").frame(maxWidth: .infinity)
            }
            .prominentCoralButton()
        }
        .padding(.top, 40)
    }

    private var addPetButton: some View {
        Button {
            Haptics.tap()
            if model.canAddPet(isPro: store.isPro) { showAddPet = true } else { showPaywall = true }
        } label: {
            Label(store.isPro ? "Add Another Pet" : "Add a Pet", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .pawPanelButton()
    }
}

private struct PetRow: View {
    let pet: Pet

    var body: some View {
        PawCard {
            HStack(spacing: 14) {
                PawPrintShape()
                    .fill(pet.species == .dog ? FurecastColor.coral : FurecastColor.sage)
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(pet.name).font(FurecastFont.headline(17)).foregroundStyle(FurecastColor.ink)
                    Text(pet.breedName ?? "\(pet.species.rawValue) · no prediction yet")
                        .font(.footnote)
                        .foregroundStyle(FurecastColor.inkMuted)
                }
                Spacer(minLength: 0)
                if pet.hasPrediction {
                    FurecastPill(text: "Predicted", color: FurecastColor.sage)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(FurecastColor.inkMuted)
            }
        }
    }
}
