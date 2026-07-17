import SwiftUI

/// The card/button silhouette used everywhere in Furecast instead of a plain rounded
/// rectangle: four independently-radiused corners give it a soft, asymmetric, hand-molded
/// "paw pad" quality rather than a uniform squircle. This is the app's signature shape
/// language — deliberately organic, never a rigid grid or ring.
struct PawBlobShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    func path(in fullRect: CGRect) -> Path {
        let rect = fullRect.insetBy(dx: insetAmount, dy: insetAmount)
        let w = rect.width
        let h = rect.height
        let base = min(w, h)

        let rTL = base * 0.40
        let rTR = base * 0.26
        let rBR = base * 0.44
        let rBL = base * 0.24

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rTL, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rTR, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rTR),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rBR))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rBR, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + rBL, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - rBL),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rTL))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rTL, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

/// A simplified, rounded animal-head silhouette (head blob + two ear bumps) — the container
/// for the piggy-bank animation. Deliberately generic across dog/cat rather than literal, so
/// it reads as "a pet" regardless of the profile's species.
struct PetSilhouetteShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    func path(in fullRect: CGRect) -> Path {
        let rect = fullRect.insetBy(dx: insetAmount, dy: insetAmount)
        let w = rect.width
        let h = rect.height
        var path = Path()

        let headTop = rect.minY + h * 0.20
        let headRect = CGRect(x: rect.minX, y: headTop, width: w, height: rect.maxY - headTop)
        let headRadius = min(w, headRect.height) * 0.42
        path.addPath(Path(roundedRect: headRect, cornerRadius: headRadius, style: .continuous))

        let earWidth = w * 0.30
        let earHeight = h * 0.26
        let earRadius = earWidth * 0.5

        let leftEarRect = CGRect(x: rect.minX + w * 0.04, y: rect.minY, width: earWidth, height: earHeight)
        let rightEarRect = CGRect(x: rect.maxX - w * 0.04 - earWidth, y: rect.minY, width: earWidth, height: earHeight)

        path.addPath(Path(roundedRect: leftEarRect, cornerRadius: earRadius, style: .continuous))
        path.addPath(Path(roundedRect: rightEarRect, cornerRadius: earRadius, style: .continuous))

        return path
    }
}

/// A literal, hand-drawn paw print (one pad + four toes) used as Furecast's decorative mark
/// in headers and empty states, in place of a generic SF Symbol.
struct PawPrintShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        let padRect = CGRect(x: rect.minX + w * 0.12, y: rect.minY + h * 0.42, width: w * 0.76, height: h * 0.52)
        path.addPath(Path(roundedRect: padRect, cornerRadius: min(padRect.width, padRect.height) * 0.46, style: .continuous))

        let toeXFractions: [CGFloat] = [0.06, 0.32, 0.58, 0.82]
        let toeWidthFractions: [CGFloat] = [0.20, 0.24, 0.24, 0.20]
        let toeHeightFractions: [CGFloat] = [0.24, 0.30, 0.30, 0.24]
        let toeYFractions: [CGFloat] = [0.12, 0.0, 0.0, 0.12]

        for i in 0..<4 {
            let tw = w * toeWidthFractions[i]
            let th = h * toeHeightFractions[i]
            let tx = rect.minX + w * toeXFractions[i]
            let ty = rect.minY + h * toeYFractions[i]
            path.addPath(Path(ellipseIn: CGRect(x: tx, y: ty, width: tw, height: th)))
        }

        return path
    }
}
