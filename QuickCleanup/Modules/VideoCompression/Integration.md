# Host integration excerpts

These complete original methods are reading context, not build targets. Core Data helpers and the host model are omitted.

## Insert the compressed asset into the cache

```swift
    func applyInsertedGalleryAsset(
        localIdentifier: String,
        sizeBytes: Int64
    ) async throws {
        guard let snapshot = try await galleryService.assetSnapshot(
            withLocalIdentifier: localIdentifier,
            sizeBytes: sizeBytes
        ) else {
            throw DatabaseManagerError.galleryAssetNotFound
        }

        let backgroundContext = coreDataStack.makeBackgroundContext()
        let insertedAt = Date()
        let insertedSwipePhotos = try await swipePhotosService.prepareSwipePhotos(
            from: [snapshot]
        )

        try await backgroundContext.performChangesAsync {
            self.upsertAssets(
                [snapshot],
                scannedAt: insertedAt,
                in: backgroundContext
            )
            self.attachSwipePhotosAssets(
                from: insertedSwipePhotos.months,
                updatedAt: insertedAt,
                in: backgroundContext
            )
            self.recalculateGallerySummary(
                lastLibrarySyncAt: insertedAt,
                in: backgroundContext
            )
        }
    }
```

## Apply deletion after Photos confirms it

```swift
    func applyDeletedAssets(localIdentifiers: [String]) async throws {
        guard !localIdentifiers.isEmpty else { return }

        await deletedAssetIdentifiersStore.insert(localIdentifiers)

        let backgroundContext = coreDataStack.makeBackgroundContext()

        try await backgroundContext.performChangesAsync {
            self.deleteAssets(
                withLocalIdentifiers: Set(localIdentifiers),
                in: backgroundContext
            )
            self.recalculateGallerySummary(
                lastLibrarySyncAt: .now,
                in: backgroundContext
            )
        }
    }
```

