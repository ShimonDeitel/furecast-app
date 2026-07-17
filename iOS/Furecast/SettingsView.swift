import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @AppStorage("furecast.theme") private var themeRaw = AppTheme.system.rawValue

    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var restoreMessage: String?

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Furecast \(v)"
    }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                appearanceSection
                howPredictionWorksSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .tint(FurecastColor.coralDeep)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Erase All Data?", isPresented: $showDeleteConfirm) {
                Button("Erase", role: .destructive) {
                    model.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes every pet, prediction, and logged expense. Furecast keeps no data anywhere else.")
            }
        }
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if store.isPro {
                HStack {
                    Label("Furecast Pro", systemImage: "pawprint.fill")
                    Spacer()
                    Text("Active").foregroundStyle(.secondary)
                }
            } else {
                Button {
                    Haptics.tap(); showPaywall = true
                } label: {
                    HStack {
                        Label("Get Furecast Pro", systemImage: "pawprint.fill")
                        Spacer()
                        Text("\(store.displayPrice)/mo").foregroundStyle(.secondary)
                    }
                }
                Button("Restore Purchase") {
                    Task {
                        await store.restore()
                        restoreMessage = store.isPro ? "Restored." : "No previous purchase found."
                    }
                }
                if let restoreMessage {
                    Text(restoreMessage).font(.footnote).foregroundStyle(.secondary)
                }
            }
        } footer: {
            if !store.isPro {
                Text("Breed cost prediction, AI surprise-risk coaching, the surprise jar, and predict-vs-actual reports.")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $themeRaw) {
                ForEach(AppTheme.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var howPredictionWorksSection: some View {
        Section {
            DisclosureGroup("How the prediction works") {
                Text("Furecast's breed catalog is a hand-written reference of well-documented cost and health tendencies — brachycephalic breeds and airway surgery, large breeds and joint issues, long coats and grooming, and more. Each pet's prediction is a snapshot taken when you add the breed, plus a range (low, expected, high). The surprise jar only ever counts an expense you deliberately tag against one of those specific predicted risks — never routine food, litter, or supplies — so the prediction stays honest and falsifiable rather than a vague guess.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dataSection: some View {
        Section {
            Button("Erase All Data", role: .destructive) { showDeleteConfirm = true }
        } header: {
            Text("Data & Privacy")
        } footer: {
            Text("Pets and expenses live only in this app on this device. AI coaching sends the selected breed, your pet's age, and a summary of logged spending to a stateless Cloudflare Worker to generate a reply — nothing is stored on any server, and no account or identifier is ever attached.")
        }
    }

    private var aboutSection: some View {
        Section {
            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/furecast-site/privacy.html")!)
            Link("Terms of Use", destination: URL(string: "https://shimondeitel.github.io/furecast-site/terms.html")!)
        } footer: {
            Text(version).frame(maxWidth: .infinity, alignment: .center).padding(.top, 4)
        }
    }
}
