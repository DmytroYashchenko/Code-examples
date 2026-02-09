import SwiftUIPlus

struct TipStateView: View {

    static let size: CGFloat = 80

    let tipState: TipState

    private var tipStateText: String {
        switch tipState {
        case .incorrect:
            "❌"
        case .correct:
            "✅"
        }
    }

    private var circleBackgroundColor: Color {
        switch tipState {
        case .incorrect:
            .error100
        case .correct:
            .success100
        }
    }

    private var circleBorderColor: Color {
        switch tipState {
        case .incorrect:
            .error400
        case .correct:
            .success400
        }
    }

    var body: some View {
        Circle()
            .fill(circleBackgroundColor)
            .frame(
                width: TipStateView.size,
                height: TipStateView.size
            )
            .overlay {
                Circle()
                    .stroke(
                        circleBorderColor,
                        lineWidth: 1
                    )
            }
            .overlay {
                Text(tipStateText)
                    .font(.ds.title1Bold)
            }
            .animation(.default, value: tipState)
    }
}
