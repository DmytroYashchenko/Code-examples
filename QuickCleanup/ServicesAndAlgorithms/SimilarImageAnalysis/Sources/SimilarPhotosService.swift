import Depin
import Foundation

struct SimilarPhotosFlowInput: Sendable {

    let totalItemCount: Int
    let totalBytes: Int64
    let dateRange: ClosedRange<Date>?
    let groups: [SimilarPhotoGroupPayload]
}

struct SimilarPhotoGroupPayload: Sendable, Identifiable {

    let id: UUID
    let totalItemCount: Int
    let totalBytes: Int64
    let bestAssetLocalIdentifier: String?
    let items: [SimilarPhotoItemPayload]
}

struct SimilarPhotoItemPayload: Sendable, Identifiable {

    let id: String
    let localIdentifier: String
    let creationDate: Date?
    let sizeBytes: Int64
    let pixelWidth: Int32
    let pixelHeight: Int32
    let isBest: Bool
}

struct SimilarPhotoAnalysisResult: Sendable {

    let analyzedAt: Date
    let groups: [SimilarPhotoGroupResult]
}

struct SimilarPhotoGroupResult: Sendable {

    let assetLocalIdentifiers: [String]
    let assetQualityScores: [String: Double]
    let bestAssetLocalIdentifier: String
    let totalBytes: Int64
    let newestAssetDate: Date?
}

final class SimilarPhotosService {

    @Injected private var similarAssetsService: SimilarAssetsService

    nonisolated static func isEligibleForAnalysis(_ asset: GalleryAssetSnapshot) -> Bool {
        asset.mediaTypeRaw == 1
        && !asset.isScreenshot
        && !asset.isLivePhoto
        && !asset.isBurstPhoto
        && !asset.isVideo
    }

    func analyzeSimilarPhotos(
        from assets: [GalleryAssetSnapshot]
    ) async throws -> SimilarPhotoAnalysisResult {
        let result = try await similarAssetsService.analyzeSimilarAssets(
            from: assets,
            analysisName: "Similar Photos",
            eligibilityFilter: Self.isEligibleForAnalysis
        )

        return SimilarPhotoAnalysisResult(
            analyzedAt: result.analyzedAt,
            groups: result.groups.map {
                SimilarPhotoGroupResult(
                    assetLocalIdentifiers: $0.assetLocalIdentifiers,
                    assetQualityScores: $0.assetQualityScores,
                    bestAssetLocalIdentifier: $0.bestAssetLocalIdentifier,
                    totalBytes: $0.totalBytes,
                    newestAssetDate: $0.newestAssetDate
                )
            }
        )
    }
}
