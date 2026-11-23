# Similar Image Analysis — Service Excerpt

## Problem / Product context

A cleanup app needs groups of visually similar photographs and a suggested keeper. Scanning metadata alone cannot decide visual similarity. This service consumes the shared gallery scan's snapshots, performs local image analysis, and returns identifiers, quality scores and byte totals for the host cache.

## Implementation and reading path

1. [GalleryAssetSnapshot.swift](Sources/GalleryAssetSnapshot.swift): complete metadata value passed in from the scanner.
2. [SimilarPhotosService.swift](Sources/SimilarPhotosService.swift): real caller/facade; excludes screenshots, Live Photos, bursts and videos and maps generic results into feature results.
3. [SimilarAssetsService.swift](Sources/SimilarAssetsService.swift): begin at `analyzeSimilarAssets`, then `performSimilarAssetsAnalysis`, `makeGroups`, `isVisualMatch`, `qualityScore`, and the private job/accumulator types.
4. [AnalysisMetricsTracker.swift](Sources/AnalysisMetricsTracker.swift): original DEBUG-only elapsed/footprint diagnostics, not a published benchmark.
5. [Integration.md](Integration.md): complete host caller that saves results, filters deletion-session identifiers and publishes readiness.

The algorithm sorts eligible metadata newest first and fetches matching PHAssets. It requests local thumbnails synchronously on its dedicated serial analysis queue, creates Vision feature prints, a 64-bit difference hash, grayscale statistics and RGB histograms. An initial anchor compares up to 24 subsequent decoded candidates subject to date, orientation, aspect-ratio and dimension checks. Feature distance, hash distance and strong structural-mismatch checks all participate in the match decision.

The candidate window advances one item at a time. New candidate groups may merge into a previous accumulator through compatible merge anchors. Final results contain metadata/quality scores; the “best” item is a heuristic ranking using sharpness, exposure and resolution, with pixel/date tie breakers.

## Engineering decisions and limits

- The decoder/comparison window holds at most 25 analyzed candidates. **Total algorithm memory is not bounded to 25 images/features**: the metadata/PHAsset index scales with input, and group merge anchors retain feature observations. Group lookup and accumulated-anchor matching can grow beyond the local window's cost. This is not a claim of globally linear runtime.
- Thumbnails use `isNetworkAccessAllowed = false`. Assets without locally obtainable thumbnails are skipped; completeness for an iCloud-only library is not guaranteed. PhotoKit callback error details are not promoted into per-item results.
- Matching is heuristic. The ten-minute window, nearest-neighbor cap and thresholds trade recall against work; they can miss matching images far apart in order or time. Merged groups need not be pairwise equivalent. The Vision request revision is not pinned, and no labeled accuracy corpus or threshold calibration is supplied.
- The local initial-pair check includes dimension similarity; the merge-anchor check has a different, weaker gate. A reader should inspect both instead of assuming identical acceptance rules.
- Equal dates/scores/pixel counts lack a final identifier tie breaker in some sort/ranking paths. Fully deterministic results across reordered equal inputs are not guaranteed.
- Cancellation bridges Swift tasks to a lock-guarded continuation. It handles cancellation before registration and prevents double resume. Underlying synchronous thumbnail/Vision work is checked between steps rather than forcibly interrupted, so cancellation latency is not bounded.
- Existing `@unchecked Sendable` wrappers cross framework boundaries. Serial processing is the intended confinement; parsing alone does not verify strict-concurrency correctness under a different isolation configuration.

## Extraction notes

The full algorithm, helper types, snapshot, original facade and DEBUG metrics implementation are retained. The internal queue label is replaced with a demonstration reverse-domain value. No thresholds, grouping logic, ranking weights or cancellation behavior were changed. Scanner, persistence, similar-photo screens and actual media are omitted. No SDK wrapper is represented as the algorithm: the image signatures, filtering, candidate management, grouping and ranking are visible in the source.

## Dependencies / Verification

Requires an Apple iOS host with Foundation, UIKit/CoreGraphics, PhotoKit and Vision. The original facade additionally requires the omitted internal Depin/Swinject integration. Metrics use Darwin task-memory APIs. The host supplies Photos authorization, a metadata scan and persistence; the integration method is documentation only. There are no fake dependencies or sample media assets.

This is an excerpt, not a runnable package. Source syntax was parsed; image analysis, PhotoKit authorization, accuracy, cancellation races and performance were not executed or measured. The separate [burst package](../NativeBurstGrouping/README.md) provides isolated tests for a different algorithm and does not validate this one.
