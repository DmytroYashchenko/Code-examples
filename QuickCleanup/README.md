# QuickCleanup

Selected implementations from an iOS photo-library cleanup project. These examples cover a video compression feature, a custom similarity-analysis pipeline and grouping based on native burst metadata.

## Examples

| Example | Focus | Form |
| --- | --- | --- |
| [Video Compression](Modules/VideoCompression/README.md) | Two screen modules, routing, streaming progress, cancellation and Photos/cache coordination | Feature flow with processing service |
| [Similar Image Analysis](ServicesAndAlgorithms/SimilarImageAnalysis/README.md) | Vision features, difference hashes, structural checks, candidate grouping and quality ranking | Service excerpt |
| [Native Burst Grouping](ServicesAndAlgorithms/NativeBurstGrouping/README.md) | Group eligibility, representative selection and deterministic ordering | Buildable Swift Package with tests |

Start with Video Compression to inspect architecture. Follow with Similar Image Analysis for a larger algorithm, or Native Burst Grouping for a small isolated example you can execute without photo-library access.

## Context

The source project uses SwiftUI, modular MVVM+C, PhotoKit, AVFoundation, Vision, Core Data and dependency injection. Its Swift language mode and default MainActor isolation matter when reading the concurrency code; the package manifest preserves that context.

These are excerpts, not the full app. PhotoKit permissions, persistence and UI resources belong to the host. Each example describes its boundaries and tradeoffs. No release status, benchmark, accuracy score or compression-ratio guarantee is implied.
