@preconcurrency import AVFoundation
import Foundation
@preconcurrency import Photos

struct VideoCompressionConfiguration: Sendable {

    let compressionLevelRange: ClosedRange<Double>
    let defaultCompressionLevel: Double
    let maximumOutputSizeRatio: Double
    let minimumOutputSizeRatio: Double
}

struct VideoCompressionPlan: Sendable {

    let compressionLevel: Double
    let sourceSizeBytes: Int64
    let estimatedOutputSizeBytes: Int64
    let estimatedSavedSizeBytes: Int64
}

enum VideoCompressionStage: Sendable {

    case loadingSource
    case preparing
    case compressing
    case saving
}

struct VideoCompressionProgress: Sendable {

    let stage: VideoCompressionStage
    let stageFractionCompleted: Double
    let totalFractionCompleted: Double
}

struct VideoCompressionResult: Sendable {

    let originalLocalIdentifier: String
    let compressedLocalIdentifier: String
    let originalSizeBytes: Int64
    let compressedSizeBytes: Int64
    let savedSizeBytes: Int64
}

enum VideoCompressionEvent: Sendable {

    case progress(VideoCompressionProgress)
    case completed(VideoCompressionResult)
}

enum VideoCompressionServiceError: Error {

    case assetNotFound
    case assetIsNotVideo
    case sourceVideoTrackMissing
    case videoTrackUnsupported
    case audioTrackUnsupported
    case compressedVideoIsNotSmaller
    case readerFailed
    case writerFailed
    case outputFileMissing
    case photoLibrarySaveFailed
    case photoLibraryDeleteFailed
}

final class VideoCompressionService {

    let configuration = VideoCompressionConfiguration(
        compressionLevelRange: Constants.compressionLevelRange,
        defaultCompressionLevel: Constants.defaultCompressionLevel,
        maximumOutputSizeRatio: Constants.maximumOutputSizeRatio,
        minimumOutputSizeRatio: Constants.minimumOutputSizeRatio
    )

    func makePlan(
        sourceSizeBytes: Int64,
        compressionLevel: Double
    ) -> VideoCompressionPlan {
        let compressionLevel = normalizedCompressionLevel(compressionLevel)
        let outputSizeRatio = Constants.maximumOutputSizeRatio
            - compressionLevel * (Constants.maximumOutputSizeRatio - Constants.minimumOutputSizeRatio)
        let estimatedOutputSizeBytes = max(
            Int64(Double(sourceSizeBytes) * outputSizeRatio),
            Constants.minimumEstimatedOutputSizeBytes
        )
        let cappedOutputSizeBytes = min(estimatedOutputSizeBytes, sourceSizeBytes)

        return VideoCompressionPlan(
            compressionLevel: compressionLevel,
            sourceSizeBytes: sourceSizeBytes,
            estimatedOutputSizeBytes: cappedOutputSizeBytes,
            estimatedSavedSizeBytes: max(sourceSizeBytes - cappedOutputSizeBytes, .zero)
        )
    }

    func estimatedCompressedSizeBytes(
        sourceSizeBytes: Int64,
        compressionLevel: Double
    ) -> Int64 {
        makePlan(
            sourceSizeBytes: sourceSizeBytes,
            compressionLevel: compressionLevel
        )
        .estimatedOutputSizeBytes
    }

    func estimatedSavedSizeRange(sourceSizeBytes: Int64) -> ClosedRange<Int64> {
        let minimumCompressionPlan = makePlan(
            sourceSizeBytes: sourceSizeBytes,
            compressionLevel: configuration.compressionLevelRange.lowerBound
        )
        let maximumCompressionPlan = makePlan(
            sourceSizeBytes: sourceSizeBytes,
            compressionLevel: configuration.compressionLevelRange.upperBound
        )

        return minimumCompressionPlan.estimatedSavedSizeBytes...maximumCompressionPlan.estimatedSavedSizeBytes
    }

