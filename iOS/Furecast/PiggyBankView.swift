import SwiftUI

/// The animation hook: a pet-silhouette "piggy bank" whose coral fill rises to show real
/// spend against the predicted annual total, with a thin sage predicted-line marker showing
/// where the app expected the fill to be by now. The gap between the fill's top edge and the
/// marker is the whole point — it's the prediction made visually falsifiable.
struct PiggyBankView: View {
    let fillFraction: Double      // 0...1.25, actual spend / predicted annual mid
    let predictedFraction: Double // 0...1, elapsed-time-based "expected by now" line
    let isOverPace: Bool

    @State private var animatedFill: CGFloat = 0
    @State private var animatedLine: CGFloat = 0
    @State private var hasAppeared = false

    var body: some View {
        GeometryReader { proxy in
            let h = proxy.size.height
            ZStack(alignment: .bottom) {
                PetSilhouetteShape()
                    .stroke(FurecastColor.sage.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [1]))

                PetSilhouetteShape()
                    .fill(
                        LinearGradient(
                            colors: [FurecastColor.coralDeep, FurecastColor.coral],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    .mask(alignment: .bottom) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle().frame(height: max(0, h * min(animatedFill, 1)))
                        }
                    }

                PetSilhouetteShape()
                    .strokeBorder(FurecastColor.ink.opacity(0.12), lineWidth: 1)

                // Predicted-line marker: where the app expected spend to be by now.
                Rectangle()
                    .fill(isOverPace ? FurecastColor.jarAmber : FurecastColor.sageDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 2.5)
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 0.5)
                    .offset(y: -h * animatedLine)
            }
            .frame(width: proxy.size.width, height: h)
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                withAnimation(.easeOut(duration: 1.1)) {
                    animatedFill = CGFloat(fillFraction)
                    animatedLine = CGFloat(predictedFraction)
                }
            }
            .onChange(of: fillFraction) { _, newValue in
                withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) {
                    animatedFill = CGFloat(newValue)
                }
            }
            .onChange(of: predictedFraction) { _, newValue in
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedLine = CGFloat(newValue)
                }
            }
        }
    }
}

#Preview {
    PiggyBankView(fillFraction: 0.62, predictedFraction: 0.45, isOverPace: true)
        .frame(width: 220, height: 260)
        .padding()
        .background(FurecastColor.canvas)
}
