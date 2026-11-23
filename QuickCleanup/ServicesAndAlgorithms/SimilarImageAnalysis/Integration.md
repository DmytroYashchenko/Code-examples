# Host integration excerpt

This complete original DatabaseManager method shows the actual caller. It is not compiled by this export. The host owns Core Data contexts, persistence helpers, deleted-id tracking and readiness.

```swift
    func refreshSimilarPhotosAnalysis(
        using assets: [GalleryAssetSnapshot],
        lastLibrarySyncAt: Date,
        in context: NSManagedObjectContext
    ) async throws {
        let hasCachedAnalysis = await MainActor.run {
            gallerySummary?.lastSimilarAnalysisAt != nil
        }

        await MainActor.run {
            self.galleryFeaturePreparationStates.similarPhotos = hasCachedAnalysis ? .refreshing : .loading
        }

        let result = try await similarPhotosService.analyzeSimilarPhotos(from: assets)
        try Task.checkCancellation()

        let deletedIdentifiers = await deletedAssetIdentifiersStore.currentIdentifiers()

        try await context.performChangesAsync {
            self.deleteAssets(
                withLocalIdentifiers: deletedIdentifiers,
                in: context
            )
            self.replaceSimilarGroups(
                with: result.groups,
                excludingLocalIdentifiers: deletedIdentifiers,
                analyzedAt: result.analyzedAt,
                lastLibrarySyncAt: lastLibrarySyncAt,
                in: context
            )
        }

        let latestDeletedIdentifiers = await deletedAssetIdentifiersStore.currentIdentifiers()

        if latestDeletedIdentifiers != deletedIdentifiers {
            try await context.performChangesAsync {
                self.deleteAssets(
                    withLocalIdentifiers: latestDeletedIdentifiers,
                    in: context
                )
                self.recalculateGallerySummary(
                    lastLibrarySyncAt: lastLibrarySyncAt,
                    in: context
                )
            }
        }

        await MainActor.run {
            self.galleryFeaturePreparationStates.similarPhotos = .ready
        }
    }
```
