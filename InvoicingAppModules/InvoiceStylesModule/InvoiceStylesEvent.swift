import EventKit

enum InvoiceStylesEvent: Event {
    case screenShown
    case closeTapped
    case sampleSelected(sample: InvoiceSample)
    case themeSelected(theme: InvoiceColorizer)
    case styleApplied(style: InvoiceStyle)
}

class InvoiceStylesEventProcessor: EventProcessor {

    func process(_ event: InvoiceStylesEvent) {
        switch event {
        case .screenShown:
            send("invoice_styles_screen_shown")
        case .closeTapped:
            send("invoice_styles_close_tapped")
        case let .sampleSelected(sample):
            send(
                "invoice_styles_sample_selected",
                with: ["sample": sample.displayName]
            )
        case let .themeSelected(theme):
            send(
                "invoice_styles_theme_selected",
                 with: ["theme": theme.displayName]
            )
        case let .styleApplied(style):
            send(
                "invoice_styles_style_selected",
                 with: [
                    "sample": style.sample.displayName,
                    "theme": style.theme.displayName
                 ]
            )
        }
    }
}
