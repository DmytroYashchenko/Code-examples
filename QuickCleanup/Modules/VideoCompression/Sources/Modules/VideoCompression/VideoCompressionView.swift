import SwiftUI

struct VideoCompressionView: View {

    @ObservedObject var viewModel: VideoCompressionViewModel

    var body: some View {
        ZStack {
            Color.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: .zero) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                content
                    .padding(.horizontal, 16)
            }
        }
        .animation(.default, value: viewModel.viewState)
        .overlay {
            if viewModel.isDeleteInProgress {
                LoadingView()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isDeleteInProgress)
            }
        }
        .disabled(viewModel.isDeleteInProgress)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

// MARK: - Subviews

private extension VideoCompressionView {

    var header: some View {
        HStack(spacing: .zero) {
            BackButton {
                viewModel.backTapped()
            }

            Spacer()
        }
        .frame(height: 40)
        .overlay {
            Text("Compress Video")
                .font(.body1Semibold)
                .foregroundStyle(.fgPrimary)
        }
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {
        case .prepareToCompression:
            prepareToCompressionContent
        case .compressionInProgress:
            VideoCompressionProgressView(progress: viewModel.compressionProgress)
        case .compressionSuccess:
            compressionSuccessContent
        }
    }

    var prepareToCompressionContent: some View {
        VStack(spacing: .zero) {
            player
                .padding(.bottom, 16)

            compressionControls
                .padding(.bottom, 16)
        }
    }

    var compressionSuccessContent: some View {
        VStack(spacing: .zero) {
            player
                .padding(.bottom, 16)

            compressionSuccessControls
                .padding(.bottom, 16)
        }
    }

    var player: some View {
        PlayerView(
            player: viewModel.player,
            isLoading: false,
            isPlaying: viewModel.isPlaying,
            isMuted: viewModel.isMuted,
            currentTimeText: viewModel.currentTimeText,
            remainingTimeText: viewModel.remainingTimeText,
            playbackProgress: viewModel.playbackProgress,
            onTap: nil,
            onTogglePlayback: {
                viewModel.togglePlayback()
            },
            onToggleMute: {
                viewModel.toggleMute()
            },
            onSeek: { progress in
                viewModel.seek(to: progress)
            }
        )
    }

    var compressionControls: some View {
        VStack(spacing: 16) {
            sizeComparison

            VideoCompressionSlider(
                value: $viewModel.compressionLevel,
                range: viewModel.compressionLevelRange
            )

            Button("Compress") {
                viewModel.compressTapped()
            }
            .buttonStyle(.primary)
        }
    }

    var compressionSuccessControls: some View {
        VStack(spacing: 24) {
            Text(viewModel.compressionSuccessTitle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                Button("Keep Both Videos") {
                    viewModel.keepBothVideosTapped()
                }
                .buttonStyle(.primary)

                Button("Delete Original Video") {
                    viewModel.deleteOriginalVideoTapped()
                }
                .buttonStyle(.primary)
            }
        }
    }

    var sizeComparison: some View {
        HStack(spacing: 8) {
            sizeInfo(
                title: "Original size",
                value: viewModel.originalSizeText,
                valueColor: .fgPrimary
            )

            Icon(.icDoubleChevronRight)
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(.fgSecondary)

            sizeInfo(
                title: "After compression",
                value: viewModel.compressedSizeText,
                valueColor: .accent500
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.bgSecondary, in: .rect(cornerRadius: 16, style: .continuous))
    }

    func sizeInfo(
        title: LocalizedStringKey,
        value: String,
        valueColor: Color
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption1Regular)
                .foregroundStyle(.fgSecondary)

            Text(value)
                .font(.body1Semibold)
                .foregroundStyle(valueColor)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
    }
}
