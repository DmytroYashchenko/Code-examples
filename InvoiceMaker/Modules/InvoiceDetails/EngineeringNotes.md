# Invoice Details: Feature Module Excerpt

## Problem / Product context

The invoice list opens a saved invoice so a user can inspect its parties, line items, payment terms, notes, and status. From Details, the user can edit, preview, share, print, duplicate, mark paid/unpaid, or delete the invoice. Sharing, printing, and duplication are premium-gated in the application.

This is a source excerpt from the Invoice Maker iPhone app. It retains the production feature's view, view model, router contract, coordinator, module assembly, and the parent navigation entry. It is not a standalone sample app.

## File roles

| File | Role |
|---|---|
| [MainViewModel.swift](Sources/Main/MainViewModel.swift) | Parent list state and the action that requests invoice details; also supplies the weak duplication-toast presenter contract. |
| [MainRouter.swift](Sources/Main/MainRouter.swift) | Parent navigation contract. |
| [MainCoordinator.swift](Sources/Main/MainCoordinator.swift) | Maps the list's details route to `InvoiceDetailsCoordinator`. |
| [InvoiceDetailsModule.swift](Sources/InvoiceDetails/InvoiceDetailsModule.swift) | Builds the view model, SwiftUI view, and hosting controller. |
| [InvoiceDetailsView.swift](Sources/InvoiceDetails/InvoiceDetailsView.swift) | Renders invoice content and forwards user actions to the view model. |
| [InvoiceDetailsViewModel.swift](Sources/InvoiceDetails/InvoiceDetailsViewModel.swift) | Subscribes to invoice changes, performs data actions, invokes share/print services, and requests navigation. |
| [InvoiceDetailsRouter.swift](Sources/InvoiceDetails/InvoiceDetailsRouter.swift) | Navigation intent contract injected into the view model. |
| [InvoiceDetailsCoordinator.swift](Sources/InvoiceDetails/InvoiceDetailsCoordinator.swift) | Builds the screen and maps preview, edit, paywall, pop, and dismiss routes. |
| [InvoiceDetailsEvent.swift](Sources/InvoiceDetails/InvoiceDetailsEvent.swift), [MainEvent.swift](Sources/Main/MainEvent.swift) | Typed local analytics events used by the feature and parent list. They show event call sites and mappings; processor registration and delivery are outside this excerpt. |
| [ShareInvoiceService.swift](Sources/Services/ShareInvoiceService.swift), [PrintInvoiceService.swift](Sources/Services/PrintInvoiceService.swift) | Render and hand PDF data to the iOS share sheet or print UI. |
| [PremiumGate.swift](Sources/SupportingContracts/PremiumGate.swift) | The original `performIfPremium` helper extracted from a larger purchase-manager source file. The rest of that file, including credentials, is intentionally excluded. |

## Recommended reading order

1. Read `MainViewModel.openInvoiceDetails(for:)` to see how the list passes the selected invoice and itself as a toast presenter.
2. Follow `MainCoordinator.openInvoiceDetails` into `InvoiceDetailsCoordinator` and its `.invoiceDetails` route.
3. Read `InvoiceDetailsModule.build()` and then the view/view-model pair.
4. Follow `shareTapped()` through the premium gate, paywall callback, share service, and `InvoiceRenderingService` in [PDF Invoice Rendering](../../ServicesAndAlgorithms/PDFInvoiceRendering/README.md).
5. Compare the preview, edit, deletion, and duplication paths in `InvoiceDetailsCoordinator` and `InvoiceDetailsViewModel`.

## User and navigation scenarios

**Live details update:** the user opens an invoice card → `MainViewModel.openInvoiceDetails(for:)` asks `MainRouter` to open it → `MainCoordinator` creates `InvoiceDetailsCoordinator` → that coordinator builds `InvoiceDetailsModule` and pushes its hosting controller. `InvoiceDetailsViewModel` observes `DatabaseManager.$invoices`, maps updated managed objects to `Invoice` values, and replaces its published invoice when the same ID appears. SwiftUI redraws the details view from the published value.

**Preview route:** the user taps Preview → `InvoiceDetailsViewModel.previewTapped()` calls `InvoiceDetailsRouter.openPreview(input:)` → `InvoiceDetailsCoordinator` starts a `PreviewCoordinator` for the same `InvoiceInput` → the preview coordinator presents its module full-screen. Closing the preview dismisses that child flow. Edit similarly starts the existing `CreateInvoiceCoordinator` with the saved invoice. Duplicate saves through `DatabaseManager`, pops Details, then asks the weak parent presenter to show a toast.

**Premium share:** the user taps Share or Send Invoice → the view model calls `performIfPremium`. The helper refreshes subscription status and invokes either the share action or the router's paywall route. The paywall receives a close handler that resumes sharing when the purchase flow signals success. `ShareInvoiceService` renders a PDF, writes a temporary file, and presents `UIActivityViewController`; this means the system sheet was presented, not that the recipient received the invoice. Print follows the same gate and asks `UIPrintInteractionController` to present its dialog.

## Ownership, lifetime, and error behavior

The module receives its router and `Invoice` explicitly; infrastructure services are resolved through Depin. The `InvoiceDetailsView` observes the module-owned view model. Its `CancelBag` retains the Combine subscription; the sink captures the view model weakly. The coordinator keeps the duplication-toast presenter weakly, avoiding a parent/child retain cycle. `Invoice` is a value wrapper that retains a Core Data object reference, so it is not an independent persistence snapshot and remains subject to Core Data queue rules.

The view model's share/print processing flags are cleared when the service finishes presenting its system UI, not after a recipient action or print completion. Render/write failures do not produce a dedicated error state in this excerpt. The premium helper and service implementations retain the application's asynchronous and queue behavior; review platform/threading behavior on device before presenting this as a validated runtime flow.

## Extraction notes and dependencies

The feature sources are copied from the application with the event enums preserved. `PremiumGate.swift` contains only the original top-level helper from `PurchaseManager.swift`; unrelated purchase implementation and API credentials were not copied. No business algorithm was rewritten.

This excerpt is not buildable alone. It depends on the app's `Invoice`/`InvoiceInput` and related models, Core Data entities/schema, `DatabaseManager`, `AppStorage`, Depin registrations, RevenueCat-backed `PurchaseManager`, event bus and processor registration, paywall/preview/create-invoice destinations, `InvoiceRenderingService`, shared UI styles/icons/assets, and local packages including XCoordinator, Depin, CombineExt, EventKit, SwiftUIExt, UIKitExt, and Core. Only the share/print service call sites are included here; the rendering implementation is shown in the linked service excerpt. The source tree deliberately excludes signing files, app configuration, user/client data, and generated resources.

## Dependencies / verification

Study this as an architecture excerpt. No app build or UI scenario was run for this export. The excerpt does not include the app's models, assets, packages or project configuration; collection-level verification is limited to source syntax and documentation checks. A successful compile alone would not verify Core Data queue confinement, paywall resumption, or modal presentation.
