import Foundation
import UIKit
@preconcurrency import Photos
@preconcurrency import Vision

struct SimilarAssetAnalysisResult: Sendable {

    let analyzedAt: Date
    let groups: [SimilarAssetGroupResult]
}

struct SimilarAssetGroupResult: Sendable {

    let assetLocalIdentifiers: [String]
    let assetQualityScores: [String: Double]
    let bestAssetLocalIdentifier: String
    let totalBytes: Int64
    let newestAssetDate: Date?
}

final class SimilarAssetsService {

    typealias EligibilityFilter = @Sendable (GalleryAssetSnapshot) -> Bool

    private let analysisQueue = DispatchQueue(
        label: "com.example.portfolio.similar-assets.analysis",
        qos: .userInitiated
    )

    func analyzeSimilarAssets(
        from assets: [GalleryAssetSnapshot],
        analysisName: String,
        eligibilityFilter: @escaping EligibilityFilter
    ) async throws -> SimilarAssetAnalysisResult {
        let job = SimilarAssetsAnalysisJob()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard job.setContinuation(continuation) else { return }

                analysisQueue.async {
                    let metricsTracker = AnalysisMetricsTracker.make(
                        analysisName: analysisName,
                        totalAssetCount: assets.count
                    )

                    do {
                        try job.checkCancellation()

                        let result = try self.performSimilarAssetsAnalysis(
                            from: assets,
                            eligibilityFilter: eligibilityFilter,
                            job: job,
                            metricsTracker: metricsTracker
                        )
                        metricsTracker?.printCompletionSummary(groupCount: result.groups.count)
                        job.resume(returning: result)
                    } catch {
                        if !(error is CancellationError) {
                            metricsTracker?.printFailureSummary(error: error)
                        }
                        job.resume(throwing: error)
                    }
                }
            }
        } onCancel: {
            job.cancel()
        }
    }
}

// MARK: - Private

private extension SimilarAssetsService {

    enum Constants {

        static let featurePrintDistanceThreshold: Float = 2.5
        static let differenceHashDistanceThreshold = 10
        static let maximumNeighborCount = 24
        static let maximumAspectRatioDelta = 0.03
        static let minimumDimensionSimilarity = 0.85
        static let comparisonWindow: TimeInterval = 60 * 10
        static let thumbnailSize = CGSize(width: 256, height: 256)
        static let qualityThumbnailSide = 64
        static let differenceHashWidth = 9
        static let differenceHashHeight = 8
        static let signatureSide = 64
        static let signatureColorHistogramBins = 16
        static let mismatchEdgeRatioThreshold = 3.0
        static let mismatchColorHistogramDistanceThreshold = 1.2
        static let mismatchLumaStdDevDeltaThreshold = 0.075
    }

    func performSimilarAssetsAnalysis(
        from assets: [GalleryAssetSnapshot],
        eligibilityFilter: EligibilityFilter,
        job: SimilarAssetsAnalysisJob,
        metricsTracker: AnalysisMetricsTracker?
    ) throws -> SimilarAssetAnalysisResult {
        let eligibleAssets = assets
            .filter(eligibilityFilter)
            .sorted {
                comparisonDate(for: $0) > comparisonDate(for: $1)
            }

        metricsTracker?.setEligibleAssetCount(eligibleAssets.count)

        return try performAnalysis(
            from: eligibleAssets,
            job: job,
            metricsTracker: metricsTracker
        )
    }

    func performAnalysis(
        from assets: [GalleryAssetSnapshot],
        job: SimilarAssetsAnalysisJob,
        metricsTracker: AnalysisMetricsTracker?
    ) throws -> SimilarAssetAnalysisResult {
        guard !assets.isEmpty else {
            return SimilarAssetAnalysisResult(
                analyzedAt: .now,
                groups: []
            )
        }

        let imageManager = PHImageManager.default()
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: assets.map(\.localIdentifier),
            options: nil
        )

        var assetsByIdentifier = [String: PHAsset]()
        assetsByIdentifier.reserveCapacity(fetchResult.count)

        fetchResult.enumerateObjects { asset, _, _ in
            assetsByIdentifier[asset.localIdentifier] = asset
        }