    func compressVideo(
        localIdentifier: String,
        sourceSizeBytes: Int64,
        compressionLevel: Double
    ) -> AsyncThrowingStream<VideoCompressionEvent, Error> {
        AsyncThrowingStream { continuation in
            self.printDebugLog(
                """
                Stream started.
                • localIdentifier: \(localIdentifier)
                • sourceSizeBytes: \(sourceSizeBytes)
                • compressionLevel: \(compressionLevel)
                """
            )

            let cancellationToken = VideoCompressionCancellationToken()
            let task = Task(priority: .utility) { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                do {
                    let result = try await self.performCompression(
                        localIdentifier: localIdentifier,
                        sourceSizeBytes: sourceSizeBytes,
                        compressionLevel: compressionLevel,
                        cancellationToken: cancellationToken
                    ) { progress in
                        continuation.yield(.progress(progress))
                    }

                    if cancellationToken.isCancelled {
                        await self.deleteCompressedVideoIfNeeded(
                            localIdentifier: result.compressedLocalIdentifier
                        )
                        throw CancellationError()
                    }

                    switch continuation.yield(.completed(result)) {
                    case .enqueued:
                        break
                    case .dropped, .terminated:
                        await self.deleteCompressedVideoIfNeeded(
                            localIdentifier: result.compressedLocalIdentifier
                        )
                        throw CancellationError()
                    @unknown default:
                        break
                    }
                    continuation.finish()
                } catch is CancellationError {
                    self.printDebugLog("Stream cancelled.")
                    continuation.finish()
                } catch {
                    self.printDebugLog("Stream failed with error: \(String(reflecting: error))")
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                self.printDebugLog("Stream termination requested.")
                cancellationToken.cancel()
                task.cancel()
            }
        }
    }

    func deleteCompressedVideo(withLocalIdentifier localIdentifier: String) async throws {
        try await deleteAsset(withLocalIdentifier: localIdentifier)
    }
}

// MARK: - Private methods

private extension VideoCompressionService {

    enum Constants {

        static let compressionLevelRange = 0.0...1.0
        static let defaultCompressionLevel = 0.5
        static let maximumOutputSizeRatio = 0.9
        static let minimumOutputSizeRatio = 0.45
        static let minimumEstimatedOutputSizeBytes: Int64 = 1
        static let minimumVideoBitRate = 450_000
        static let audioBitRateReserve = 128_000
        static let audioSampleRate = 44_100
        static let audioChannelCount = 2
        static let audioLinearPCMBitDepth = 16
        static let outputFileExtension = "mp4"
        static let compressionQueueLabel = "com.example.portfolio.video.compression"
        static let loadingProgressWeight = 0.01
        static let savingProgressStart = 0.9
        static let compressingProgressWeight = savingProgressStart - loadingProgressWeight
        static let savingProgressWeight = 1 - savingProgressStart
    }

    typealias ProgressHandler = @Sendable (VideoCompressionProgress) -> Void

