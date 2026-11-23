# Invoice Maker

Selected source from an iPhone app for creating and managing invoices, clients, businesses and work items, producing PDFs, and sharing or printing documents.

[App Store: Invoice Maker — Easy Receipts](https://apps.apple.com/us/app/invoice-maker-easy-receipts/id6748883626)

## Examples

| Example | Focus | Where to start |
| --- | --- | --- |
| [Invoice Details](Modules/InvoiceDetails/README.md) | A connected SwiftUI feature: published state, navigation contracts, coordinators, premium-gated actions and parent callbacks | `MainViewModel.openInvoiceDetails(for:)` |
| [PDF Invoice Rendering](ServicesAndAlgorithms/PDFInvoiceRendering/README.md) | A native document renderer with shared measurement/drawing logic, dynamic page height and color themes | `InvoiceRenderingService.renderInvoice(from:)` |

The module and renderer are linked: sharing and printing consume the renderer's PDF output. Together they show the UI/service boundary as well as the platform-specific implementation.

## Context

SwiftUI views use MVVM with module assembly and XCoordinator navigation. Services use dependency injection; app models wrap Core Data objects. The selected files are source excerpts, with host models, resources, package dependencies and runtime limitations documented at the example level.
