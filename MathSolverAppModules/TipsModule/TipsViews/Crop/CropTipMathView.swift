import SwiftUIPlus

struct CropTipMathView: View {

    @Environment(\.i18n) var i18n

    let tipState: TipState

    @State private var currentFocusFrameSize: CGSize = .zero
    @State private var currentFocusFrameOffset: CGPoint = .zero
    @State private var initialFocusFramePosition: CGRect = .zero
    @State private var targetFocusFramePosition: CGRect = .zero

    private var emptyRectangleViewCornerRadius: CGFloat {
        switch tipState {
        case .incorrect:
            10
        case .correct:
            20
        }
    }

    private var focusFrameCurveSize: CGFloat {
        switch tipState {
        case .incorrect:
            10
        case .correct:
            20
        }
    }

    private var focusFrameCurveIntensity: CGFloat {
        switch tipState {
        case .incorrect:
            8
        case .correct:
            16
        }
    }

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

private extension CropTipMathView {

    var expressionView: some View {
        VStack(spacing: 8) {
            Text(i18n.str(.solveTheSystemOfEquations))
                .font(.ds.customFont(
                    fontStyle: .sfProTextRegular,
                    size: 16
                ))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            VStack(alignment: .leading, spacing: 8) {
                MathLabel(
                    latex: "1.\\ \\log_x \\left( 2x^2 - 3x - 4 \\right) = 2",
                    color: .black900,
                    fontSize: 18
                )
                .padding(8)
                .overlay {
                    GeometryReader { proxy in
                        FocusCornersShape(
                            size: focusFrameCurveSize,
                            intensity: focusFrameCurveIntensity
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
                    }
                    .positionInGlobal($initialFocusFramePosition)
                }

                MathLabel(
                    latex: "2.\\ x^2 - 3x - 4 = 0",
                    color: .black900,
                    fontSize: 18
                )
                .padding(.horizontal, 8)
            }
        }
    }

    var mainContentView: some View {
        Image(.imgCheckeredSheet)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay {
                EmptyRectangleView(
                    size: currentFocusFrameSize,
                    padding: 8,
                    cornerRadius: emptyRectangleViewCornerRadius
                )
            }
            .overlay {
                expressionView
                    .padding(34)
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
