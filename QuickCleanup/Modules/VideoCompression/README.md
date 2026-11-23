# Video Compression — Feature Flow

A connected flow from selecting a compression level to transcoding a video, saving the result to Photos and choosing whether to delete the original. The excerpt includes the actual processing service and navigation into the cleanup summary.

## Source organization

```text
Sources/
├── Modules/
│   ├── VideoCompression/   # Module, view, view model, state and screen components
│   └── CleaningSummary/    # Separate result screen: module, view and view model
├── Assembly/              # Relevant dependency registrations
├── Navigation/            # Router contract and coordinator transitions
├── Services/              # Compression and Photos/cache deletion implementations
└── Support/               # Player bridge, UI helpers and formatting
```

`CleaningSummary` is a separate route in this flow. After the original video is deleted, it receives the deleted-item count and net saved bytes. Its completion action dismisses the summary and returns to the root. Keeping both videos skips the summary. Services are grouped at the flow level; screen folders contain presentation and module composition.

## Read the flow

1. [HomeCoordinator / HomeRouter](Sources/Navigation/HomeCoordinator.swift): route contracts and compression/summary transitions.
2. [VideoCompressionModule](Sources/Modules/VideoCompression/VideoCompressionModule.swift): build the view model, view and hosting controller.
3. [VideoCompressionView](Sources/Modules/VideoCompression/VideoCompressionView.swift): render preparation, progress and success states.
4. [VideoCompressionViewModel](Sources/Modules/VideoCompression/VideoCompressionViewModel.swift): orchestrate playback, compression, persistence and routing.
5. [VideoCompressionService](Sources/Services/VideoCompressionService.swift): Photos asset loading, compression planning, reader/writer work and progress events.
6. [GalleryDeletionService](Sources/Services/GalleryDeletionService.swift), [host integration](Integration.md) and [CleaningSummary](Sources/Modules/CleaningSummary/CleaningSummaryViewModel.swift): reconcile the result and complete navigation.

## What this shows

- MainActor presentation state consuming asynchronous progress events.
- Module assembly and a router abstraction implemented by the coordinator.
- AVAssetReader/AVAssetWriter orchestration and callback/cancellation bridges.
- Coordination between Photos and a local cache, including compensating deletion after a cache-insertion failure.

## Scope and tradeoffs

Photos writes and Core Data updates are separate operations; compensation is best effort. The retained implementation has a known cancellation/rapid-restart UI-state edge case, documented in the engineering notes. Errors are logged and reset state rather than being presented as differentiated UI errors. These limitations are preserved from the source, not hidden behind a rewritten demo.

This is a source excerpt, not a standalone app or a validated transcoding library. Host resources, Photos authorization, model/DI infrastructure and device-level media testing are required for integration. See [Dependencies](Dependencies.md) and [Engineering Notes](EngineeringNotes.md) for the full walkthrough and limitations.
