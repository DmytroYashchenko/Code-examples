import SwiftUIPlus

struct CropTipGeometryView: View {

    @Environment(\.i18n) var i18n

    let tipState: TipState

    @State private var mainContentWidth: CGFloat = 0
    @State private var currentFocusFrameSize: CGSize = .zero
    @State private var currentFocusFrameOffset: CGPoint = .zero
    @State private var initialFocusFramePosition: CGRect = .zero
    @State private var targetFocusFramePosition: CGRect = .zero

    private var focusFrameColor: Color {
        switch tipState {
        case .incorrect:
            .error400
        case .correct:
            .success500
        }
    }

    var body: some View {
        VStack(spacing: .zero) {
            mainContentView

            Spacer()
                .frame(height: TipStateView.size / 2)
        }
        .overlay(alignment: .bottom) {
            TipStateView(tipState: tipState)
        }
    }
}

// MARK: - Subviews

private extension CropTipGeometryView {

    var expressionView: some View {
        VStack(spacing: 16) {
            MathLabel(
                latex: "\\text{\(i18n.str(.whatIs)) } m \\angle 1\\text{?}",
                color: .black900,
                fontSize: 18
            )

            Image(.imgTriangleProblem)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: mainContentWidth * 0.7)
                    .padding(16)
                    .overlay {
                        GeometryReader { proxy in
                            FocusCornersShape(
                                size: 20,
                                intensity: 16
                            )
                            .stroke(
                                focusFrameColor,
                                style: .init(lineWidth: 2, lineCap: .round)
                            )
                            .animation(.default, value: tipState)
                            .frame(
                                width: currentFocusFrameSize.width,
                                height: currentFocusFrameSize.height
                            )
                            .offset(
                                x: currentFocusFrameOffset.x,
                                y: currentFocusFrameOffset.y
                            )
                            .onAppear {
                                currentFocusFrameSize = proxy.size
                            }
                            .onChange(of: proxy.size) { newValue in
                                currentFocusFrameSize = newValue
                            }
                        }
                        .positionInGlobal($initialFocusFramePosition)
                    }

            MathLabel(
                latex: "m \\angle 1 = ?",
                color: .black900,
                fontSize: 18
            )
        }
    }

    var mainContentView: some View {
        VStack(spacing: .zero) {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        mainContentWidth = proxy.size.width
                    }
            }
            .frame(height: 0)

            Image(.imgCheckeredSheet)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay {
                    EmptyRectangleView(
                        size: currentFocusFrameSize,
                        padding: 8,
                        cornerRadius: 20
                    )
                }
                .overlay {
                    expressionView
                        .multipadding(
                            .vertical(12),
                            .horizontal(12)
                        )
                        .positionInGlobal($targetFocusFramePosition)
                }
                .clipCorner(radius: 24)
                .onChange(of: tipState) { newValue in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        switch newValue {
                        case .incorrect:
                            currentFocusFrameSize = initialFocusFramePosition.size
                            currentFocusFrameOffset = .zero
                        case .correct:
                            currentFocusFrameSize = targetFocusFramePosition.size
                            currentFocusFrameOffset = .init(
                                x: targetFocusFramePosition.minX - initialFocusFramePosition.minX,
                                y: targetFocusFramePosition.minY - initialFocusFramePosition.minY
                            )
                        }
                    }
                }
        }
    }
}
