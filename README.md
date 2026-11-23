# Swift & iOS Engineering — Code Examples

Selected work from **Invoice Maker** and **QuickCleanup**, plus an additional **MathSolver** UIKit module, organized for technical review. The main examples cover connected SwiftUI feature flows, navigation and state management, media processing, document rendering, and native photo metadata.

## Choose a starting point

| What you want to review | Example | Format |
| --- | --- | --- |
| Feature architecture, navigation and business actions | [Invoice Details](InvoiceMaker/Modules/InvoiceDetails/README.md) | SwiftUI / MVVM+C source excerpt |
| A complete UI-to-media-processing flow | [Video Compression](QuickCleanup/Modules/VideoCompression/README.md) | SwiftUI / AVFoundation source excerpt |
| A custom image-analysis pipeline | [Similar Image Analysis](QuickCleanup/ServicesAndAlgorithms/SimilarImageAnalysis/README.md) | Vision / PhotoKit service excerpt |
| Native PDF layout and rendering | [PDF Invoice Rendering](InvoiceMaker/ServicesAndAlgorithms/PDFInvoiceRendering/README.md) | UIKit / Core Graphics service excerpt |
| A small algorithm you can build and test | [Native Burst Grouping](QuickCleanup/ServicesAndAlgorithms/NativeBurstGrouping/README.md) | Swift Package, six behavioral tests |

For architecture, start with Invoice Details and follow the view model's navigation request through its router, coordinator and module builder. For a compact executable example, start with Native Burst Grouping. Each example has a reading order, dependency boundary and engineering notes.

For UIKit, see the additional [Results Screen](MathSolver/Modules/SimpleResults/README.md): a view controller with XIB/Auto Layout, a Combine-driven view model and a dedicated view-state factory.

## Projects

- [Invoice Maker](InvoiceMaker/README.md): invoice management, PDF generation and native document workflows. [View the published app](https://apps.apple.com/us/app/invoice-maker-easy-receipts/id6748883626).
- [QuickCleanup](QuickCleanup/README.md): photo-library organization, image analysis and video compression.
- [MathSolver — additional UIKit example](MathSolver/README.md): a results-screen module illustrating a different presentation approach.

## Scope and verification

These are selected application implementations, not full application repositories or drop-in libraries. The SwiftUI flows retain their real View/ViewModel/Router/Coordinator composition; the UIKit example retains its view protocol, view model and factory, with parent navigation supplied through a callback. Internal packages, signing configuration, application assets and user data are omitted.

Business logic is preserved from the prepared exports and the existing UIKit sample. One truncated premium-gate helper was restored to match the complete original function; other Swift files are unchanged. Extraction changes, host assumptions and known edge cases are described in the example documentation. There is no claim that a syntax check validates a complete app or its runtime behavior.

The **Native Burst Grouping** package is independently buildable; its [README](QuickCleanup/ServicesAndAlgorithms/NativeBurstGrouping/README.md) describes how to run the tests and their scope. The other examples are for source review and do not include standalone app targets.

— Dmytro Yashchenko
