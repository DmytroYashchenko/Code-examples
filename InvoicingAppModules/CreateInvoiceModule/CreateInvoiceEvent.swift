import EventKit

enum CreateInvoiceEvent: Event {
    case screenShown
    case closeTapped
    case previewTapped
    case issuerTapped
    case clientTapped
    case addWorkItemTapped
    case workItemTapped
    case removeWorkItemTapped
    case addPaymentMethodTapped
    case paymentMethodTapped
    case removePaymentMethodTapped
    case currencyTapped
    case discountTapped
    case taxTapped
    case styleTapped
    case createInvoiceTapped
    case invoiceCreated(invoice: CD_Invoice)
}

class CreateInvoiceEventProcessor: EventProcessor {

    func process(_ event: CreateInvoiceEvent) {
        switch event {
        case .screenShown:
            send("create_invoice_screen_shown")
        case .closeTapped:
            send("create_invoice_close_tapped")
        case .previewTapped:
            send("create_invoice_preview_tapped")
        case .issuerTapped:
            send("create_invoice_issuer_tapped")
        case .clientTapped:
            send("create_invoice_client_tapped")
        case .addWorkItemTapped:
            send("create_invoice_add_work_item_tapped")
        case .workItemTapped:
            send("create_invoice_work_item_tapped")
        case .removeWorkItemTapped:
            send("create_invoice_remove_work_item_tapped")
        case .addPaymentMethodTapped:
            send("create_invoice_add_payment_method_tapped")
        case .paymentMethodTapped:
            send("create_invoice_payment_method_tapped")
        case .removePaymentMethodTapped:
            send("create_invoice_remove_payment_method_tapped")
        case .currencyTapped:
            send("create_invoice_currency_tapped")
        case .discountTapped:
            send("create_invoice_discount_tapped")
        case .taxTapped:
            send("create_invoice_tax_tapped")
        case .styleTapped:
            send("create_invoice_style_tapped")
        case .createInvoiceTapped:
            send("create_invoice_create_invoice_tapped")
        case let .invoiceCreated(invoice):
            send(
                "invoice_created",
                with: [
                    "has_number": invoice.number.nonNilNonEmpty,
                    "has_issuer": invoice.issuer != nil,
                    "has_recipient": invoice.recipient != nil,
                    "has_notes": invoice.notes.nonNilNonEmpty,
                    "due_date": invoice.dueDate.analyticsValue,
                    "work_items_count": invoice.workItems.count,
                    "currency": invoice.currency.code
                ]
                    .addIfPresent(
                        invoice.paymentMethods.map(\.paymentMethod).map(\.renderingTitle).nilIfEmpty,
                        for: "payment_methods"
                    )
                    .addIfPresent(invoice.discount?.analyticsValue, for: "discount")
                    .addIfPresent(invoice.tax?.analyticsValue, for: "tax")
            )
        }
    }
}
