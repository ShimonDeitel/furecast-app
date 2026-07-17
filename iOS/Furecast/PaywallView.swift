import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var working = false
    @State private var restoreMessage: String?

    private let benefits: [(String, String, String)] = [
        ("chart.line.uptrend.xyaxis", "Pre-adoption cost prediction", "See a breed-specific true-cost estimate — with dollar ranges — before you even bring your pet home."),
        ("sparkles", "AI surprise-risk coaching", "Get tailored risk flags and a savings tip based on what you've actually logged so far."),
        ("seal.fill", "Surprise jar & predict-vs-actual reports", "Track whether the specific risks Furecast warned about actually showed up, in real dollars."),
        ("pawprint.fill", "Unlimited pets", "Free is capped at one pet with no prediction. Pro removes that cap entirely.")
    ]

    var body: some View {
        ZStack {
            FurecastColor.canvas.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        PawPrintShape()
                            .fill(FurecastColor.coral)
                            .frame(width: 44, height: 44)
                        Text("Furecast Pro").font(FurecastFont.title(30))
                            .foregroundStyle(FurecastColor.ink)
                        Text("\(store.displayPrice) / month. Cancel anytime.")
                            .font(.subheadline).foregroundStyle(FurecastColor.inkMuted)
                    }
                    .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(benefits, id: \.0) { item in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: item.0)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(FurecastColor.coral)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.1).font(FurecastFont.headline(16))
                                        .foregroundStyle(FurecastColor.ink)
                                    Text(item.2).font(.subheadline).foregroundStyle(FurecastColor.inkMuted)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(16)
                    .background(FurecastColor.panel, in: PawBlobShape())
                    .overlay(PawBlobShape().strokeBorder(FurecastColor.hairline, lineWidth: 1))
                    .padding(.horizontal)

                    VStack(spacing: 12) {
                        Button { Task { await buy() } } label: {
                            HStack {
                                if working { ProgressView().tint(.white) }
                                Text(working ? "Starting…" : "Start Furecast Pro · \(store.displayPrice)/mo")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                        .prominentCoralButton()
                        .accessibilityIdentifier("paywall-subscribe")
                        .disabled(working)

                        Button("Restore Purchase") { Task { await restore() } }
                            .font(.subheadline).tint(FurecastColor.inkMuted)

                        if let restoreMessage {
                            Text(restoreMessage).font(.footnote).foregroundStyle(FurecastColor.inkMuted)
                        }

                        Text("Auto-renewable subscription, billed monthly to your Apple ID. Manage or cancel anytime in Settings.")
                            .font(.footnote).foregroundStyle(FurecastColor.inkMuted)
                            .multilineTextAlignment(.center).padding(.top, 4)
                    }
                    .padding(.horizontal).padding(.bottom, 30)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").font(.title2)
                    .foregroundStyle(FurecastColor.inkMuted).padding()
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier("paywall-close")
        }
        .onChange(of: store.isPro) { _, newValue in if newValue { dismiss() } }
    }

    private func buy() async {
        working = true
        let ok = await store.purchase()
        working = false
        if ok { Haptics.success(); dismiss() }
    }

    private func restore() async {
        await store.restore()
        if store.isPro { Haptics.success(); dismiss() }
        else { restoreMessage = "No previous purchase found on this Apple ID." }
    }
}
