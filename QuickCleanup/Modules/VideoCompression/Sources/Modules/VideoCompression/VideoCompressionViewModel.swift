import AVFoundation
import Combine
import Depin
import UIKitExt

@MainActor
final class VideoCompressionViewModel: ObservableObject {

    @Injected private var videoCompressionService: VideoCompressionService
    @Injected private var galleryDeletionService: GalleryDeletionService
    @Injected private var databaseManager: DatabaseManager

    @Published var compressionLevel = 0.5
    @Published private(set) var viewState: VideoCompressionViewState = .prepareToCompression
    @Published private(set) var compressionProgress: CGFloat = .zero
    @Published private(set) var isPlaying = false
    @Published private(set) var isMuted = false
    @Published private(set) var currentTime: Double = .zero
    @Published private(set) var duration: Double = .zero
    @Published private(set) var savedSizeBytes: Int64 = .zero
    @Published private(set) var isDeleteInProgress = false

    private let router: HomeRouter
    private let localIdentifier: String
    private let sizeBytes: Int64
    private var timeObserver: Any?
    private var compressionTask: Task<Void, Never>?
    private var compressionResult: VideoCompressionResult?

    let player: AVPlayer

    init(
        router: HomeRouter,
        input: VideoCompressionInput
    ) {
        self.router = router
        localIdentifier = input.localIdentifier
        sizeBytes = input.sizeBytes
        player = input.player
        compressionLevel = videoCompressionService.configuration.defaultCompressionLevel
    }

    func onAppear() {
        syncPlaybackState()
        addTimeObserver()
    }

    func onDisappear() {
        removeTimeObserver()
        cancelCompressionTask()
    }

    func backTapped() {
        if viewState == .compressionSuccess {
            router.popToRoot()
            return
        }

        cancelCompressionTask()
        router.closeVideoCompression()
    }

    func togglePlayback() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func toggleMute() {
        isMuted.toggle()
        player.isMuted = isMuted
    }