    func performCompression(
        localIdentifier: String,
        sourceSizeBytes: Int64,
        compressionLevel: Double,
        cancellationToken: VideoCompressionCancellationToken,
        progress: @escaping ProgressHandler
    ) async throws -> VideoCompressionResult {
        try cancellationToken.checkCancellation()
        reportProgress(
            stage: .loadingSource,
            stageFractionCompleted: .zero,
            progress: progress
        )

        let photoAsset = try fetchVideoAsset(localIdentifier: localIdentifier)
        printDebugLog(
            """
            Photo asset fetched.
            • duration: \(photoAsset.duration)
            • pixelSize: \(photoAsset.pixelWidth)x\(photoAsset.pixelHeight)
            """
        )
        let avAsset = try await requestAVAsset(
            for: photoAsset,
            cancellationToken: cancellationToken,
            progress: progress
        )
        printDebugLog("AVAsset requested.")

        try cancellationToken.checkCancellation()
        reportProgress(
            stage: .preparing,
            stageFractionCompleted: .zero,
            progress: progress
        )

        let plan = makePlan(
            sourceSizeBytes: sourceSizeBytes,
            compressionLevel: compressionLevel
        )
        let outputURL = makeTemporaryOutputURL()
        printDebugLog(
            """
            Compression plan prepared.
            • estimatedOutputSizeBytes: \(plan.estimatedOutputSizeBytes)
            • estimatedSavedSizeBytes: \(plan.estimatedSavedSizeBytes)
            • outputURL: \(outputURL.path)
            """
        )

        do {
            try await transcode(
                asset: avAsset,
                outputURL: outputURL,
                plan: plan,
                cancellationToken: cancellationToken,
                progress: progress
            )

            let compressedSizeBytes = try fileSizeBytes(at: outputURL)
            printDebugLog(
                """
                Transcoding finished.
                • originalSizeBytes: \(sourceSizeBytes)
                • compressedSizeBytes: \(compressedSizeBytes)
                """
            )
            guard compressedSizeBytes < sourceSizeBytes else {
                printDebugLog("Compressed file is not smaller than source.")
                throw VideoCompressionServiceError.compressedVideoIsNotSmaller
            }

            reportProgress(
                stage: .saving,
                stageFractionCompleted: .zero,
                progress: progress
            )
            try cancellationToken.checkCancellation()

            let compressedLocalIdentifier = try await saveCompressedVideo(
                outputURL: outputURL,
                sourceAsset: photoAsset
            )
            printDebugLog(
                """
                Saved compressed video.
                • compressedLocalIdentifier: \(compressedLocalIdentifier)
                """
            )

            if cancellationToken.isCancelled {
                printDebugLog("Cancellation requested after Photos save. Removing compressed asset.")
                await deleteCompressedVideoIfNeeded(localIdentifier: compressedLocalIdentifier)
                throw CancellationError()
            }

            reportProgress(
                stage: .saving,
                stageFractionCompleted: 1,
                progress: progress
            )

            return VideoCompressionResult(
                originalLocalIdentifier: localIdentifier,
                compressedLocalIdentifier: compressedLocalIdentifier,
                originalSizeBytes: sourceSizeBytes,
                compressedSizeBytes: compressedSizeBytes,
                savedSizeBytes: max(sourceSizeBytes - compressedSizeBytes, .zero)
            )
        } catch {
            printDebugLog("Removing temporary output file after failure: \(outputURL.path)")
            try? FileManager.default.removeItem(at: outputURL)
            throw error
        }
    }

    func deleteAsset(withLocalIdentifier localIdentifier: String) async throws {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        )

        guard fetchResult.count > 0 else { return }

        let assets = makeAssetArray(from: fetchResult)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard success else {
                    continuation.resume(throwing: VideoCompressionServiceError.photoLibraryDeleteFailed)
                    return
                }

