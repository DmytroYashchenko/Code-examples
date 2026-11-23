# Similar Image Analysis

A custom PhotoKit/Vision pipeline that groups visually similar photos and ranks a suggested keeper. The source includes image signatures, candidate selection, structural checks, group merging and quality scoring.

## Reading order

1. [GalleryAssetSnapshot](Sources/GalleryAssetSnapshot.swift): scanner metadata input.
2. [SimilarPhotosService](Sources/SimilarPhotosService.swift): the feature-specific facade and eligibility filtering.
3. [SimilarAssetsService](Sources/SimilarAssetsService.swift): start at `analyzeSimilarAssets`, then follow analysis, grouping, matching and scoring.
4. [AnalysisMetricsTracker](Sources/AnalysisMetricsTracker.swift): DEBUG diagnostics.
5. [Integration](Integration.md): the persistence caller and deletion-session boundary.

## Engineering decisions

The service combines Vision feature prints, a difference hash, grayscale statistics and RGB histograms. Sorted candidates pass through time/geometry gates, a local comparison window and merge-anchor checks. Sharpness, exposure and resolution contribute to a heuristic quality ranking.

The local decode window limits immediate comparison work; it is **not** a bound on total memory or overall runtime. Metadata and retained merge anchors scale with the input. Matching thresholds trade recall against work, iCloud-only images may be skipped, and synchronous framework work is cooperatively cancelled between steps rather than forcibly interrupted.

This is a service excerpt, not a standalone package. It requires the host scanner, PhotoKit authorization, DI and persistence; no media dataset or accuracy benchmark is bundled. See [Engineering Notes](EngineeringNotes.md) for algorithm stages, ordering/recall limitations and concurrency assumptions. For an isolated executable algorithm, see [Native Burst Grouping](../NativeBurstGrouping/README.md).