    func seek(to progress: CGFloat) {
        guard duration > .zero else { return }

        let targetTime = duration * Double(min(max(progress, .zero), 1))
        let time = CMTime(
            seconds: targetTime,
            preferredTimescale: Constants.timeScale
        )
        currentTime = targetTime
        player.seek(
            to: time,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    func compressTapped() {
        guard compressionTask == nil else { return }

        player.pause()
        isPlaying = false
        compressionProgress = .zero
        viewState = .compressionInProgress

        let compressionLevel = compressionLevel
        printDebugLog(
            """
            Started.
            • localIdentifier: \(localIdentifier)
            • sourceSizeBytes: \(sizeBytes)
            • compressionLevel: \(compressionLevel)
            """
        )
        compressionTask = Task { @MainActor [weak self] in
            await self?.compressVideo(compressionLevel: compressionLevel)
        }
    }

    func keepBothVideosTapped() {
        router.popToRoot()
    }

    func deleteOriginalVideoTapped() {
        guard
            let compressionResult,
            !isDeleteInProgress
        else {
            return
        }

        isDeleteInProgress = true

        Task { [weak self] in
            await self?.deleteOriginalVideo(compressionResult: compressionResult)
        }
    }
}

// MARK: - Compression

private extension VideoCompressionViewModel {

    func compressVideo(compressionLevel: Double) async {
        defer {
            compressionTask = nil
        }

        do {
            let stream = videoCompressionService.compressVideo(
                localIdentifier: localIdentifier,
                sourceSizeBytes: sizeBytes,
                compressionLevel: compressionLevel
            )

            for try await event in stream {
                try await handleCompressionEvent(event)
            }
        } catch is CancellationError {
            printDebugLog("Cancelled.")
            compressionProgress = .zero
            viewState = .prepareToCompression
        } catch {
            printDebugLog("Failed with error: \(String(reflecting: error))")
            compressionProgress = .zero
            viewState = .prepareToCompression
        }
    }

    func handleCompressionEvent(_ event: VideoCompressionEvent) async throws {
        switch event {
        case let .progress(progress):
            compressionProgress = min(
                max(CGFloat(progress.totalFractionCompleted), .zero),
                1
            )
        case .completed(let result):
            printDebugLog("Completed.")
            do {
                try await databaseManager.applyInsertedGalleryAsset(
                    localIdentifier: result.compressedLocalIdentifier,
                    sizeBytes: result.compressedSizeBytes
                )
            } catch {
                await deleteCompressedVideoAfterDatabaseFailure(
                    localIdentifier: result.compressedLocalIdentifier,
                    error: error
                )
                throw error
            }

            compressionResult = result
            savedSizeBytes = result.savedSizeBytes
            compressionProgress = 1
            viewState = .compressionSuccess
        }
    }

    func deleteOriginalVideo(compressionResult: VideoCompressionResult) async {
        defer {
            isDeleteInProgress = false
        }

        do {
            let result = try await galleryDeletionService.deleteAssets(
                withLocalIdentifiers: [compressionResult.originalLocalIdentifier]
            )
            guard result == .deleted else { return }

            router.openCleaningSummary(
                input: CleaningSummaryFlowInput(
                    deletedItemCount: 1,
                    deletedBytes: compressionResult.savedSizeBytes,
                    rateUsReferrer: .videos
                )
            )
        } catch {
            printDebugLog("Failed to delete original video with error: \(String(reflecting: error))")
        }
    }

    func cancelCompressionTask() {
        if compressionTask != nil {
            printDebugLog("Cancellation requested.")
        }
        compressionTask?.cancel()
        compressionTask = nil
    }

    func deleteCompressedVideoAfterDatabaseFailure(
        localIdentifier: String,
        error: Error
    ) async {
        printDebugLog(
            "Database sync failed with error: \(String(reflecting: error)). Removing compressed video."
        )

        do {
            try await videoCompressionService.deleteCompressedVideo(
                withLocalIdentifier: localIdentifier
            )
        } catch {
            printDebugLog("Failed to remove compressed video with error: \(String(reflecting: error))")
        }
    }

    func printDebugLog(_ message: String) {
        #if DEBUG
        print("[VideoCompressionViewModel] \(message)")
        #endif
    }
}

// MARK: - View data

extension VideoCompressionViewModel {

    var compressionLevelRange: ClosedRange<Double> {
        videoCompressionService.configuration.compressionLevelRange
    }

    var playbackProgress: CGFloat {
        guard duration > .zero else { return .zero }
        return min(max(CGFloat(currentTime / duration), .zero), 1)
    }

    var currentTimeText: String {
        timeText(for: currentTime)
    }

    var remainingTimeText: String {
        timeText(for: max(duration - currentTime, .zero))
    }

    var originalSizeText: String {
        StorageTextFormatter.string(for: sizeBytes)
    }

    var compressedSizeText: String {
        StorageTextFormatter.string(
            for: videoCompressionPlan.estimatedOutputSizeBytes
        )
    }

    var compressionSuccessTitle: AttributedString {
        let savedSizeText = StorageTextFormatter.string(for: savedSizeBytes)

        return String(localized: "Compression complete. Delete the original to free \(savedSizeText)")
            .attributedString
            .setFont(.body1Regular)
            .setForegroundColor(.fgSecondary)
            .setFont(.title2Bold, to: savedSizeText)
            .setForegroundColor(.accent500, to: savedSizeText)
    }
}

// MARK: - Private

private extension VideoCompressionViewModel {

    enum Constants {

        static let timeScale: CMTimeScale = 600
    }

    var videoCompressionPlan: VideoCompressionPlan {
        videoCompressionService.makePlan(
            sourceSizeBytes: sizeBytes,
            compressionLevel: compressionLevel
        )
    }

    func syncPlaybackState() {
        isMuted = player.isMuted
        isPlaying = player.timeControlStatus == .playing
        currentTime = normalizedDuration(player.currentTime().seconds)

        if let duration = player.currentItem?.duration.seconds {
            self.duration = normalizedDuration(duration)
        }
    }

    func addTimeObserver() {
        removeTimeObserver()

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(
                seconds: 0.25,
                preferredTimescale: Constants.timeScale
            ),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.currentTime = self?.normalizedDuration(time.seconds) ?? .zero

                if let duration = self?.player.currentItem?.duration.seconds {
                    self?.duration = self?.normalizedDuration(duration) ?? .zero
                }

                self?.isPlaying = self?.player.timeControlStatus == .playing
            }
        }
    }

    func removeTimeObserver() {
        guard let timeObserver else { return }

        player.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }

    func normalizedDuration(_ duration: Double) -> Double {
        guard duration.isFinite else { return .zero }
        return max(duration, .zero)
    }

    func timeText(for duration: Double) -> String {
        let totalSeconds = max(Int(duration.rounded()), .zero)
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > .zero {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }
}
