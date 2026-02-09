import SwiftUIPlus

struct CropTipGraphsView: View {

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

private extension CropTipGraphsView {

    var expressionView: some View {
        VStack(spacing: 4) {
            VStack(spacing: 4) {
                Text(i18n.str(.plotAnalyzeTheFunction))
                    .font(.ds.customFont(
                        fontStyle: .sfProTextRegular,
                        size: 17
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                MathLabel(
                    latex: "f(x)= -2x+4",
                    color: .black900,
                    fontSize: 19
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("a. \(i18n.str(.theYInterceptIsAt)) (0, 4)")
                    .font(.ds.customFont(
                        fontStyle: .sfProTextRegular,
                        size: 17
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
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

                Text("b. \(i18n.str(.theXInterceptIsAt)) (2, 0)")
                    .font(.ds.customFont(
                        fontStyle: .sfProTextRegular,
                        size: 17
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 8)

                Text("c. \(i18n.str(.theSlopeOfThisLineIs)) -2")
                    .font(.ds.customFont(
                        fontStyle: .sfProTextRegular,
                        size: 17
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
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
