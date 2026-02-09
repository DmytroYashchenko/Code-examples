import SwiftUI

struct FocusCornersShape: Shape {

    var size: CGFloat
    var intensity: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { path in
            // Top-left corner
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: 0, y: intensity))
            path.addQuadCurve(
                to: CGPoint(x: intensity, y: 0),
                control: CGPoint(x: 0, y: 0)
            )
            path.addLine(to: CGPoint(x: size, y: 0))

            // Top-right corner
            path.move(to: CGPoint(x: rect.maxX - size, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX - intensity, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: intensity),
                control: CGPoint(x: rect.maxX, y: 0)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: size))

            // Bottom-right corner
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - size))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - intensity))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - intensity, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.maxX - size, y: rect.maxY))

            // Bottom-left corner
            path.move(to: CGPoint(x: size, y: rect.maxY))
            path.addLine(to: CGPoint(x: intensity, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.maxY - intensity),
                control: CGPoint(x: 0, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: 0, y: rect.maxY - size))
        }
    }
}

extension FocusCornersShape: Animatable {

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(size, intensity)
        }
        set {
            size = newValue.first
            intensity = newValue.second
        }
    }
}