        return SimilarAssetAnalysisResult(
            analyzedAt: .now,
            groups: try makeGroups(
                from: assets,
                assetsByIdentifier: assetsByIdentifier,
                imageManager: imageManager,
                job: job,
                metricsTracker: metricsTracker
            )
        )
    }

    func makeGroups(
        from assets: [GalleryAssetSnapshot],
        assetsByIdentifier: [String: PHAsset],
        imageManager: PHImageManager,
        job: SimilarAssetsAnalysisJob,
        metricsTracker: AnalysisMetricsTracker?
    ) throws -> [SimilarAssetGroupResult] {
        guard assets.count > 1 else { return [] }

        var groupAccumulators = [SimilarAssetGroupAccumulator]()
        var candidateWindow = [AnalyzedSimilarAssetCandidate]()
        candidateWindow.reserveCapacity(Constants.maximumNeighborCount + 1)
        var nextAssetIndex = 0

        try fillCandidateWindow(
            &candidateWindow,
            nextAssetIndex: &nextAssetIndex,
            from: assets,
            assetsByIdentifier: assetsByIdentifier,
            imageManager: imageManager,
            job: job,
            metricsTracker: metricsTracker
        )

        while !candidateWindow.isEmpty {
            try job.checkCancellation()

            if !candidateWindow[0].isGrouped {
                let anchor = candidateWindow[0]
                var groupMemberIndices = [Int]()
                groupMemberIndices.reserveCapacity(Constants.maximumNeighborCount + 1)
                groupMemberIndices.append(0)

                for candidateIndex in 1..<candidateWindow.count {
                    guard !candidateWindow[candidateIndex].isGrouped else { continue }

                    let candidate = candidateWindow[candidateIndex]
                    guard canCompare(anchor.snapshot, candidate.snapshot) else { continue }

                    guard try isVisualMatch(anchor, candidate) else { continue }
                    groupMemberIndices.append(candidateIndex)
                }

                if groupMemberIndices.count > 1 {
                    groupMemberIndices.forEach {
                        candidateWindow[$0].isGrouped = true
                    }

                    try appendGroupCandidates(
                        groupMemberIndices.map { candidateWindow[$0] },
                        to: &groupAccumulators
                    )
                }
            }

            candidateWindow.removeFirst()
            try fillCandidateWindow(
                &candidateWindow,
                nextAssetIndex: &nextAssetIndex,
                from: assets,
                assetsByIdentifier: assetsByIdentifier,
                imageManager: imageManager,
                job: job,
                metricsTracker: metricsTracker
            )
            metricsTracker?.recordMemoryUsage()
        }

        return groupAccumulators.map {
            makeGroupResult(from: $0.members)
        }
    }

    func appendGroupCandidates(
        _ candidates: [AnalyzedSimilarAssetCandidate],
        to groups: inout [SimilarAssetGroupAccumulator]
    ) throws {
        if let groupIndex = try groups.lastIndex(where: {
            try canMerge($0, with: candidates)
        }) {
            groups[groupIndex].append(candidates)
        } else if let accumulator = SimilarAssetGroupAccumulator(candidates: candidates) {
            groups.append(accumulator)
        }
    }

    func canMerge(
        _ group: SimilarAssetGroupAccumulator,
        with candidates: [AnalyzedSimilarAssetCandidate]
    ) throws -> Bool {
        guard let candidateAnchor = candidates.first else { return false }

        for groupAnchor in group.mergeAnchors {
            guard canMergeGroupAnchors(groupAnchor.snapshot, candidateAnchor.snapshot) else {
                continue
            }

            if try isVisualMatch(groupAnchor, candidateAnchor) {
                return true
            }
        }

        return false
    }

    func canMergeGroupAnchors(
        _ lhs: GalleryAssetSnapshot,
        _ rhs: GalleryAssetSnapshot
    ) -> Bool {
        let lhsIsLandscape = lhs.pixelWidth >= lhs.pixelHeight
        let rhsIsLandscape = rhs.pixelWidth >= rhs.pixelHeight

        guard lhsIsLandscape == rhsIsLandscape else { return false }

        let aspectDelta = abs(aspectRatio(for: lhs) - aspectRatio(for: rhs))

        guard aspectDelta <= Constants.maximumAspectRatioDelta else { return false }

        let dateDelta = abs(comparisonDate(for: lhs).timeIntervalSince(comparisonDate(for: rhs)))

        return dateDelta <= Constants.comparisonWindow
    }

    func fillCandidateWindow(
        _ candidateWindow: inout [AnalyzedSimilarAssetCandidate],
        nextAssetIndex: inout Int,
        from assets: [GalleryAssetSnapshot],
        assetsByIdentifier: [String: PHAsset],
        imageManager: PHImageManager,
        job: SimilarAssetsAnalysisJob,
        metricsTracker: AnalysisMetricsTracker?
    ) throws {
        while nextAssetIndex < assets.count
        && candidateWindow.count < Constants.maximumNeighborCount + 1 {
            if let candidate = try makeAnalyzedCandidate(
                from: assets[nextAssetIndex],
                assetsByIdentifier: assetsByIdentifier,
                imageManager: imageManager,
                job: job,
                metricsTracker: metricsTracker
            ) {
                candidateWindow.append(candidate)
            }

            nextAssetIndex += 1
        }
    }

    func makeAnalyzedCandidate(
        from snapshot: GalleryAssetSnapshot,
        assetsByIdentifier: [String: PHAsset],
        imageManager: PHImageManager,
        job: SimilarAssetsAnalysisJob,
        metricsTracker: AnalysisMetricsTracker?
    ) throws -> AnalyzedSimilarAssetCandidate? {
        try job.checkCancellation()

        guard let asset = assetsByIdentifier[snapshot.localIdentifier] else {
            return nil
        }

        return try autoreleasepool {
            guard let cgImage = loadThumbnailImage(
                for: asset,
                using: imageManager
            ) else {
                return nil
            }

            let featurePrint = try makeFeaturePrint(from: cgImage)
            let differenceHash = makeDifferenceHash(from: cgImage)
            let qualityScore = qualityScore(
                for: cgImage,
                snapshot: snapshot
            )
            let imageSignature = imageSignature(from: cgImage)

            metricsTracker?.recordMemoryUsage()

            return AnalyzedSimilarAssetCandidate(
                snapshot: snapshot,
                featurePrint: .init(featurePrint),
                differenceHash: differenceHash,
                qualityScore: qualityScore,
                imageSignature: imageSignature
            )
        }
    }

    func isVisualMatch(
        _ lhs: AnalyzedSimilarAssetCandidate,
        _ rhs: AnalyzedSimilarAssetCandidate
    ) throws -> Bool {
        let distance = try featurePrintDistance(
            lhs.featurePrint.value,
            rhs.featurePrint.value
        )

        guard distance <= Constants.featurePrintDistanceThreshold else {
            return false
        }

        let differenceHashDistance = hammingDistance(
            lhs.differenceHash,
            rhs.differenceHash
        )

        guard differenceHashDistance <= Constants.differenceHashDistanceThreshold else {
            return false
        }

        return !hasStrongStructuralMismatch(
            lhs.imageSignature,
            rhs.imageSignature
        )
    }

    func hasStrongStructuralMismatch(
        _ lhs: SimilarAssetImageSignature,
        _ rhs: SimilarAssetImageSignature
    ) -> Bool {
        let lumaStdDevDelta = abs(
            lhs.luminanceStandardDeviation - rhs.luminanceStandardDeviation
        )
        let edgeRatio = max(lhs.edgeMagnitude, rhs.edgeMagnitude)
            / max(min(lhs.edgeMagnitude, rhs.edgeMagnitude), 0.000_001)
        let colorHistogramDistance = zip(lhs.colorHistogram, rhs.colorHistogram)
            .reduce(into: Double.zero) { $0 += abs($1.0 - $1.1) } / 2
        let hasDifferentStructure = edgeRatio > Constants.mismatchEdgeRatioThreshold
        let hasDifferentContrast = lumaStdDevDelta > Constants.mismatchLumaStdDevDeltaThreshold
        let hasDifferentColorDistribution = colorHistogramDistance
            > Constants.mismatchColorHistogramDistanceThreshold

        return hasDifferentStructure && (hasDifferentContrast || hasDifferentColorDistribution)
    }

    func imageSignature(from cgImage: CGImage) -> SimilarAssetImageSignature {
        let grayscalePixels = grayscalePixels(
            from: cgImage,
            side: Constants.signatureSide
        )
        let luminanceMean = mean(from: grayscalePixels)
        let luminanceStandardDeviation = standardDeviation(
            from: grayscalePixels,
            mean: luminanceMean
        )
        let edgeMagnitude = edgeMagnitude(
            from: grayscalePixels,
            width: Constants.signatureSide,
            height: Constants.signatureSide
        )
        let colorHistogram = colorHistogram(
            from: cgImage,
            side: Constants.signatureSide,
            binCount: Constants.signatureColorHistogramBins
        )

        return SimilarAssetImageSignature(
            luminanceStandardDeviation: luminanceStandardDeviation,
            edgeMagnitude: edgeMagnitude,
            colorHistogram: colorHistogram
        )
    }

    func mean(from pixels: [UInt8]) -> Double {
        guard !pixels.isEmpty else { return .zero }

        return pixels.reduce(into: Double.zero) { partialResult, pixel in
            partialResult += Double(pixel) / 255
        } / Double(pixels.count)
    }

    func standardDeviation(
        from pixels: [UInt8],
        mean: Double
    ) -> Double {
        guard !pixels.isEmpty else { return .zero }

        let variance = pixels.reduce(into: Double.zero) { partialResult, pixel in
            let value = (Double(pixel) / 255) - mean
            partialResult += value * value
        } / Double(pixels.count)

        return sqrt(variance)
    }

    func edgeMagnitude(
        from pixels: [UInt8],
        width: Int,
        height: Int
    ) -> Double {
        guard pixels.count == width * height else { return .zero }

        var totalMagnitude = Double.zero
        var count = 0

        for row in 0..<height {
            for column in 0..<width {
                let index = row * width + column

                if column + 1 < width {
                    totalMagnitude += abs(Double(pixels[index]) - Double(pixels[index + 1])) / 255
                    count += 1
                }

                if row + 1 < height {
                    totalMagnitude += abs(Double(pixels[index]) - Double(pixels[index + width])) / 255
                    count += 1
                }
            }
        }

        return totalMagnitude / Double(max(count, 1))
    }

    func colorHistogram(
        from cgImage: CGImage,
        side: Int,
        binCount: Int
    ) -> [Double] {
        let bytesPerPixel = 4
        let bytesPerRow = side * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: side * side * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return [Double](repeating: .zero, count: binCount * 3)
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))

        var histogram = [Double](repeating: .zero, count: binCount * 3)
        let pixelCount = side * side

        for pixelIndex in 0..<pixelCount {
            let pixelOffset = pixelIndex * bytesPerPixel

            for channel in 0..<3 {
                let value = Int(pixels[pixelOffset + channel])
                let bin = min(value * binCount / 256, binCount - 1)
                histogram[(channel * binCount) + bin] += 1
            }
        }

        return histogram.map {
            $0 / Double(max(pixelCount, 1))
        }
    }

    func comparisonDate(for asset: GalleryAssetSnapshot) -> Date {
        asset.creationDate ?? asset.modificationDate ?? .distantPast
    }

    func dimensionSimilarity(
        _ lhsDimension: Int32,
        _ rhsDimension: Int32
    ) -> Double {
        let lhs = max(Double(lhsDimension), 1)
        let rhs = max(Double(rhsDimension), 1)
        return min(lhs, rhs) / max(lhs, rhs)
    }

    func hammingDistance(
        _ lhs: UInt64,
        _ rhs: UInt64
    ) -> Int {
        (lhs ^ rhs).nonzeroBitCount
    }

    func makeDifferenceHash(from cgImage: CGImage) -> UInt64 {
        let pixels = grayscalePixels(
            from: cgImage,
            width: Constants.differenceHashWidth,
            height: Constants.differenceHashHeight
        )

        guard pixels.count == Constants.differenceHashWidth * Constants.differenceHashHeight else {
            return .zero
        }

        var hash: UInt64 = .zero
        var bitIndex = 0

        for row in 0..<Constants.differenceHashHeight {
            let rowStart = row * Constants.differenceHashWidth

            for column in 0..<(Constants.differenceHashWidth - 1) {
                let lhsPixel = pixels[rowStart + column]
                let rhsPixel = pixels[rowStart + column + 1]

                if lhsPixel > rhsPixel {
                    hash |= 1 << bitIndex
                }

                bitIndex += 1
            }
        }

        return hash
    }

    func makeGroupResult(
        from members: [SimilarAssetGroupMember]
    ) -> SimilarAssetGroupResult {
        let bestMember = members.max {
            isLeftGroupMemberWorse($0, $1)
        }
        let orderedMembers = members.sorted {
            isLeftGroupMemberNewer($0, $1)
        }

        return SimilarAssetGroupResult(
            assetLocalIdentifiers: orderedMembers.map(\.snapshot.localIdentifier),
            assetQualityScores: Dictionary(
                uniqueKeysWithValues: orderedMembers.map {
                    ($0.snapshot.localIdentifier, $0.qualityScore)
                }
            ),
            bestAssetLocalIdentifier: bestMember?.snapshot.localIdentifier
                ?? orderedMembers[0].snapshot.localIdentifier,
            totalBytes: orderedMembers.reduce(into: Int64.zero) { partialResult, member in
                partialResult += member.snapshot.sizeBytes
            },
            newestAssetDate: orderedMembers.first.map { comparisonDate(for: $0.snapshot) }
        )
    }

    func canCompare(
        _ lhs: GalleryAssetSnapshot,
        _ rhs: GalleryAssetSnapshot
    ) -> Bool {
        let lhsIsLandscape = lhs.pixelWidth >= lhs.pixelHeight
        let rhsIsLandscape = rhs.pixelWidth >= rhs.pixelHeight

        guard lhsIsLandscape == rhsIsLandscape else { return false }

        let lhsAspectRatio = aspectRatio(for: lhs)
        let rhsAspectRatio = aspectRatio(for: rhs)

        guard abs(lhsAspectRatio - rhsAspectRatio) <= Constants.maximumAspectRatioDelta else {
            return false
        }

        guard
            dimensionSimilarity(lhs.pixelWidth, rhs.pixelWidth) >= Constants.minimumDimensionSimilarity,
            dimensionSimilarity(lhs.pixelHeight, rhs.pixelHeight) >= Constants.minimumDimensionSimilarity
        else {
            return false
        }

        let lhsDate = comparisonDate(for: lhs)
        let rhsDate = comparisonDate(for: rhs)

        return abs(lhsDate.timeIntervalSince(rhsDate)) <= Constants.comparisonWindow
    }

    func aspectRatio(for asset: GalleryAssetSnapshot) -> Double {
        guard asset.pixelHeight > 0 else { return .zero }
        return Double(asset.pixelWidth) / Double(asset.pixelHeight)
    }

    func featurePrintDistance(
        _ lhs: VNFeaturePrintObservation,
        _ rhs: VNFeaturePrintObservation
    ) throws -> Float {
        var distance: Float = .zero
        try lhs.computeDistance(&distance, to: rhs)
        return distance
    }

    func loadThumbnailImage(
        for asset: PHAsset,
        using imageManager: PHImageManager
    ) -> CGImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = true

        var image: UIImage?
        let targetSize = Constants.thumbnailSize

        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { requestedImage, _ in
            image = requestedImage
        }

        guard
            let image,
            let cgImage = image.cgImage
        else {
            return nil
        }

        return cgImage
    }

    func makeFeaturePrint(from cgImage: CGImage) throws -> VNFeaturePrintObservation {
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNGenerateImageFeaturePrintRequest()

        try requestHandler.perform([request])

        guard let featurePrint = request.results?.first as? VNFeaturePrintObservation else {
            throw SimilarAssetsServiceError.missingFeaturePrint
        }

        return featurePrint
    }

    func qualityScore(
        for cgImage: CGImage,
        snapshot: GalleryAssetSnapshot
    ) -> Double {
        let pixels = grayscalePixels(
            from: cgImage,
            side: Constants.qualityThumbnailSide
        )

        let sharpnessScore = sharpnessScore(from: pixels)
        let exposureScore = exposureScore(from: pixels)
        let resolutionScore = resolutionScore(for: snapshot)

        return (sharpnessScore * 0.45) + (exposureScore * 0.2) + (resolutionScore * 0.35)
    }

    func grayscalePixels(
        from cgImage: CGImage,
        side: Int
    ) -> [UInt8] {
        grayscalePixels(
            from: cgImage,
            width: side,
            height: side
        )
    }

    func grayscalePixels(
        from cgImage: CGImage,
        width: Int,
        height: Int
    ) -> [UInt8] {
        let bytesPerRow = width
        var pixels = [UInt8](repeating: 0, count: width * height)

        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2),
            let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            )
        else {
            return pixels
        }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixels
    }

    func sharpnessScore(from pixels: [UInt8]) -> Double {
        guard pixels.count == Constants.qualityThumbnailSide * Constants.qualityThumbnailSide else {
            return .zero
        }

        var accumulatedLaplacian = Double.zero

        for row in 1..<(Constants.qualityThumbnailSide - 1) {
            for column in 1..<(Constants.qualityThumbnailSide - 1) {
                let index = row * Constants.qualityThumbnailSide + column
                let center = Double(pixels[index])
                let left = Double(pixels[index - 1])
                let right = Double(pixels[index + 1])
                let top = Double(pixels[index - Constants.qualityThumbnailSide])
                let bottom = Double(pixels[index + Constants.qualityThumbnailSide])
                let laplacian = abs((4 * center) - left - right - top - bottom)

                accumulatedLaplacian += laplacian
            }
        }

        let pixelCount = Double(
            (Constants.qualityThumbnailSide - 2)
            * (Constants.qualityThumbnailSide - 2)
        )
        let averageLaplacian = accumulatedLaplacian / max(pixelCount, 1)

        return min(averageLaplacian / 255, 1)
    }

    func exposureScore(from pixels: [UInt8]) -> Double {
        guard !pixels.isEmpty else { return .zero }

        let meanBrightness = pixels.reduce(into: Double.zero) { partialResult, pixel in
            partialResult += Double(pixel) / 255
        } / Double(pixels.count)

        return max(0, 1 - abs(meanBrightness - 0.55) * 2)
    }

    func resolutionScore(for snapshot: GalleryAssetSnapshot) -> Double {
        let pixelCount = max(Double(snapshot.pixelWidth) * Double(snapshot.pixelHeight), 1)
        let megapixels = pixelCount / 1_000_000
        return min(log10(megapixels + 1) / log10(13), 1)
    }

    func isLeftGroupMemberNewer(
        _ lhs: SimilarAssetGroupMember,
        _ rhs: SimilarAssetGroupMember
    ) -> Bool {
        let lhsDate = comparisonDate(for: lhs.snapshot)
        let rhsDate = comparisonDate(for: rhs.snapshot)

        if lhsDate == rhsDate {
            return lhs.qualityScore > rhs.qualityScore
        }

        return lhsDate > rhsDate
    }

    func isLeftGroupMemberWorse(
        _ lhs: SimilarAssetGroupMember,
        _ rhs: SimilarAssetGroupMember
    ) -> Bool {
        if lhs.qualityScore == rhs.qualityScore {
            let lhsPixels = Int64(lhs.snapshot.pixelWidth) * Int64(lhs.snapshot.pixelHeight)
            let rhsPixels = Int64(rhs.snapshot.pixelWidth) * Int64(rhs.snapshot.pixelHeight)

            if lhsPixels == rhsPixels {
                return comparisonDate(for: lhs.snapshot) < comparisonDate(for: rhs.snapshot)
            }

            return lhsPixels < rhsPixels
        }

        return lhs.qualityScore < rhs.qualityScore
    }
}

