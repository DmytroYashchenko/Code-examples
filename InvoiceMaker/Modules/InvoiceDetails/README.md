# Invoice Details — Feature Module

A saved invoice can be viewed, edited, previewed, shared, printed, duplicated, marked paid/unpaid or deleted. This excerpt connects the parent invoice list to the Details screen and its child flows.

## Read the flow

1. [MainViewModel](Sources/Main/MainViewModel.swift) requests Details through [MainRouter](Sources/Main/MainRouter.swift).
2. [MainCoordinator](Sources/Main/MainCoordinator.swift) creates [InvoiceDetailsCoordinator](Sources/InvoiceDetails/InvoiceDetailsCoordinator.swift).
3. [InvoiceDetailsModule](Sources/InvoiceDetails/InvoiceDetailsModule.swift) assembles the view model, SwiftUI view and hosting controller.
4. [InvoiceDetailsViewModel](Sources/InvoiceDetails/InvoiceDetailsViewModel.swift) subscribes to invoice changes, performs business actions and calls [InvoiceDetailsRouter](Sources/InvoiceDetails/InvoiceDetailsRouter.swift).
5. [InvoiceDetailsView](Sources/InvoiceDetails/InvoiceDetailsView.swift) renders published state and forwards actions.

## What this shows

- Constructor-injected navigation contracts alongside service injection.
- Reactive refresh when an invoice with the same ID changes in the database.
- Premium gating and paywall continuation for share, print and duplicate actions.
- Child coordinators for edit/preview; a weak parent presenter for duplication feedback.
- Native share/print consumers linked to the [PDF renderer](../../ServicesAndAlgorithms/PDFInvoiceRendering/README.md).

```text
Invoice list → Router → Coordinator → Module → View + ViewModel
                                        ViewModel → Services / Router
```

## Scope and tradeoffs

This is an architecture excerpt, not a standalone app. Models/schema, DI bootstrap, shared UI resources and destination modules remain host dependencies. Share/print completion here signals presentation of system UI, not successful delivery to a recipient. The original adapters also have a Core Data queue-confinement risk when rendering off the main queue; that behavior has not been rewritten or device-validated.

See [Engineering Notes](EngineeringNotes.md) for file roles, full user/navigation scenarios, dependencies and the retained implementation's runtime limitations.