                continuation.resume()
            }
        }
    }

    func deleteCompressedVideoIfNeeded(localIdentifier: String) async {
        do {
            try await deleteCompressedVideo(withLocalIdentifier: localIdentifier)
        } catch {
            printDebugLog("Failed to remove compressed asset with error: \(String(reflecting: error))")
        }
    }

    func fetchVideoAsset(localIdentifier: String) throws -> PHAsset {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        )

        guard let asset = fetchResult.firstObject else {
            throw VideoCompressionServiceError.assetNotFound
        }

        guard asset.mediaType == .video else {
            throw VideoCompressionServiceError.assetIsNotVideo
        }

        return asset
    }

    func requestAVAsset(
        for asset: PHAsset,
        cancellationToken: VideoCompressionCancellationToken,
        progress: @escaping ProgressHandler
    ) async throws -> AVAsset {
        let requestToken = PhotoKitAVAssetRequest()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                requestToken.setContinuation(continuation)

                guard requestToken.canStartRequest else { return }

                if cancellationToken.isCancelled {
                    requestToken.cancel()
                    return
                }

                let options = PHVideoRequestOptions()
                options.version = .current
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.progressHandler = { sourceProgress, error, stop, _ in
                    if cancellationToken.isCancelled {
                        stop.pointee = true
                        requestToken.cancel()
                        return
                    }

                    if error == nil {
                        self.reportProgress(
                            stage: .loadingSource,
                            stageFractionCompleted: sourceProgress,
                            progress: progress
                        )
                    }
                }

                let requestId = PHImageManager.default().requestAVAsset(
                    forVideo: asset,
                    options: options
                ) { avAsset, _, info in
                    if let error = info?[PHImageErrorKey] as? Error {
                        requestToken.resume(throwing: error)
                        return
                    }

                    if info?[PHImageCancelledKey] as? Bool == true {
                        requestToken.resume(throwing: CancellationError())
                        return
                    }

                    guard let avAsset else {
                        requestToken.resume(throwing: VideoCompressionServiceError.assetNotFound)
                        return
                    }

                    requestToken.resume(returning: avAsset)
                }

                requestToken.setRequestId(requestId)
            }
        } onCancel: {
            requestToken.cancel()
        }
    }

    func transcode(
        asset: AVAsset,
        outputURL: URL,
        plan: VideoCompressionPlan,
        cancellationToken: VideoCompressionCancellationToken,
        progress: @escaping ProgressHandler
    ) async throws {
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw VideoCompressionServiceError.sourceVideoTrackMissing
        }
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let metadata = try await asset.load(.metadata)
        let duration = try await asset.load(.duration)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
        let estimatedDataRate = try await videoTrack.load(.estimatedDataRate)
        printDebugLog(
            """
            Source track loaded.
            • naturalSize: \(naturalSize)
            • nominalFrameRate: \(nominalFrameRate)
            • estimatedDataRate: \(estimatedDataRate)
            """
        )

        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        writer.shouldOptimizeForNetworkUse = true
        writer.metadata = metadata

        let videoOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            ]
        )
        videoOutput.alwaysCopiesSampleData = false

        guard reader.canAdd(videoOutput) else {
            printDebugLog("Reader cannot add video output.")
            throw VideoCompressionServiceError.videoTrackUnsupported
        }

        reader.add(videoOutput)

        let durationSeconds = normalizedDuration(duration.seconds)
        let targetVideoBitRate = targetVideoBitRate(
            sourceVideoEstimatedDataRate: estimatedDataRate,
            plan: plan,
            durationSeconds: durationSeconds
        )
        let videoInput = try makeVideoInput(
            writer: writer,
            naturalSize: naturalSize,
            preferredTransform: preferredTransform,
            nominalFrameRate: nominalFrameRate,
            targetVideoBitRate: targetVideoBitRate
        )
        printDebugLog("Target video bit rate: \(targetVideoBitRate)")
        writer.add(videoInput)

        let audioBinding = try makeAudioBinding(
            audioTracks: audioTracks,
            reader: reader,
            writer: writer
        )

        try await writeMedia(
            reader: reader,
            writer: writer,
            videoOutput: videoOutput,
            videoInput: videoInput,
            audioBinding: audioBinding,
            durationSeconds: durationSeconds,
            cancellationToken: cancellationToken,
            progress: progress
        )
    }

    func makeVideoInput(
        writer: AVAssetWriter,
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform,
        nominalFrameRate: Float,
        targetVideoBitRate: Int
    ) throws -> AVAssetWriterInput {
        let width = normalizedVideoDimension(naturalSize.width)
        let height = normalizedVideoDimension(naturalSize.height)
        let compressionProperties: [String: Any] = [
            AVVideoAverageBitRateKey: targetVideoBitRate,
            AVVideoExpectedSourceFrameRateKey: max(Int(nominalFrameRate.rounded()), 24)
        ]

        let preferredCodecs: [AVVideoCodecType] = [
            .hevc,
            .h264
        ]

        for codec in preferredCodecs {
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: codec,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: compressionProperties
            ]
            let input = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: videoSettings
            )
            input.expectsMediaDataInRealTime = false
            input.transform = preferredTransform

            if writer.canAdd(input) {
                printDebugLog("Using video codec: \(codec.rawValue)")
                return input
            }
        }

        printDebugLog("Writer cannot add video input for HEVC or H.264.")
        throw VideoCompressionServiceError.videoTrackUnsupported
    }

    func makeAudioBinding(
        audioTracks: [AVAssetTrack],
        reader: AVAssetReader,
        writer: AVAssetWriter
    ) throws -> VideoCompressionAudioBinding? {
        guard let audioTrack = audioTracks.first else {
            printDebugLog("Source has no audio track.")
            return nil
        }

        if let passthroughAudioBinding = makePassthroughAudioBinding(
            audioTrack: audioTrack,
            reader: reader,
            writer: writer
        ) {
            return passthroughAudioBinding
        }

        return try makeAACAudioBinding(
            audioTrack: audioTrack,
            reader: reader,
            writer: writer
        )
    }

    func makePassthroughAudioBinding(
        audioTrack: AVAssetTrack,
        reader: AVAssetReader,
        writer: AVAssetWriter
    ) -> VideoCompressionAudioBinding? {
        let output = AVAssetReaderTrackOutput(
            track: audioTrack,
            outputSettings: nil
        )
        output.alwaysCopiesSampleData = false

        guard reader.canAdd(output) else {
            printDebugLog("Reader cannot add passthrough audio output.")
            return nil
        }

        let input = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: nil
        )
        input.expectsMediaDataInRealTime = false

        guard writer.canAdd(input) else {
            printDebugLog("Writer cannot add passthrough audio input. Falling back to AAC.")
            return nil
        }

        reader.add(output)
        writer.add(input)
        printDebugLog("Passthrough audio binding prepared.")

        return VideoCompressionAudioBinding(
            output: output,
            input: input
        )
    }

    func makeAACAudioBinding(
        audioTrack: AVAssetTrack,
        reader: AVAssetReader,
        writer: AVAssetWriter
    ) throws -> VideoCompressionAudioBinding {
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: Constants.audioSampleRate,
            AVNumberOfChannelsKey: Constants.audioChannelCount,
            AVLinearPCMBitDepthKey: Constants.audioLinearPCMBitDepth,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let output = AVAssetReaderTrackOutput(
            track: audioTrack,
            outputSettings: outputSettings
        )
        output.alwaysCopiesSampleData = false

        guard reader.canAdd(output) else {
            printDebugLog("Reader cannot add AAC fallback audio output.")
            throw VideoCompressionServiceError.audioTrackUnsupported
        }

        let inputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: Constants.audioSampleRate,
            AVNumberOfChannelsKey: Constants.audioChannelCount,
            AVEncoderBitRateKey: Constants.audioBitRateReserve
        ]
        let input = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: inputSettings
        )
        input.expectsMediaDataInRealTime = false

        guard writer.canAdd(input) else {
            printDebugLog("Writer cannot add AAC fallback audio input.")
            throw VideoCompressionServiceError.audioTrackUnsupported
        }

        reader.add(output)
        writer.add(input)
        printDebugLog("AAC audio binding prepared.")

        return VideoCompressionAudioBinding(
            output: output,
            input: input
        )
    }

    func writeMedia(
        reader: AVAssetReader,
        writer: AVAssetWriter,
        videoOutput: AVAssetReaderTrackOutput,
        videoInput: AVAssetWriterInput,
        audioBinding: VideoCompressionAudioBinding?,
        durationSeconds: Double,
        cancellationToken: VideoCompressionCancellationToken,
        progress: @escaping ProgressHandler
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let completion = VideoCompressionCompletion()
            let dispatchGroup = DispatchGroup()
            let processingQueue = DispatchQueue(
                label: Constants.compressionQueueLabel,
                qos: .utility
            )
            let mediaReferences = VideoCompressionMediaReferences(
                reader: reader,
                writer: writer,
                videoOutput: videoOutput,
                videoInput: videoInput,
                audioBinding: audioBinding
            )

            func finish(_ result: Result<Void, Error>) {
                completion.finish(result, continuation: continuation)
            }

            guard writer.startWriting() else {
                self.printDebugLog("Writer failed to start: \(String(describing: writer.error))")
                finish(.failure(writer.error ?? VideoCompressionServiceError.writerFailed))
                return
            }

            guard reader.startReading() else {
                self.printDebugLog("Reader failed to start: \(String(describing: reader.error))")
                writer.cancelWriting()
                finish(.failure(reader.error ?? VideoCompressionServiceError.readerFailed))
                return
            }

            writer.startSession(atSourceTime: .zero)

            dispatchGroup.enter()
            mediaReferences.videoInput.requestMediaDataWhenReady(on: processingQueue) {
                self.writeSamples(
                    output: mediaReferences.videoOutput,
                    input: mediaReferences.videoInput,
                    durationSeconds: durationSeconds,
                    cancellationToken: cancellationToken,
                    progress: progress,
                    onFailure: { error in
                        self.printDebugLog("Video sample writing failed: \(String(reflecting: error))")
                        mediaReferences.reader.cancelReading()
                        mediaReferences.writer.cancelWriting()
                        finish(.failure(error))
                    },
                    onFinish: {
                        dispatchGroup.leave()
                    }
                )
            }

            if
                let audioOutput = mediaReferences.audioOutput,
                let audioInput = mediaReferences.audioInput
            {
                dispatchGroup.enter()
                audioInput.requestMediaDataWhenReady(on: processingQueue) {
                    self.writeSamples(
                        output: audioOutput,
                        input: audioInput,
                        durationSeconds: nil,
                        cancellationToken: cancellationToken,
                        progress: nil,
                        onFailure: { error in
                            self.printDebugLog("Audio sample writing failed: \(String(reflecting: error))")
                            mediaReferences.reader.cancelReading()
                            mediaReferences.writer.cancelWriting()
                            finish(.failure(error))
                        },
                        onFinish: {
                            dispatchGroup.leave()
                        }
                    )
                }
            }

            dispatchGroup.notify(queue: processingQueue) {
                if cancellationToken.isCancelled {
                    self.printDebugLog("Cancelling reader/writer before finishWriting.")
                    mediaReferences.reader.cancelReading()
                    mediaReferences.writer.cancelWriting()
                    finish(.failure(CancellationError()))
                    return
                }

                if mediaReferences.reader.status == .failed {
                    self.printDebugLog("Reader failed: \(String(describing: mediaReferences.reader.error))")
                    mediaReferences.writer.cancelWriting()
                    finish(.failure(mediaReferences.reader.error ?? VideoCompressionServiceError.readerFailed))
                    return
                }

                mediaReferences.writer.finishWriting {
                    switch mediaReferences.writer.status {
                    case .completed:
                        finish(.success(()))
                    case .cancelled:
                        self.printDebugLog("Writer cancelled.")
                        finish(.failure(CancellationError()))
                    default:
                        self.printDebugLog("Writer failed: \(String(describing: mediaReferences.writer.error))")
                        finish(.failure(mediaReferences.writer.error ?? VideoCompressionServiceError.writerFailed))
                    }
                }
            }
        }
    }

    func writeSamples(
        output: AVAssetReaderOutput,
        input: AVAssetWriterInput,
        durationSeconds: Double?,
        cancellationToken: VideoCompressionCancellationToken,
        progress: ProgressHandler?,
        onFailure: @escaping (Error) -> Void,
        onFinish: @escaping () -> Void
    ) {
        while input.isReadyForMoreMediaData {
            do {
                try cancellationToken.checkCancellation()
            } catch {
                input.markAsFinished()
                onFailure(error)
                onFinish()
                return
            }

            guard let sampleBuffer = output.copyNextSampleBuffer() else {
                input.markAsFinished()
                onFinish()
                return
            }

            if let durationSeconds, durationSeconds > .zero {
                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                reportProgress(
                    stage: .compressing,
                    stageFractionCompleted: min(max(timestamp.seconds / durationSeconds, .zero), 1),
                    progress: progress
                )
            }

            guard input.append(sampleBuffer) else {
                input.markAsFinished()
                onFailure(VideoCompressionServiceError.writerFailed)
                onFinish()
                return
            }
        }
    }

    func saveCompressedVideo(
        outputURL: URL,
        sourceAsset: PHAsset
    ) async throws -> String {
        let assetCollections = fetchEditableAssetCollections(containing: sourceAsset)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            var createdLocalIdentifier: String?

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.creationDate = sourceAsset.creationDate
                request.location = sourceAsset.location

                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true

                request.addResource(
                    with: .video,
                    fileURL: outputURL,
                    options: options
                )

                guard let placeholder = request.placeholderForCreatedAsset else { return }

                createdLocalIdentifier = placeholder.localIdentifier

                assetCollections.forEach { assetCollection in
                    PHAssetCollectionChangeRequest(for: assetCollection)?
                        .addAssets([placeholder] as NSArray)
                }
            } completionHandler: { success, error in
                if let error {
                    self.printDebugLog("Photo Library save failed with error: \(String(reflecting: error))")
                    continuation.resume(throwing: error)
                    return
                }

                guard success else {
                    self.printDebugLog("Photo Library save failed without error.")
                    continuation.resume(throwing: VideoCompressionServiceError.photoLibrarySaveFailed)
                    return
                }

                guard let createdLocalIdentifier else {
                    self.printDebugLog("Photo Library save succeeded without created local identifier.")
                    continuation.resume(throwing: VideoCompressionServiceError.photoLibrarySaveFailed)
                    return
                }

                continuation.resume(returning: createdLocalIdentifier)
            }
        }
    }

    func targetVideoBitRate(
        sourceVideoEstimatedDataRate: Float,
        plan: VideoCompressionPlan,
        durationSeconds: Double
    ) -> Int {
        let targetTotalBitRate = Double(plan.estimatedOutputSizeBytes) * 8 / max(durationSeconds, 1)
        let targetVideoBitRate = max(
            Int(targetTotalBitRate) - Constants.audioBitRateReserve,
            Constants.minimumVideoBitRate
        )
        let sourceVideoBitRate = Int(sourceVideoEstimatedDataRate)

        guard sourceVideoBitRate > .zero else { return targetVideoBitRate }

        return min(
            targetVideoBitRate,
            max(Int(Double(sourceVideoBitRate) * 0.95), Constants.minimumVideoBitRate)
        )
    }

    func fetchEditableAssetCollections(containing asset: PHAsset) -> [PHAssetCollection] {
        let fetchResult = PHAssetCollection.fetchAssetCollectionsContaining(
            asset,
            with: .album,
            options: nil
        )
        var assetCollections = [PHAssetCollection]()
        assetCollections.reserveCapacity(fetchResult.count)

        fetchResult.enumerateObjects { assetCollection, _, _ in
            guard assetCollection.canPerform(.addContent) else { return }
            assetCollections.append(assetCollection)
        }

        return assetCollections
    }

    func makeAssetArray(from fetchResult: PHFetchResult<PHAsset>) -> [PHAsset] {
        var assets = [PHAsset]()
        assets.reserveCapacity(fetchResult.count)

        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        return assets
    }

    func normalizedVideoDimension(_ dimension: CGFloat) -> Int {
        let roundedDimension = max(Int(abs(dimension).rounded(.down)), 2)

        if roundedDimension.isMultiple(of: 2) {
            return roundedDimension
        }

        return max(roundedDimension - 1, 2)
    }

    func normalizedCompressionLevel(_ compressionLevel: Double) -> Double {
        min(
            max(compressionLevel, Constants.compressionLevelRange.lowerBound),
            Constants.compressionLevelRange.upperBound
        )
    }

    func normalizedDuration(_ duration: Double) -> Double {
        guard duration.isFinite else { return 1 }
        return max(duration, 1)
    }

    func makeTemporaryOutputURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("quickcleanup-video-compression-\(UUID().uuidString)")
            .appendingPathExtension(Constants.outputFileExtension)
    }

    func fileSizeBytes(at url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = values.fileSize else {
            throw VideoCompressionServiceError.outputFileMissing
        }

        return Int64(fileSize)
    }

    nonisolated func printDebugLog(_ message: String) {
        #if DEBUG
        print("[VideoCompressionService] \(message)")
        #endif
    }

    func reportProgress(
        stage: VideoCompressionStage,
        stageFractionCompleted: Double,
        progress: ProgressHandler?
    ) {
        let stageFractionCompleted = min(max(stageFractionCompleted, .zero), 1)
        let totalFractionCompleted: Double

        switch stage {
        case .loadingSource:
            totalFractionCompleted = stageFractionCompleted * Constants.loadingProgressWeight
        case .preparing:
            totalFractionCompleted = Constants.loadingProgressWeight
        case .compressing:
            totalFractionCompleted = Constants.loadingProgressWeight
                + stageFractionCompleted * Constants.compressingProgressWeight
        case .saving:
            totalFractionCompleted = Constants.savingProgressStart
                + stageFractionCompleted * Constants.savingProgressWeight
        }

        progress?(
            VideoCompressionProgress(
                stage: stage,
                stageFractionCompleted: stageFractionCompleted,
                totalFractionCompleted: totalFractionCompleted
            )
        )
    }
}

