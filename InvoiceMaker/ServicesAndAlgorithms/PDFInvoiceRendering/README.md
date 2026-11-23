# PDF Invoice Rendering

A native PDF pipeline used by invoice preview, sharing and printing. It draws invoice sections directly with UIKit/Core Graphics rather than an HTML template or server renderer.

## Reading order

1. [InvoiceRenderingService](Sources/InvoiceRenderingService.swift): select the renderer from the invoice style.
2. [CommonInvoiceRenderer](Sources/CommonInvoiceRenderer.swift): configure dimensions, currency formatting and colors.
3. [CommonPDFRenderer](Sources/CommonPDFRenderer.swift): measure and draw parties, work items, totals, payment details, notes and signatures.
4. [InvoiceInput](Sources/Models/InvoiceInput.swift) and [InvoicePageMetrics](Sources/Models/InvoicePageMetrics.swift): input/layout contracts.
5. [InvoiceColorizer](Sources/Styles/InvoiceColorizer.swift) and [InvoiceClassicTheme](Sources/Styles/Themes/InvoiceClassicTheme.swift): the color contract and its palettes.
6. [QRCodeGenerator](Sources/Utilities/QRCodeGenerator.swift): PayPal QR rendering with Core Image.

The three rendering entry points stay directly under `Sources`. `Models` holds input/layout contracts, `Styles` holds style selection and color themes, and `Utilities` holds the QR helper.

## Engineering decisions

The same drawing actions run twice: first to measure required height, then to produce the final PDF. This keeps measurement and drawing in one layout path. The result is a single page with US Letter width and a dynamically growing height; the code does **not** implement pagination or repeated headers.

The renderer is synchronous and depends on host model types. Callers own scheduling and Core Data confinement; model wrappers in the app can retain managed objects. Print scaling, long text and localization need application-level validation. Only the Classic layout and its color themes are included here.

This is a source excerpt, not a runnable package. See [Engineering Notes](EngineeringNotes.md) for the complete extraction boundary, known output omissions and review scenarios, and [Invoice Details](../../Modules/InvoiceDetails/README.md) for the consuming feature.
