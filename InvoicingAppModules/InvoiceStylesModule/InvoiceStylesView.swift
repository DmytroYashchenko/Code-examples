import SwiftUIExt

struct InvoiceStylesView: View {

    @Environment(\.heightSize) private var heightSize

    @ObservedObject var viewModel: InvoiceStylesViewModel

    private var cardWidthMultiplier: CGFloat {
        switch heightSize {
        case .small:
            0.65
        default:
            0.7
        }
    }

    private var themesPadding: CGFloat {
        switch heightSize {
        case .small:
            16
        default:
            24
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Rectangle()
                .fill(.border)
                .frame(height: 1)

            stylesCollection
                .frame(maxHeight: .infinity)

            themesGrid
        }
        .safeAreaInset(edge: .bottom) {
            Button("Apply") {
                viewModel.applyTapped()
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(.backgroundPrimary)
    }
}

// MARK: - Subviews

private extension InvoiceStylesView {

    var header: some View {
        Text("Invoice styles")
            .font(.poppins(size: 22, weight: .semiBold))
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                Button {
                    viewModel.closeTapped()
                } label: {
                    Cross()
                        .scaledToFit()
                        .frame(height: 16)
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.icon)
            }
            .foregroundStyle(.textPrimary)
    }

    var stylesCollection: some View {
        WidthReader { width in
            let cardWidth = width * cardWidthMultiplier
            let cardHeight = cardWidth * 1.4
            let horizontalPadding = (width - cardWidth) / 2

            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    // Available samples

                    ForEach(viewModel.selectableSamples) { sample in
                        let isSelected = viewModel.selectedSample == sample

                        Button {
                            viewModel.selectSample(sample)
                        } label: {
                            VStack(spacing: 12) {
                                Text(sample.displayName)
                                    .font(.poppins(size: 14, weight: .semiBold))
                                    .foregroundStyle(.textPrimary)

                                if let data = viewModel.previewData(for: sample) {
                                    PDFPresentableView(
                                        data: data,
                                        isUserInteractionEnabled: false
                                    )
                                }
                            }
                            .padding(12)
                            .frame(width: cardWidth, height: cardHeight)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.backgroundSecondary)
                                    .shadow(color: .shadow, radius: 4)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isSelected ? .green600 : .clear,
                                        lineWidth: 2
                                    )
                            }
                            .overlay {
                                if isSelected {
                                    Image(systemName: "checkmark.circle")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundStyle(.green600)
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                        .buttonStyle(.icon)
                        .betterCell()
                    }

                    // Dummy items

                    ForEach(0..<2) { index in
                        let title = switch index {
                        case 0:
                            "Coming soon ✨"
                        case 1:
                            "Stay tuned 👀"
                        default:
                            ""
                        }
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.backgroundSecondary.gradient)
                            .shadow(color: .shadow, radius: 4)
                            .frame(width: cardWidth, height: cardHeight)
                            .overlay {
                                Text(title)
                                    .font(.poppins(size: 20, weight: .semiBold))
                                    .foregroundStyle(.textPrimary)
                            }
                            .betterCell()
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, horizontalPadding)
            }
            .scrollIndicators(.hidden)
            .betterScrollView()
        }
    }

    @ViewBuilder
    var themesGrid: some View {
        let themes = viewModel.selectableThemes
        let chunkSize = 3
        let themeChunks = stride(from: 0, to: themes.count, by: chunkSize).map { index in
            Array(themes[index ..< min(index + chunkSize, themes.count)])
        }

        Grid(horizontalSpacing: 24, verticalSpacing: 24) {
            ForEach(themeChunks.indices, id: \.self) { rowIndex in
                GridRow {
                    HStack(spacing: 24) {
                        let rowThemes = themeChunks[rowIndex]
                        ForEach(rowThemes.indices, id: \.self) { themeIndex in
                            let theme = rowThemes[themeIndex]
                            let isSelected = viewModel.selectedThemeId == theme.id
                            Button {
                                viewModel.selectTheme(id: theme.id)
                            } label: {
                                InvoiceStyleColorsView(
                                    theme: theme,
                                    isSelected: isSelected
                                )
                                .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.icon)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(themesPadding)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                topTrailingRadius: 20
            )
            .fill(.backgroundSecondary)
            .shadow(color: .shadow, radius: 4)
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

private extension View {

    @ViewBuilder
    func betterScrollView() -> some View {
        if #available(iOS 17.0, *) {
            scrollTargetBehavior(.viewAligned)
                .scrollTargetLayout()
        } else {
            self
        }
    }

    @ViewBuilder
    func betterCell() -> some View {
        if #available(iOS 17.0, *) {
            scrollTransition(axis: .horizontal) { content, phase in
                content
                    .rotation3DEffect(
                        .degrees(phase.value * -15),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.7
                    )
                    .opacity(1 - abs(phase.value) / 2)
            }
        } else {
            self
        }
    }
}
