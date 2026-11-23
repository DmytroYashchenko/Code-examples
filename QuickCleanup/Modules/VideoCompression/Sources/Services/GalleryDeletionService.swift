// Excerpt: the ordinary deletion path used by video compression.
import Depin
import Foundation

final class GalleryDeletionService {

    enum Result: Sendable {

        case deleted
        case cancelled
    }

    @Injected private var galleryService: GalleryService
    @Injected private var databaseManager: DatabaseManager

    func deleteAssets(withLocalIdentifiers localIdentifiers: [String]) async throws -> Result {
        let hasDeletedAssets = try await galleryService.deleteAssets(
            withLocalIdentifiers: localIdentifiers
        )
        guard hasDeletedAssets else { return .cancelled }

        try await databaseManager.applyDeletedAssets(
            localIdentifiers: localIdentifiers
        )

        return .deleted
    }
}
