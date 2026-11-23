import AVFoundation
import SwiftUI

struct PlayerView: View {

    let player: AVPlayer?
    let isLoading: Bool
    let isPlaying: Bool
    let isMuted: Bool
    let currentTimeText: String
    let remainingTimeText: String
    let playbackProgress: CGFloat
    let onTap: (() -> Void)?
    let onTogglePlayback: () -> Void
    let onToggleMute: () -> Void
    let onSeek: (CGFloat) -> Void

    var body: some View {
        Color.bgSecondary
            .overlay {
                playerContent
            }
            .overlay {
                LinearGradient(
                    colors: [
                        .black.opacity(0.2),
                        .clear,
                        .black.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                playerControls
                    .padding(16)
            }
            .overlay {
                if isLoading {
                    loadingOverlay
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(.rect(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Subviews

private extension PlayerView {

    @ViewBuilder
    var playerContent: some View {
        if let player {
            PlayerLayerView(player: player)
                .contentShape(.rect)
                .onTapGesture {
                    onTap?()
                }
        }
    }

    var loadingOverlay: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
            }
    }

    var playerControls: some View {
        VStack(spacing: 8) {
            progressBar

            ZStack {
                HStack(spacing: .zero) {
                    Text(currentTimeText)
                        .font(.caption1Semibold)
                        .foregroundStyle(.fgPrimary)

                    Spacer()

                    HStack(spacing: 12) {
                        Text(remainingTimeText)
                            .font(.caption1Semibold)
                            .foregroundStyle(.fgPrimary)

                        Button {
                            onToggleMute()
                        } label: {
                            Icon(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.fgPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    onTogglePlayback()
                } label: {
                    Icon(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.fgPrimary)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 24)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
    }

    var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.fgPrimary.opacity(0.36))

                Capsule()
                    .fill(.fgPrimary)
                    .frame(width: geometry.size.width * playbackProgress)
            }
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: .zero)
                    .onChanged { value in
                        let progress = value.location.x / max(geometry.size.width, 1)
                        onSeek(progress)
                    }
            )
        }
        .frame(height: 6)
    }
}

// MARK: - PlayerLayerView

private struct PlayerLayerView: UIViewRepresentable {

    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerLayerContainerView {
        let view = PlayerLayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill

        return view
    }

    func updateUIView(
        _ view: PlayerLayerContainerView,
        context: Context
    ) {
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
    }
}

// MARK: - PlayerLayerContainerView

private final class PlayerLayerContainerView: UIView {

    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
