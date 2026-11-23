import Foundation
import Photos
import Testing
@testable import BurstPhotoGrouping

@MainActor
struct BurstPhotosServiceTests {

    @Test
    func rejectsOrphansSingletonsAndUnrelatedAssets() async throws {
        let assets = [
            makeAsset(identifier: "orphan-1", burst: "orphan"),
            makeAsset(identifier: "orphan-2", burst: "orphan"),
            makeAsset(identifier: "singleton", burst: "single", representsBurst: true),
            makeAsset(identifier: "ordinary", burst: nil, representsBurst: true),
            makeAsset(identifier: "flag-off", burst: "flagged", isBurst: false),
            makeAsset(identifier: "valid-1", burst: "valid", representsBurst: true),
            makeAsset(identifier: "valid-2", burst: "valid")
        ]
        let result = try await BurstPhotosService().prepareBurstPhotos(from: assets)
        #expect(result.groups.map(\.burstIdentifier) == ["valid"])
        #expect(result.groups.first?.assetLocalIdentifiers.count == 2)
    }

    @Test
    func nativeRepresentativeWinsOverLargerUserPick() async throws {
        let assets = [
            makeAsset(identifier: "native", burst: "trip", representsBurst: true, width: 640, height: 480, bytes: 120),
            makeAsset(identifier: "picked", burst: "trip", selection: .userPick, width: 4000, height: 3000, bytes: 900)
        ]
        let result = try await BurstPhotosService().prepareBurstPhotos(from: assets)
        #expect(result.groups.first?.bestAssetLocalIdentifier == "native")
        #expect(result.groups.first?.totalBytes == 1020)
    }

    @Test
    func stableOrderingSurvivesInputPermutation() async throws {
        let assets = [
            makeAsset(identifier: "z-item", burst: "z-group", representsBurst: true),
            makeAsset(identifier: "z-other", burst: "z-group"),
            makeAsset(identifier: "b-item", burst: "a-group", representsBurst: true),
            makeAsset(identifier: "a-item", burst: "a-group")
        ]
        let first = try await BurstPhotosService().prepareBurstPhotos(from: assets)
        let second = try await BurstPhotosService().prepareBurstPhotos(from: assets.reversed())
        #expect(first.groups.map(\.burstIdentifier) == ["a-group", "z-group"])
        #expect(first.groups.map(\.assetLocalIdentifiers) == second.groups.map(\.assetLocalIdentifiers))
        #expect(first.groups.first?.assetLocalIdentifiers == ["a-item", "b-item"])
    }

    @Test
    func missingCreationDateUsesModificationDateForRecency() async throws {
        let assets = [
            makeAsset(identifier: "new", burst: "recent", representsBurst: true, date: nil, modification: Date(timeIntervalSince1970: 300)),
            makeAsset(identifier: "new-other", burst: "recent", date: nil, modification: Date(timeIntervalSince1970: 250)),
            makeAsset(identifier: "old", burst: "older", representsBurst: true, date: Date(timeIntervalSince1970: 100)),
            makeAsset(identifier: "old-other", burst: "older", date: nil)
        ]
        let result = try await BurstPhotosService().prepareBurstPhotos(from: assets)
        #expect(result.groups.map(\.burstIdentifier) == ["recent", "older"])
        #expect(result.groups.first?.newestAssetDate == Date(timeIntervalSince1970: 300))
    }

    @Test
    func emptyInputProducesNoGroups() async throws {
        let result = try await BurstPhotosService().prepareBurstPhotos(from: [])
        #expect(result.groups.isEmpty)
    }

    @Test
    func alreadyCancelledWorkDoesNotProduceAResult() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await BurstPhotosService().prepareBurstPhotos(from: [])
        }
        do {
            _ = try await task.value
            Issue.record("Cancelled work unexpectedly returned a result.")
        } catch is CancellationError {
            // Entry cancellation is the production guarantee exercised here.
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    private func makeAsset(
        identifier: String,
        burst: String?,
        representsBurst: Bool = false,
        isBurst: Bool = true,
        selection: PHAssetBurstSelectionType = [],
        width: Int32 = 1000,
        height: Int32 = 1000,
        bytes: Int64 = 100,
        date: Date? = Date(timeIntervalSince1970: 200),
        modification: Date? = nil
    ) -> GalleryAssetSnapshot {
        GalleryAssetSnapshot(
            localIdentifier: identifier,
            mediaTypeRaw: 1,
            mediaSubtypesRaw: 0,
            creationDate: date,
            modificationDate: modification,
            duration: 0,
            pixelWidth: width,
            pixelHeight: height,
            sizeBytes: bytes,
            isLivePhoto: false,
            isScreenshot: false,
            isBurstPhoto: isBurst,
            burstIdentifier: burst,
            burstSelectionTypesRaw: Int16(selection.rawValue),
            representsBurst: representsBurst,
            isVideo: false
        )
    }
}