// MARK: - VideoCompressionAudioBinding

private struct VideoCompressionAudioBinding {

    let output: AVAssetReaderTrackOutput
    let input: AVAssetWriterInput
}

// MARK: - VideoCompressionMediaReferences

private final class VideoCompressionMediaReferences: @unchecked Sendable {

    nonisolated(unsafe) let reader: AVAssetReader
    nonisolated(unsafe) let writer: AVAssetWriter
    nonisolated(unsafe) let videoOutput: AVAssetReaderTrackOutput
    nonisolated(unsafe) let videoInput: AVAssetWriterInput
    nonisolated(unsafe) let audioOutput: AVAssetReaderTrackOutput?
    nonisolated(unsafe) let audioInput: AVAssetWriterInput?

    init(
        reader: AVAssetReader,
        writer: AVAssetWriter,
        videoOutput: AVAssetReaderTrackOutput,
        videoInput: AVAssetWriterInput,
        audioBinding: VideoCompressionAudioBinding?
    ) {
        self.reader = reader
        self.writer = writer
        self.videoOutput = videoOutput
        self.videoInput = videoInput
        audioOutput = audioBinding?.output
        audioInput = audioBinding?.input
    }
}

// MARK: - VideoCompressionCancellationToken

private final class VideoCompressionCancellationToken: @unchecked Sendable {

