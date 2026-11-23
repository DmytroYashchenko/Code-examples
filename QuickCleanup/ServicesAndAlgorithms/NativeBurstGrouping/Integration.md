# Host integration excerpt

This complete original DatabaseManager method shows the actual caller. It is not compiled by this export. The host owns Core Data contexts, persistence helpers, deleted-id tracking and readiness.

```swift
    func refreshBurstPhotos(
        using assets: [GalleryAssetSnapshot],
        lastLibrarySyncAt: Date,
        in context: NSManagedObjectContext
    ) async throws {
        let hasCachedPreparation = await MainActor.run {
            gallerySummary?.lastBurstPhotosPreparationAt != nil
        }

        await MainActor.run {
            self.galleryFeaturePreparationStates.burstPhotos = hasCachedPreparation ? .refreshing : .loading
        }

        let result = try await burstPhotosService.prepareBurstPhotos(from: assets)
        try Task.checkCancellation()

        let deletedIdentifiers = await deletedAssetIdentifiersStore.currentIdentifiers()

        try await context.performChangesAsync {
            self.deleteAssets(
                withLocalIdentifiers: deletedIdentifiers,
                in: context
            )
            self.replaceBurstGroups(
                with: result.groups,
                excludingLocalIdentifiers: deletedIdentifiers,
                preparedAt: result.preparedAt,
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
            self.galleryFeaturePreparationStates.burstPhotos = .ready
        }
    }
```
