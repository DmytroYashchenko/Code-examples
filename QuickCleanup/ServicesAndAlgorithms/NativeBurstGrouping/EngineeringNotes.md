# Native Burst Grouping

## Problem / Product context

PhotoKit already knows which photos belong to one burst sequence. This service turns scanner snapshots into valid cleanup groups without inferring burst identity from dates or image similarity. It rejects singleton groups and native leftovers that lack a representative, then chooses an automatic best item and stable display order.

## Implementation and reading path

1. [GalleryAssetSnapshot.swift](Sources/BurstPhotoGrouping/GalleryAssetSnapshot.swift): the complete original metadata value type, extracted from the gallery scanner.
2. [BurstPhotosService.swift](Sources/BurstPhotoGrouping/BurstPhotosService.swift): original payload/result types, eligibility, grouping, ordering and automatic representative selection.
3. [Integration.md](Integration.md): the original DatabaseManager call site and its persistence/deletion-session boundary.
4. [BurstPhotosServiceTests.swift](Tests/BurstPhotoGroupingTests/BurstPhotosServiceTests.swift): synthetic behavioral scenarios; these tests were added for this extraction.
5. [Package.swift](Package.swift): minimal package, preserving Swift language mode 5 and default MainActor isolation from the source app.

The host calls `try await service.prepareBurstPhotos(from: snapshots)`. The implementation groups eligible assets by native burst identifier, requires more than one member and at least one `representsBurst` item, and computes member identifiers, total bytes, newest date and the initial best identifier.

## Engineering decisions

Native representative status has highest priority, followed by user pick, automatic pick, pixel count, date and identifier. Within a group, display order is newest first, then identifier; groups use newest date, then burst identifier. A missing creation date falls back to modification date and then `distantPast`. These tie breakers let shuffled equivalent input produce the same identifiers/order.

The scanner must supply consistent native metadata, include all burst members and use unique local identifiers. The service does not re-fetch assets or validate source consistency. `isBurstPhoto` tests a non-nil identifier rather than rejecting an empty string. It accepts metadata as trusted input; totals assume nonnegative realistic byte counts without overflow. It checks cancellation at entry, not during grouping/sorting. `@concurrent` moves the async operation away from the caller's actor in the original design.

Grouping requires input storage plus sorted groups, with sorting work up to O(n log n). This is source-level complexity reasoning, not a measured benchmark. Persisted user overrides, burst deletion/preservation and Core Data reconciliation belong to the omitted host, not this automatic-choice algorithm.

## Extraction notes

The service file is unchanged. The complete snapshot type was moved into a separate file with a Foundation import. A package manifest and six scenario tests are new extraction infrastructure, not claimed to be shipped product tests. There are no demo replacements, media fixtures or third-party sources. The public package exposes no new API; tests inspect the original internal types through `@testable import`.

## Dependencies / Verification

Requires **Swift tools 6.2+**, iOS **16.4+** or macOS **14+**, and Apple's Foundation/Photos frameworks. The package has no remote dependencies. The macOS target exists to exercise the metadata algorithm; it does not make this an iOS application or request photo-library access.

```sh
swift test
```

The six tests cover rejecting orphans/singletons/unrelated inputs, native representative precedence over a larger user pick, stable ordering after input permutation, modification-date fallback, empty input and already-cancelled work. They use artificial identifiers and metadata and never scan or change Photos.

**Verified:** the package built on Apple Silicon with Apple Swift 6.4.2, and all six tests passed. The original grouping source was unchanged. This environment needed a matching Xcode macOS SDK and explicit developer-framework search paths to locate Swift Testing; no global toolchain settings were changed.

If SwiftPM cannot locate `Testing`, use the selected Xcode developer frameworks explicitly:

```sh
portfolio_developer_dir="$(xcode-select -p)"
portfolio_frameworks="$portfolio_developer_dir/Platforms/MacOSX.platform/Developer/Library/Frameworks"
swift test --enable-swift-testing --disable-xctest \
  -Xswiftc -F -Xswiftc "$portfolio_frameworks" \
  -Xlinker -F -Xlinker "$portfolio_frameworks" \
  -Xlinker -rpath -Xlinker "$portfolio_frameworks"
```

The declared macOS 14 floor accommodates the installed testing framework. iOS 16.4 is the declared library target, not an iOS-device test result. Successful macOS grouping tests do not validate scanning, permission handling, user overrides or deletion behavior.