    private let lock = NSLock()
    nonisolated(unsafe) private var _isCancelled = false

    nonisolated var isCancelled: Bool {
        lock.lock()
        let isCancelled = _isCancelled
        lock.unlock()
        return isCancelled
    }

    nonisolated func cancel() {
        lock.lock()
        _isCancelled = true
        lock.unlock()
    }

    nonisolated func checkCancellation() throws {
        if isCancelled {
            throw CancellationError()
        }
    }
}

// MARK: - PhotoKitAVAssetRequest

private final class PhotoKitAVAssetRequest: @unchecked Sendable {

    private let lock = NSLock()
    nonisolated(unsafe) private var requestId: PHImageRequestID = PHInvalidImageRequestID
    nonisolated(unsafe) private var continuation: CheckedContinuation<AVAsset, Error>?
    nonisolated(unsafe) private var isCancelled = false
    nonisolated(unsafe) private var isFinished = false

    nonisolated var canStartRequest: Bool {
        lock.lock()
        let canStartRequest = !isCancelled && !isFinished
        lock.unlock()
        return canStartRequest
    }

    nonisolated func setContinuation(_ continuation: CheckedContinuation<AVAsset, Error>) {
        lock.lock()
        if isCancelled {
            isFinished = true
            lock.unlock()
            continuation.resume(throwing: CancellationError())
            return
        }

        self.continuation = continuation
        lock.unlock()
    }

