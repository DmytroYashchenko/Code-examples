import SwiftUIPlus

struct VisibilityTipView: View {

    let tipState: TipState
    let expressionView: any View

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

// MARK: Subviews

private extension VisibilityTipView {

    var mainContentView: some View {
        Image(.imgCheckeredSheet)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay {
                AnyView(expressionView)
                    .blur(radius: tipState == .incorrect ? 2 : 0)
                    .animation(.easeIn(duration: 0.5), value: tipState)
            }
            .overlay {
                if tipState == .incorrect {
                    Color.constantBlack
                        .opacity(0.12)
                        .animation(.easeIn(duration: 0.5), value: tipState)
                }
            }
            .clipCorner(radius: 24)
    }
}
