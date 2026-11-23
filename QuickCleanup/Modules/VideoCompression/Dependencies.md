# Dependency and resource boundary

The following are explicit boundaries of a source excerpt, not runnable stubs. The partial assembly resolves concrete host classes; it does not turn the excerpt into an application.

| Dependency | Contract used here | Included / omitted |
| --- | --- | --- |
| VideoCompressionService | Planning, compression stream, delete compressed asset | Full implementation included, including event/result/configuration types and private callback bridges |
| GalleryDeletionService | `deleteAssets(withLocalIdentifiers:) async throws -> Result` | Complete ordinary deletion implementation and result enum included; other feature variants omitted |
| DatabaseManager | `applyInsertedGalleryAsset(localIdentifier:sizeBytes:) async throws`; `applyDeletedAssets(localIdentifiers:) async throws` | Original method bodies in [Integration.md](Integration.md); CoreDataStack, entities, model versions, upsert/summary helpers, change-save helpers, SwipePhotosService and FRC wiring remain host dependencies |
| GalleryService | `deleteAssets(withLocalIdentifiers:) async throws -> Bool`; `assetSnapshot(withLocalIdentifier:sizeBytes:) async throws -> GalleryAssetSnapshot?` | Host PhotoKit scan/deletion implementation omitted; false means system deletion was cancelled. Snapshot production is outside this module |
| DeviceService | `normalizedStorageSizeGB() -> Int?` | Included original implementation |
| HomeModule | `HomeModule(router: HomeRouter).build() -> UIViewController` | Omitted original host root. The real coordinator's initial `.home` still uses this boundary |
| RateUsService / RateUsReferrer | `@MainActor static func requestReview(referrer: RateUsReferrer)`; `.videos` input | Summary keeps its original one-request-per-view-model guard. StoreKit/EventKit analytics bridge and referrer enum omitted; not replaced by a no-op |
| Depin | `@Injected`, `Assembly`, `Container`, registrations and container scope | Internal DI package omitted. It integrates Swinject/SwinjectAutoregistration and must be supplied by an integrating host |
| SwiftUIExt | `HostingController(rootView:)` | Internal SwiftUI/UIKit hosting and utility package omitted |
| UIKitExt | AttributedString typography/color helpers used by the success title | Internal helper package omitted; this is not a platform API |
| XCoordinator | NavigationCoordinator, Route, NavigationTransition, trigger and composition | External navigation library omitted; use its upstream distribution and license if integrating |
| Lottie | LottieView and playback modifiers on the summary | External runtime and the app's `LottieView.make` integration omitted; animation artwork omitted |

## Excluded UI resources and helpers

The included sources reference the app's color and font tokens (`bgPrimary`, `bgSecondary`, `bgStroke`, `fgPrimary`, `fgSecondary`, `accent100`, `accent500`, `accentBg`, body/title/caption styles), UIKit equivalents used in attributed text, and generated image-resource accessors. The icon assets `icDoubleChevronRight`, `icTowardsArrows`, `icCircledTrashBin` and `icCircledArrows` are not included. The Lottie `congratulations` animation/type and its loading helper are not included. The localization catalog, localized format variants, bundled fonts, asset catalogs and design-token extensions are not included.

Shared player, back button, loading view, primary button style, icon wrapper, formatter and device helper implementations are included. They still require the omitted tokens/resources above. No account configuration, signing files, analytics credentials, production service identifiers, actual Photos identifiers or media assets are required for reading this excerpt, and none are bundled.

## Compilation consequences

The sources are intentionally not one buildable target: unresolved host classes, internal imports, assets, resource accessors and extension APIs remain. Restoring only package imports is insufficient. Integration also requires the host's DI bootstrap and MainActor defaults, navigation owner, Photos permissions, persistence model and resource graph. Swift parsing checks syntax only; it does not resolve these dependencies, validate actor isolation or run the user flow.