    nonisolated func setRequestId(_ requestId: PHImageRequestID) {
        lock.lock()
        self.requestId = requestId
        let shouldCancelRequest = isCancelled
        lock.unlock()

        if shouldCancelRequest {
            cancelImageRequest(requestId)
        }
    }

    nonisolated func resume(returning asset: AVAsset) {
        resume(with: .success(asset))
    }

    nonisolated func resume(throwing error: Error) {
        resume(with: .failure(error))
    }

    nonisolated func cancel() {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }

        isCancelled = true
        isFinished = true
        let requestId = requestId
        let continuation = continuation
        self.continuation = nil
        lock.unlock()

        cancelImageRequest(requestId)
        continuation?.resume(throwing: CancellationError())
    }

    private nonisolated func resume(with result: Result<AVAsset, Error>) {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }

        isFinished = true
        let continuation = continuation
        self.continuation = nil
        lock.unlock()

        continuation?.resume(with: result)
    }

    private nonisolated func cancelImageRequest(_ requestId: PHImageRequestID) {
        guard requestId != PHInvalidImageRequestID else { return }
        PHImageManager.default().cancelImageRequest(requestId)
    }
}

// MARK: - VideoCompressionCompletion

private final class VideoCompressionCompletion: @unchecked Sendable {

    private let lock = NSLock()
    nonisolated(unsafe) private var isFinished = false

    nonisolated func finish(
        _ result: Result<Void, Error>,
        continuation: CheckedContinuation<Void, Error>
    ) {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }

        isFinished = true
        lock.unlock()

        continuation.resume(with: result)
    }
}
