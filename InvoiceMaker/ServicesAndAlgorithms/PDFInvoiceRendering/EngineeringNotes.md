# PDF Invoice Rendering

## Problem / Product context

Invoice Maker turns a saved invoice or an in-progress invoice builder into PDF data for preview, sharing, and printing. The renderer draws the document directly with UIKit/Core Graphics and `UIGraphicsPDFRenderer`; it does not depend on a web view, server, or HTML template.

## Implementation and reading order

1. Start at [InvoiceRenderingService.swift](Sources/InvoiceRenderingService.swift): it selects a renderer from the invoice style.
2. Read [CommonInvoiceRenderer.swift](Sources/CommonInvoiceRenderer.swift): it creates US Letter page metrics, a currency formatter, and theme colors.
3. Follow [CommonPDFRenderer.swift](Sources/CommonPDFRenderer.swift): it composes invoice sections, measures text, draws the table and payment details, and returns PDF bytes.
4. Read [InvoicePageMetrics.swift](Sources/Models/InvoicePageMetrics.swift), [InvoiceInput.swift](Sources/Models/InvoiceInput.swift), and [InvoiceColorizer.swift](Sources/Styles/InvoiceColorizer.swift) for the renderer's contracts.
5. Check [InvoiceStyle.swift](Sources/Styles/InvoiceStyle.swift), [InvoiceSample.swift](Sources/Styles/InvoiceSample.swift), and [InvoiceClassicTheme.swift](Sources/Styles/Themes/InvoiceClassicTheme.swift) for persisted style selection and the six palettes.
6. [QRCodeGenerator.swift](Sources/Utilities/QRCodeGenerator.swift) is the Core Image path used for PayPal QR output.

The feature excerpt's [share](../../Modules/InvoiceDetails/Sources/Services/ShareInvoiceService.swift) and [print](../../Modules/InvoiceDetails/Sources/Services/PrintInvoiceService.swift) services show two consumers of the generated `Data`.

## Engineering decisions and limits

The renderer first executes the drawing actions against an empty PDF context to determine the required height, then creates a second renderer sized to at least one US Letter page and draws the content again. This keeps long invoices on one dynamically tall page and reuses the same layout code for measurement and drawing. There are no page breaks or repeated table headers; long pages may be scaled by viewers or printers. QR/signature drawing work is also repeated during both passes.

This is a synchronous rendering API with a non-throwing return type. Measurement and drawing are coupled, which keeps the layout path in one place but makes layout changes dependent on checking both passes. The renderer does not report recoverable layout/render errors. The main preview calls it from a MainActor task; the share and print services currently call it from a global queue while invoice values retain managed-object references. That queue/Core Data interaction is an application risk, not a performance result established by this excerpt.

The current output is a single growing page with a US Letter width. The renderer does not paginate. Known omissions include the business contact person's name and the work-item unit; PDF copy is only partly localized. This export preserves those behaviors rather than silently correcting them. Theme IDs include reflected type names, so renaming the theme type can affect stored style lookup.

## Extraction notes

The renderer, style/theme files, page metrics, input protocol, and QR generator are direct source copies. `CommonPDFRenderer.swift` is included in full, including its secondary `PDFInvoicePreview` wrapper; the production preview primarily uses a separate `PDFPresentableView`. No algorithm was adapted and no new placeholder implementation was introduced.

The excerpt does not include the `Invoice`, `InvoiceBuilder`, `InvoiceTotals`, `Business`, `Client`, `WorkItem`, `Currency`, or payment-method implementations. `InvoiceInput` and `InvoiceColorizer` define part of the boundary, but the project-specific models are required to compile. The theme file uses the app's `UIColor(hex:)` helper from UIKitExt. Fonts, images/signatures, app string catalog, Core Data schema, XcodeGen project, and local packages are not included.

## Dependencies / verification

This is an iOS source excerpt, not a runnable or buildable package. It uses UIKit, Core Graphics, Core Image, PDFKit, SwiftUI, Foundation, app model types, and local UIKit extensions. No build, PDF render, visual inspection, or print test was run for this export. Before using it as runtime evidence, validate short and long invoices, multiline text, QR/signature sizing, Unicode/localized copy, and print scaling on supported iOS versions.
