import SwiftUI

struct VideoCompressionProgressView: View {

    let progress: CGFloat

    var body: some View {
        VStack(spacing: 16) {
            progressIndicator

            VStack(spacing: 8) {
                Text("Compression in Progress")
                    .font(.body1Semibold)
                    .foregroundStyle(.fgPrimary)

                Text("Please don't close the app to avoid losing progress.")
                    .font(.body2Regular)
                    .foregroundStyle(.fgSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Subviews

private extension VideoCompressionProgressView {

    enum Constants {

        static let innerCircleSize: CGFloat = 120
        static let iconSize: CGFloat = 60
        static let ringGap: CGFloat = 8
        static let ringLineWidth: CGFloat = 8
        static let progressIndicatorSize = innerCircleSize + 2 * (ringGap + ringLineWidth)
    }

    var progressIndicator: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.accent100, .accent500],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(
                width: Constants.innerCircleSize,
                height: Constants.innerCircleSize
            )
            .overlay {
                Icon(.icTowardsArrows)
                    .scaledToFit()
                    .frame(
                        width: Constants.iconSize,
                        height: Constants.iconSize
                    )
                    .foregroundStyle(.fgPrimary)
            }
            .overlay {
                progressRing
            }
            .frame(
                width: Constants.progressIndicatorSize,
                height: Constants.progressIndicatorSize
            )
    }

    var progressRing: some View {
        Circle()
            .strokeBorder(.bgSecondary, lineWidth: Constants.ringLineWidth)
            .frame(
                width: Constants.progressIndicatorSize,
                height: Constants.progressIndicatorSize
            )
            .overlay {
                Circle()
                    .inset(by: Constants.ringLineWidth / 2)
                    .trim(from: .zero, to: normalizedProgress)
                    .stroke(
                        AngularGradient(
                            stops: [
                                .init(color: .accent100, location: 0),
                                .init(color: .accent100, location: 0.04),
                                .init(color: .accent500, location: 1)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(
                            lineWidth: Constants.ringLineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(
                        width: Constants.progressIndicatorSize,
                        height: Constants.progressIndicatorSize
                    )
                    .overlay(alignment: .top) {
                        if normalizedProgress > .zero {
                            Circle()
                                .fill(.accent100)
                                .frame(
                                    width: Constants.ringLineWidth,
                                    height: Constants.ringLineWidth
                                )
                        }
                    }
            }
    }
}

// MARK: - Private

private extension VideoCompressionProgressView {

    var normalizedProgress: CGFloat {
        min(max(progress, .zero), 1)
    }
}
