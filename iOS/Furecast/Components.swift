import SwiftUI
import UIKit

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func click() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

/// Primary CTA — a solid coral paw-blob.
struct FilledCoralButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FurecastFont.headline())
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .background(FurecastColor.coral, in: PawBlobShape())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Secondary — a panel paw-blob with a hairline edge.
struct PawPanelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FurecastFont.headline(15))
            .foregroundStyle(FurecastColor.ink)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(FurecastColor.panel, in: PawBlobShape())
            .overlay(PawBlobShape().strokeBorder(FurecastColor.hairline, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func prominentCoralButton() -> some View { buttonStyle(FilledCoralButtonStyle()) }
    func pawPanelButton() -> some View { buttonStyle(PawPanelButtonStyle()) }

    /// Tap anywhere on this view to resign the first responder (dismiss the keyboard).
    /// Uses `simultaneousGesture` rather than a plain `.gesture` so it never swallows taps
    /// meant for buttons, pickers, or other controls inside the screen.
    func dismissKeyboardOnTap() -> some View {
        simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }
}

/// A grouped "paw card" container used for every section on Home/Detail.
struct PawCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FurecastColor.panel, in: PawBlobShape())
            .overlay(PawBlobShape().strokeBorder(FurecastColor.hairline, lineWidth: 1))
    }
}

/// A small pill label, used for category tags and the "Pro" badge.
struct FurecastPill: View {
    let text: String
    var color: Color = FurecastColor.sage
    var body: some View {
        Text(text)
            .font(FurecastFont.tag(12))
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(color, in: Capsule())
    }
}

/// A locked-behind-Pro row: shows the feature name with a lock glyph, taps trigger the
/// paywall via `onTap` rather than performing the action.
struct ProLockedRow: View {
    let title: String
    let subtitle: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(FurecastColor.jarAmber)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(FurecastFont.headline(15)).foregroundStyle(FurecastColor.ink)
                    Text(subtitle).font(.footnote).foregroundStyle(FurecastColor.inkMuted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(FurecastColor.inkMuted)
            }
        }
        .buttonStyle(.plain)
    }
}

/// One stat readout (label + big value), used in the pet detail header row.
struct StatTile: View {
    let label: String
    let value: String
    var valueColor: Color = FurecastColor.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(FurecastFont.caption())
                .foregroundStyle(FurecastColor.inkMuted)
                .tracking(0.8)
            Text(value)
                .font(FurecastFont.value(20))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Currency formatting shared across every money display in the app.
enum Money {
    static func format(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}
