# Native Burst Grouping

A small, independently testable algorithm that turns PhotoKit scanner snapshots into burst groups. It uses native burst identity rather than inferring membership from date proximity or visual similarity.

## Read and run

- [BurstPhotosService](Sources/BurstPhotoGrouping/BurstPhotosService.swift): grouping, eligibility, representative policy and ordering.
- [GalleryAssetSnapshot](Sources/BurstPhotoGrouping/GalleryAssetSnapshot.swift): metadata input.
- [Behavioral tests](Tests/BurstPhotoGroupingTests/BurstPhotosServiceTests.swift): six synthetic scenarios.
- [Host integration](Integration.md): the original persistence caller, outside the package target.

```sh
swift test
```

Run inside this directory with **Swift tools 6.2+** on an Apple platform. The package has no remote dependencies and declares iOS 16.4 / macOS 14 minimums. The macOS test target exercises metadata only: it does not scan, read or mutate a photo library.

## Engineering decisions

Singletons and groups without a native representative are rejected. Representative selection prioritizes native metadata, then user/automatic picks, pixel count, date and identifier. Explicit tie breakers make group and item ordering stable across input permutations.

The host must provide unique identifiers and consistent native metadata. Cancellation is checked at entry; scanner validation, persistence and user overrides belong to the host.

The package preserves the app's Swift 5 language mode and default MainActor isolation. The manifest and tests were added for extraction; the algorithm source is unchanged. See [Engineering Notes](EngineeringNotes.md) for toolchain details, complexity reasoning and the exact test scope.
