# Results Screen — UIKit Module

A results screen that presents a previously obtained math solution: the original problem, its answer, optional solution steps and an optional graph. It supports sharing through the host application. The solving engine itself is outside this excerpt.

## Reading order

1. [SimpleResultsModule](Sources/SimpleResultsModule.swift): create the view controller and view model, pass the solution and parent navigation callback, and connect their ownership.
2. [SimpleResultsViewController](Sources/SimpleResultsViewController.swift) and [XIB](Sources/SimpleResultsViewController.xib): Auto Layout, outlets, dynamic header/step stacks and the view protocol's rendering/input surface.
3. [SimpleResultsViewModel](Sources/SimpleResultsViewModel.swift): bind lifecycle and tap publishers, combine entitlement inputs for state creation, forward analytics and delegate sharing after loading the original image.
4. [SimpleResultsViewStateFactory](Sources/SimpleResultsViewStateFactory.swift): map step-based or text-based solutions into presentation values, select an original-image fallback when needed and insert optional graph content.
5. [Events+SimpleResults](Sources/Events+SimpleResults.swift): typed screen/share events and their analytics mapping.

## What this shows

- UIKit screen assembly with a view protocol separating rendering from orchestration.
- XIB/Auto Layout for the screen shell and programmatic composition of repeated result views.
- Combine input bindings with subscription lifetime management.
- A separate factory for domain-to-presentation mapping, localization and content variants.
- Explicit parent navigation through `onBackButtonTap` and sharing through an injected service.

This module uses a different presentation pattern from the collection's SwiftUI MVVM+C flows. No router or coordinator is included here: the owning flow supplies the back action. `SimpleResultsModule.build()` connects the real view controller and view model rather than introducing demo scaffolding.

## Dependencies and scope

| Boundary | Supplied by the host application |
| --- | --- |
| Screen infrastructure | `BuildableModule`, `BaseViewController`, lifecycle publishers, loading state and subscription storage |
| Packages and extensions | `CombinePlus`, `FoundationPlus`, `Depin`, `SwiftMath`, `SDWebImage` and the retained `XCoordinator` import; their implementations/distributions are not bundled |
| Domain and presentation | `Solution`, `SolvingFlowType`, `SolutionHeaderView`, `SolutionStepView`, graph presentation and the LaTeX processor/event emitter |
| Services | User/freemium providers, network service, results-sharing implementation and dependency registrations |
| Resources and analytics | Localization, fonts, colors, images, publisher/UI extensions and the shared analytics types/pipeline |

The XIB retains its original `MathSolver` target-module reference and named resources. These files are not a standalone target. Restoring imports alone is insufficient to build or display the screen; the omitted host infrastructure and resources are also required.

The view model holds an unowned view reference and assumes the view controller owns it for the screen's lifetime. Header construction has a one-time guard, while the steps container is rebuilt when state is applied; entitlement changes do not demonstrate a complete paywall flow. The factory prepares graph/LaTeX presentation values, and the actual rendering is delegated to omitted components.

All six files are copied unchanged from the existing code sample. Swift syntax and XIB structure can be checked separately, but no application build, screen rendering or runtime behavior is claimed for this excerpt.

For the larger SwiftUI modules, see [Invoice Details](../../../InvoiceMaker/Modules/InvoiceDetails/README.md) and [Video Compression](../../../QuickCleanup/Modules/VideoCompression/README.md). Return to the [collection overview](../../../README.md).