// MARK: - SimilarAssetImageSignature

private extension SimilarAssetsService {

    struct SimilarAssetImageSignature {

        let luminanceStandardDeviation: Double
        let edgeMagnitude: Double
        let colorHistogram: [Double]
    }
}

// MARK: - SimilarAssetsAnalysisJob

private extension SimilarAssetsService {

    final class SimilarAssetsAnalysisJob: @unchecked Sendable {

        private let lock = NSLock()
        nonisolated(unsafe) private var continuation: CheckedContinuation<SimilarAssetAnalysisResult, Error>?
        nonisolated(unsafe) private var isCancelled = false
        nonisolated(unsafe) private var isFinished = false

        func setContinuation(_ continuation: CheckedContinuation<SimilarAssetAnalysisResult, Error>) -> Bool {
            lock.lock()

            if isCancelled || isFinished {
                lock.unlock()
                continuation.resume(throwing: CancellationError())
                return false
            }

            self.continuation = continuation
            lock.unlock()
            return true
        }

        nonisolated func cancel() {
            lock.lock()

            guard !isFinished else {
                isCancelled = true
                lock.unlock()
                return
            }

            isCancelled = true
            isFinished = true
            let continuation = self.continuation
            self.continuation = nil
            lock.unlock()

            continuation?.resume(throwing: CancellationError())
        }

