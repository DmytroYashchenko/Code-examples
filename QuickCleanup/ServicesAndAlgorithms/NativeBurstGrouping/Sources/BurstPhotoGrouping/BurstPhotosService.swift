import Foundation
@preconcurrency import Photos

struct BurstPhotosFlowInput: Sendable {

    let totalItemCount: Int
    let totalBytes: Int64
    let dateRange: ClosedRange<Date>?
    let groups: [BurstPhotosGroupPayload]
}

struct BurstPhotosGroupPayload: Sendable, Identifiable {

    let id: UUID
    let totalItemCount: Int
    let totalBytes: Int64
    let bestAssetLocalIdentifier: String?
    let items: [BurstPhotosItemPayload]
}

struct BurstPhotosItemPayload: Sendable, Identifiable {

    let id: String
    let localIdentifier: String
    let creationDate: Date?
    let sizeBytes: Int64
    let pixelWidth: Int32
    let pixelHeight: Int32
    let isBest: Bool
}

struct BurstPhotosPreparationResult: Sendable {

    let preparedAt: Date
    let groups: [BurstPhotosGroupResult]
}

struct BurstPhotosGroupResult: Sendable {

    let burstIdentifier: String
    let assetLocalIdentifiers: [String]
    let bestAssetLocalIdentifier: String
    let totalBytes: Int64
    let newestAssetDate: Date?
}

final class BurstPhotosService {

    nonisolated static func isBurstPhoto(_ asset: GalleryAssetSnapshot) -> Bool {
        asset.isBurstPhoto && asset.burstIdentifier != nil
    }

    @concurrent
    func prepareBurstPhotos(from assets: [GalleryAssetSnapshot]) async throws -> BurstPhotosPreparationResult {
        try Task.checkCancellation()

        let groups = Dictionary(grouping: assets.filter(Self.isBurstPhoto)) { asset in
            asset.burstIdentifier ?? ""
        }
        .compactMap { burstIdentifier, assets in
            makeGroupResult(
                burstIdentifier: burstIdentifier,
                assets: assets
            )
        }
        .sorted { lhs, rhs in
            let lhsDate = lhs.newestAssetDate ?? .distantPast
            let rhsDate = rhs.newestAssetDate ?? .distantPast

            if lhsDate == rhsDate {
                return lhs.burstIdentifier < rhs.burstIdentifier
            }

            return lhsDate > rhsDate
        }

        return BurstPhotosPreparationResult(
            preparedAt: .now,
            groups: groups
        )
    }
}

// MARK: - Private

private extension BurstPhotosService {

    nonisolated func makeGroupResult(
        burstIdentifier: String,
        assets: [GalleryAssetSnapshot]
    ) -> BurstPhotosGroupResult? {
        let orderedAssets = assets.sorted { lhs, rhs in
            let lhsDate = comparisonDate(for: lhs)
            let rhsDate = comparisonDate(for: rhs)

            if lhsDate == rhsDate {
                return lhs.localIdentifier < rhs.localIdentifier
            }

            return lhsDate > rhsDate
        }

        guard
            orderedAssets.count > 1,
            orderedAssets.contains(where: \.representsBurst),
            let firstAsset = orderedAssets.first
        else {
            return nil
        }

        let bestAsset = orderedAssets.max { lhs, rhs in
            isLeftAssetWorse(lhs, than: rhs)
        } ?? firstAsset

        return BurstPhotosGroupResult(
            burstIdentifier: burstIdentifier,
            assetLocalIdentifiers: orderedAssets.map(\.localIdentifier),
            bestAssetLocalIdentifier: bestAsset.localIdentifier,
            totalBytes: orderedAssets.reduce(into: Int64.zero) { totalBytes, asset in
                totalBytes += asset.sizeBytes
            },
            newestAssetDate: orderedAssets.first.map { comparisonDate(for: $0) }
        )
    }

    nonisolated func isLeftAssetWorse(
        _ lhs: GalleryAssetSnapshot,
        than rhs: GalleryAssetSnapshot
    ) -> Bool {
        if lhs.representsBurst != rhs.representsBurst {
            return !lhs.representsBurst
        }

        let lhsSelectionPriority = selectionPriority(for: lhs)
        let rhsSelectionPriority = selectionPriority(for: rhs)

        if lhsSelectionPriority != rhsSelectionPriority {
            return lhsSelectionPriority < rhsSelectionPriority
        }

        let lhsPixelCount = Int64(lhs.pixelWidth) * Int64(lhs.pixelHeight)
        let rhsPixelCount = Int64(rhs.pixelWidth) * Int64(rhs.pixelHeight)

        if lhsPixelCount != rhsPixelCount {
            return lhsPixelCount < rhsPixelCount
        }

        let lhsDate = comparisonDate(for: lhs)
        let rhsDate = comparisonDate(for: rhs)

        if lhsDate != rhsDate {
            return lhsDate < rhsDate
        }

        return lhs.localIdentifier > rhs.localIdentifier
    }

    nonisolated func selectionPriority(for asset: GalleryAssetSnapshot) -> Int {
        let selectionTypes = PHAssetBurstSelectionType(rawValue: UInt(asset.burstSelectionTypesRaw))

        if selectionTypes.contains(.userPick) {
            return 2
        }

        if selectionTypes.contains(.autoPick) {
            return 1
        }

        return .zero
    }

    nonisolated func comparisonDate(for asset: GalleryAssetSnapshot) -> Date {
        asset.creationDate ?? asset.modificationDate ?? .distantPast
    }
}
