import SwiftUIPlus

struct InterviewSurveyView: View {

    struct ViewState {
        let navigationTitle: AttributedString
        let currentScreen: Int
        let screens: [any View]
        let isForwardSwipeAvailable: Bool
        let isBackwardSwipeAvailable: Bool
        let ctaTitle: String
        let isCtaEnabled: Bool
        let keyboardHeight: CGFloat
    }

    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.i18n) private var i18n

    @ObservedObject var viewModel: InterviewSurveyViewModel

    private let ctaButtonHeight: CGFloat = 48
    private let ctaButtonBottomPadding: CGFloat = 24

    private var viewState: ViewState {
        viewModel.viewState
    }

    private var bottomSafeAreaPadding: CGFloat {
        let keyboardHeight = viewState.keyboardHeight
        return keyboardHeight > 0 ? keyboardHeight : safeAreaInsets.bottom
    }

    var body: some View {

        VStack(spacing: .zero) {
            navigationBar

            progressIndicator

            pager
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: .zero) {
                Button {
                    viewModel.continueTapped()
                } label: {
                    Text(viewState.ctaTitle)
                }
                .buttonStyle(.primary(isActive: viewState.isCtaEnabled))
                .disabled(!viewState.isCtaEnabled)
                .frame(height: ctaButtonHeight)
                .padding(.horizontal, 24)

                Spacer().frame(height: ctaButtonBottomPadding)
            }
        }
    }
}

// MARK: - Views

private extension InterviewSurveyView {

    var navigationBar: some View {
        Text(viewState.navigationTitle)
            .font(.ds.title3Semibold)
            .foregroundStyle(.black900)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .animation(
                .easeInOut(duration: 0.2),
                value: viewState.navigationTitle
            )
            .overlay(alignment: .leading) {
                Button {
                    viewModel.closeTapped()
                } label: {
                    Image(.chevronLeft)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.black900)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 48, height: 48)
            }
    }

    var progressIndicator: some View {
        ProgressIndicatorView(
            currentSegment: viewState.currentScreen + 1,
            segments: viewState.screens.count
        )
        .frame(height: 4)
        .multipadding(
            .horizontal(24),
            .bottom(8)
        )
    }

    var pager: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(viewState.screens.indices, id: \.self) { index in
                    let view = viewState.screens[index]
                    let content = VStack(spacing: .zero) {
                        AnyView(view)
                            .surveyAnswerSelectionHandler { questionId, answerId, text in
                                viewModel.selectAnswer(
                                    questionId: questionId,
                                    answerId: answerId,
                                    text: text
                                )
                            }

                        Spacer()
                            .frame(height: ctaButtonHeight + ctaButtonBottomPadding + bottomSafeAreaPadding)
                            .layoutPriority(1)
                    }
                    .multipadding(
                        .horizontal(24),
                        .vertical(24)
                    )
                    .frame(maxHeight: .infinity, alignment: .top)

                    ViewThatFits {
                        content
                        ScrollView {
                            content
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .frame(width: geometry.size.width * CGFloat(viewState.screens.count), alignment: .leading)
            .contentShape(.rect)
            .offset(x: -CGFloat(viewModel.currentPage) * geometry.size.width)
            .animation(.easeInOut, value: viewModel.currentPage)
            .onSwipe(.left) {
                guard viewState.isForwardSwipeAvailable else { return }
                viewModel.moveToNextPage()
            }
            .onSwipe(.right) {
                guard viewState.isBackwardSwipeAvailable else { return }
                viewModel.moveToPreviousPage()
            }
            .clipped()
            .ignoresSafeArea(.all)
        }
    }
}
