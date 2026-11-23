# Video Compression — Feature Module Excerpt

## Problem / Product context

A user previews a library video, chooses a compression level, saves a smaller copy to Photos, and decides whether to keep or delete the original. A successful Photos save must also be reflected in the application's Core Data index before the UI presents success.

This excerpt contains the actual screen, view model, assembly and navigation paths, supporting player UI, compression backend and summary screen. It preserves known shortcomings described below. It is **not a runnable or independently buildable application**.

## Implementation and reading path

| Responsibility | Files | What is present |
| --- | --- | --- |
| Composition and input | [VideoCompressionModule.swift](Sources/Modules/VideoCompression/VideoCompressionModule.swift) | Input identifier/size/existing AVPlayer; creates the view model and SwiftUI hosting controller |
| UI | [VideoCompressionView.swift](Sources/Modules/VideoCompression/VideoCompressionView.swift), [progress](Sources/Modules/VideoCompression/VideoCompressionProgressView.swift), [slider](Sources/Modules/VideoCompression/VideoCompressionSlider.swift) | Preparation, in-progress and success views; event forwarding and lifecycle callbacks |
| State and orchestration | [VideoCompressionViewModel.swift](Sources/Modules/VideoCompression/VideoCompressionViewModel.swift), [state](Sources/Modules/VideoCompression/VideoCompressionViewState.swift) | Playback state, task handle, service events, cache insertion and deletion actions |
| Navigation contract | [HomeRouter in HomeCoordinator.swift](Sources/Navigation/HomeCoordinator.swift) | The real subset consumed by these screens; router is defined in the coordinator file in the app |
| Transition coordination | [HomeCoordinator.swift](Sources/Navigation/HomeCoordinator.swift) | Push compression, present summary, pop, and dismiss plus return to root |
| Dependency assembly | [AppAssembly.swift](Sources/Assembly/AppAssembly.swift), [Module.swift](Sources/Support/Module.swift) | Relevant original container registrations and module contract |
| Media processing | [VideoCompressionService.swift](Sources/Services/VideoCompressionService.swift) | Full planning, transcoding, Photos save, callback bridges and cancellation helpers |
| Cross-store deletion | [GalleryDeletionService.swift](Sources/Services/GalleryDeletionService.swift) | Complete ordinary deletion path: Photos confirmation, then cache update |
| Result screen | [summary module](Sources/Modules/CleaningSummary/CleaningSummaryModule.swift), [view model](Sources/Modules/CleaningSummary/CleaningSummaryViewModel.swift), [view](Sources/Modules/CleaningSummary/CleaningSummaryView.swift) | Receives deletion count/net saved bytes, formats display, returns to the root |
| Shared support | [PlayerView.swift](Sources/Support/PlayerView.swift), [StorageTextFormatter.swift](Sources/Support/StorageTextFormatter.swift), [DeviceService.swift](Sources/Support/DeviceService.swift) | Real player bridge, formatting and storage-capacity estimate; smaller UI helpers are included alongside them |

Read the module/input first, then the view's actions and state switch, then `compressTapped()`, `compressVideo()` and `handleCompressionEvent(_:)` in the view model. Follow those into `compressVideo(...)`, `performCompression(...)`, `transcode(...)` and `writeMedia(...)` in the backend. Finish with the navigation file, summary view model, [host call sites](Integration.md), and [dependency boundary](Dependencies.md).

## A real user scenario

1. The slider binds `compressionLevel`. The view model asks `makePlan(...)` for an estimated output size; this is a bitrate-planning estimate, not an actual measured output size.
2. Tapping **Compress** calls `compressTapped()`, pauses playback, publishes `.compressionInProgress`, and starts a stored task.
3. The service requests the original AVAsset, transcodes it with an AVAssetReader/Writer, and streams progress. Video prefers HEVC with an H.264 alternative; audio attempts passthrough before an AAC alternative. Capability checks do not guarantee every format will succeed at runtime.
4. The backend checks the produced file is smaller, saves it to Photos with creation date/location and editable album memberships, and emits `.completed` with identifiers and byte counts. PhotoKit is asked to move the temporary file on success; failure paths attempt to remove it.
5. The view model calls the host's `applyInsertedGalleryAsset(...)`. Only after this succeeds does it publish `.compressionSuccess`. If cache insertion throws, it attempts compensating deletion of the new Photos asset and returns through the error path.

