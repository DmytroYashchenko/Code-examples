import SwiftUIPlus

struct FocusTipView: View {

    @Environment(\.i18n) var i18n

    let tipState: TipState
    let expressionView: any View

    @State private var mainContentWidth: CGFloat = 0
    @State private var currentFocusFrameSize: CGSize = .zero
    @State private var currentFocusFrameOffset: CGPoint = .zero
    @State private var initialFocusFramePosition: CGRect = .zero
    @State private var targetFocusFramePosition: CGRect = .zero

    private var contentFillColor: Color {
        switch tipState {
        case .incorrect:
            .error50
        case .correct:
            .primary50
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
            topBarView

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

private extension FocusTipView {

    var topBarView: some View {
        HStack(spacing: 8) {
            Spacer()

            ForEach(1...3, id: \.self) { _ in
                Circle()
                    .foregroundStyle(.primary50)
                    .frame(width: 8, height: 8)
            }
        }
        .multipadding(
            .vertical(10),
            .horizontal(20)
        )
        .background(.primary100)
        .clipCorner(
            radius: 12,
            corners: [.topLeft, .topRight]
        )
    }

    private var topLineShapesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(1...3, id: \.self) { index in
                Rectangle()
                    .foregroundStyle(contentFillColor)
                    .frame(height: 8)
                    .frame(width: index == 3 ? mainContentWidth * 0.75 : mainContentWidth)
            }
        }
    }

    private var rightLineShapeView: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: .zero) {
                VStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { _ in
                        Rectangle()
                            .foregroundStyle(contentFillColor)
                            .frame(height: 8)
                    }
                }
            }

            Text(i18n.str(.submit))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .font(.ds.bodyBold)
                .foregroundStyle(.constantWhite)
                .multipadding(
                    .vertical(8),
                    .horizontal(10)
                )
                .background(contentFillColor)
                .clipCorner(radius: 8)
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

            VStack(spacing: 24) {
                topLineShapesView

                HStack(spacing: 12) {
                    AnyView(expressionView)
                        .padding(12)
                        .frame(width: mainContentWidth * 0.7)
                        .positionInGlobal($targetFocusFramePosition)

                    rightLineShapeView
                }

                Spacer()
                    .frame(height: 2)
            }
        }
        .padding(12)
        .overlay {
            GeometryReader { proxy in
                FocusCornersShape(size: 20, intensity: 16)
                    .stroke(
                        focusFrameColor,
                        style: .init(lineWidth: 2, lineCap: .round)
                    )
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
        .padding(16)
        .background(.backgroundSecondary)
        .clipCorner(
            radius: 12,
            corners: [.bottomLeft, .bottomRight]
        )
        .onChange(of: tipState) { newValue in
            withAnimation(.easeIn(duration: 0.5)) {
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
