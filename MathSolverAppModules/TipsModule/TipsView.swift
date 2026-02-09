import SwiftUIPlus

struct TipsView: View {

    struct ViewState {

        let title: String
        let ctaTitle: String
        let solvingFlow: SolvingFlowType
        let stepsViewStates: [TipStepViewState]
        let currentStepIndex: Int
        let isCloseButtonVisible: Bool

        static func makeEmpty() -> Self {
            .init(
                title: "",
                ctaTitle: "",
                solvingFlow: .math,
                stepsViewStates: [],
                currentStepIndex: 0,
                isCloseButtonVisible: false
            )
        }
    }

    @ObservedObject var viewModel: TipsViewModel

    private var viewState: ViewState {
        viewModel.viewState
    }

    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 12) {
                navigationBar

                progressIndicator
                    .padding(.horizontal, 24)
            }

            pager

            ctaButton
                .padding(.bottom, 24)
        }
    }
}

// MARK: - Subviews

private extension TipsView {

    var navigationBar: some View {
        Text(viewState.title)
            .font(.ds.title3Semibold)
            .foregroundStyle(.black900)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                if viewState.isCloseButtonVisible {
                    Button {
                        viewModel.closeTapped()
                    } label: {
                        Image(.cross)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.black900)
                            .frame(width: 24, height: 24)
                    }
                    .frame(width: 48, height: 48)
                }
            }
    }

    var progressIndicator: some View {
        ProgressIndicatorView(
            currentSegment: viewState.currentStepIndex + 1,
            segments: viewState.stepsViewStates.count
        )
        .frame(height: 4)
    }

    var pager: some View {
        GeometryReader { geometry in
            HStack(spacing: .zero) {
                ForEach(viewState.stepsViewStates) { step in
                    VStack(spacing: .zero) {
                        Spacer()

                        pageView(for: step)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(
                width: geometry.size.width * CGFloat(viewState.stepsViewStates.count),
                alignment: .leading
            )
            .offset(x: -CGFloat(viewState.currentStepIndex) * geometry.size.width)
            .animation(.easeInOut, value: viewState.currentStepIndex)
            .clipped()
        }
    }

    var ctaButton: some View {
        Button {
            viewModel.continueTapped()
        } label: {
            Text(viewState.ctaTitle)
        }
        .buttonStyle(.primary(isActive: true))
        .frame(height: 48)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    func pageView(for step: TipStepViewState) -> some View {
        VStack(spacing: 24) {
            Text(step.title)
                .lineLimit(2, reservesSpace: true)
                .hidden()
                .overlay {
                    Text(step.title)
                        .animation(.default, value: step.title)
                }
                .font(.ds.headlineSemibold)
                .foregroundStyle(.black900)
                .multilineTextAlignment(.center)

            switch step.tipType {
            case .focus:
                let expressionView: any View = switch viewState.solvingFlow {
                case .math:
                    FocusTipMathExpressionView()
                case .geometry:
                    FocusTipGeometryExpressionView()
                case .graph:
                    FocusTipGraphsExpressionView()
                case .science:
                    FocusTipScienceExpressionView()
                }
                FocusTipView(
                    tipState: step.tipState,
                    expressionView: expressionView
                )

            case .visibility:
                let expressionView: any View = switch viewState.solvingFlow {
                case .math:
                    VisibilityTipMathExpressionView()
                case .geometry:
                    VisibilityTipGeometryExpressionView()
                case .graph:
                    VisibilityTipGraphsExpressionView()
                case .science:
                    VisibilityTipScienceExpressionView()
                }
                VisibilityTipView(
                    tipState: step.tipState,
                    expressionView: expressionView
                )

            case .crop:
                switch viewState.solvingFlow {
                case .math:
                    CropTipMathView(tipState: step.tipState)
                case .geometry:
                    CropTipGeometryView(tipState: step.tipState)
                case .graph:
                    CropTipGraphsView(tipState: step.tipState)
                case .science:
                    CropTipScienceView(tipState: step.tipState)
                }
            }
        }
    }
}