        func checkCancellation() throws {
            lock.lock()
            let isCancelled = self.isCancelled
            lock.unlock()

            if isCancelled {
                throw CancellationError()
            }
        }

        func resume(returning result: SimilarAssetAnalysisResult) {
            let continuation = finish()
            continuation?.resume(returning: result)
        }

        func resume(throwing error: Error) {
            let continuation = finish()
            continuation?.resume(throwing: error)
        }

        private func finish() -> CheckedContinuation<SimilarAssetAnalysisResult, Error>? {
            lock.lock()
            defer { lock.unlock() }

            guard !isFinished else { return nil }

            isFinished = true
            let continuation = self.continuation
            self.continuation = nil
            return continuation
        }
    }
}

// MARK: - UnsafeFeaturePrintObservation

private extension SimilarAssetsService {

    final class UnsafeFeaturePrintObservation: @unchecked Sendable {

        nonisolated(unsafe) let value: VNFeaturePrintObservation

        init(_ value: VNFeaturePrintObservation) {
            self.value = value
        }
    }
}

// MARK: - AnalyzedSimilarAssetCandidate

private extension SimilarAssetsService {

    struct AnalyzedSimilarAssetCandidate {

        let snapshot: GalleryAssetSnapshot
        let featurePrint: UnsafeFeaturePrintObservation
        let differenceHash: UInt64
        let qualityScore: Double
        let imageSignature: SimilarAssetImageSignature

