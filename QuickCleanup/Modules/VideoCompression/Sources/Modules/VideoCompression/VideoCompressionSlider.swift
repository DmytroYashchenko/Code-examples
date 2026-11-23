import SwiftUI

struct VideoCompressionSlider: View {

    @Binding var value: Double

    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let progress = progress(width: width)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.bgStroke)
                    .frame(height: 10)

                Capsule()
                    .fill(.accent500)
                    .frame(width: progress * width, height: 10)

                Circle()
                    .fill(.accent500)
                    .frame(width: 28, height: 28)
                    .shadow(
                        color: .black.opacity(0.5),
                        radius: 8,
                        x: .zero,
                        y: 4
                    )
                    .offset(x: thumbOffset(width: width))
            }
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: .zero)
                    .onChanged { dragValue in
                        updateValue(
                            locationX: dragValue.location.x,
                            width: width
                        )
                    }
            )
        }
        .frame(height: 50)
    }
}

// MARK: - Private

private extension VideoCompressionSlider {

    func progress(width: CGFloat) -> CGFloat {
        guard range.upperBound > range.lowerBound else { return .zero }

        let rawProgress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return min(max(CGFloat(rawProgress), .zero), 1)
    }

    func thumbOffset(width: CGFloat) -> CGFloat {
        let offset = progress(width: width) * width - 14
        return min(max(offset, .zero), max(width - 28, .zero))
    }

    func updateValue(
        locationX: CGFloat,
        width: CGFloat
    ) {
        guard range.upperBound > range.lowerBound else { return }

        let progress = min(max(locationX / max(width, 1), .zero), 1)
        value = range.lowerBound + Double(progress) * (range.upperBound - range.lowerBound)
    }
}