The estimate uses configured ratios of 0.9 through 0.45 and a minimum video bitrate; these are implementation parameters, not observed compression results. Saving into Photos and writing Core Data are separate operations, so compensation is best effort rather than an atomic transaction.

## A real navigation scenario

After compression, **Delete Original Video** calls the view model's deletion operation. If the system confirms deletion and the cache update succeeds, the view model requests `HomeRouter.openCleaningSummary(input:)`. `HomeCoordinator` implements that method by triggering `.cleaningSummary`; `prepareTransition` builds the real summary module and presents it full screen.

The input contains one deleted item and the **net** saved bytes (original minus compressed copy). The summary view forwards **Got it!** to `CleaningSummaryViewModel.gotItTapped()`, which calls `closeCleaningSummaryAndPopToRoot()`. The coordinator triggers `.dismissAndPopToRoot` and returns the existing combined dismiss/root transition. There is no invented coordinator result callback: the input is passed forward, and completion is a routing command. Keeping both copies returns directly to the root. Back during preparation/progress requests cancellation and pops the compression screen.

## Engineering decisions and lifecycle

The view observes its view model. The view model retains the router and the existing player; the coordinator passes itself as the router. Coordinator ownership of view controllers, transition cleanup and any resulting retention depend on XCoordinator, which is deliberately not bundled or claimed as original work.

The view model owns the compression task and AVPlayer periodic-observer token. `onAppear` installs the observer; `onDisappear` removes it and cancels the task. Observer callbacks capture weakly and hop to MainActor. The compression task starts with a weak capture, but awaiting an instance method can retain the view model for that operation. There is no deinit fallback in this view model. No Combine subscriptions are created by this particular view model.

The backend uses a lock-protected cancellation flag and continuation helpers; sample writing is scheduled on a utility serial queue. Audio and video inputs finish through a dispatch group, and a guarded continuation completion prevents multiple resumes. `@unchecked Sendable` and `nonisolated(unsafe)` are existing framework-bridge escape hatches, not compiler proofs of safe ownership. Default MainActor isolation and Swift language mode are part of the host context; this excerpt does not prove every phase executes off the main thread.

## Known limitations

- **Cancellation state and task replacement:** the service catches `CancellationError` and finishes the stream normally. A consumer may therefore exit without resetting `.compressionInProgress`. The view model also clears its handle immediately when requesting cancellation; an older task's deferred cleanup can interfere with a subsequent task. These are preserved review findings, not silently fixed extraction details.
- **Incomplete error presentation:** errors log in DEBUG and reset the screen or leave deletion unchanged; there is no dedicated user-facing error state. System cancellation of deletion returns `.cancelled` and does not route to the summary.
- **Best-effort consistency:** compensating deletion can fail. A Photos deletion can succeed before a cache write fails, leaving a temporary discrepancy. Completion/cancellation handoff deserves device testing.
- **Resource and format coverage:** cancellation is checked while samples are being pumped; prompt interruption while awaiting writer readiness is not demonstrated. Only the first video and audio tracks are used. HDR, multiple audio tracks, codec/container compatibility and edited assets are not comprehensively validated.
- **Summary display:** device capacity is rounded to a known storage size, so its percentage is approximate. Photos' Recently Deleted behavior means the reported bytes are not proof of immediately reclaimed physical storage.

## Extraction notes

Core feature files and the backend algorithm are retained. Unrelated Home routes, DI registrations and deletion variants were trimmed; their retained bodies are original. One internal queue label was anonymized. The summary's fixed “15 min” time-saved marketing row was removed because it was not a measured result. No replacement service implementations, renamed architecture layers, real media or sample customer records were introduced.

## Dependencies / Verification

See [Dependencies.md](Dependencies.md) for each excluded host component and the consequences for compilation. Swift source parsing is checked independently of application compilation. There is no app target here, no device/transcoding/UI run, and no claim of verified minimum-iOS compatibility for this UI excerpt. The source app declares iOS 16.4, while its UI uses newer SDK surfaces; that deployment configuration requires its own integration review.