        var isGrouped = false
    }
}

// MARK: - SimilarAssetGroupAccumulator

private extension SimilarAssetsService {

    struct SimilarAssetGroupAccumulator {

        private(set) var mergeAnchors: [AnalyzedSimilarAssetCandidate]
        private(set) var members: [SimilarAssetGroupMember]

        init?(candidates: [AnalyzedSimilarAssetCandidate]) {
            guard let anchor = candidates.first else { return nil }

            mergeAnchors = [anchor]
            members = candidates.map(SimilarAssetGroupMember.init)
        }

        mutating func append(_ candidates: [AnalyzedSimilarAssetCandidate]) {
            if let anchor = candidates.first {
                mergeAnchors.append(anchor)
            }

            members.append(contentsOf: candidates.map(SimilarAssetGroupMember.init))
        }
    }
}

// MARK: - SimilarAssetGroupMember

private extension SimilarAssetsService {

    struct SimilarAssetGroupMember {

        let snapshot: GalleryAssetSnapshot
        let qualityScore: Double

        nonisolated init(_ candidate: AnalyzedSimilarAssetCandidate) {
            snapshot = candidate.snapshot
            qualityScore = candidate.qualityScore
        }
    }
}

// MARK: - SimilarAssetsServiceError

private extension SimilarAssetsService {

    enum SimilarAssetsServiceError: Error {
        case missingFeaturePrint
    }
}
