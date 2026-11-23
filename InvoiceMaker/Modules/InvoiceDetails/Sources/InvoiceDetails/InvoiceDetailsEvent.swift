import EventKit

enum InvoiceDetailsEvent: Event {
    case screenShown
    case closeTapped
    case previewTapped
    case deleteInvoiceTapped
    case switchPaidStatusTapped(isPaid: Bool)
    case shareTapped
    case printTapped
    case editTapped
    case duplicateTapped
    case invoicesCount(Int)
}

class InvoiceDetailsEventProcessor: EventProcessor {

    func process(_ event: InvoiceDetailsEvent) {
        switch event {
        case .screenShown:
            send("invoice_details_screen_shown")
        case .closeTapped:
            send("invoice_details_close_tapped")
        case .previewTapped:
            send("invoice_details_preview_tapped")
        case .deleteInvoiceTapped:
            send("invoice_details_delete_invoice_tapped")
        case .switchPaidStatusTapped(let isPaid):
            send("invoice_details_switch_paid_status_tapped", with: ["is_paid": isPaid.description])
        case .shareTapped:
            send("invoice_details_share_tapped")
        case .printTapped:
            send("invoice_details_print_tapped")
        case .editTapped:
            send("invoice_details_edit_tapped")
        case .duplicateTapped:
            send("invoice_details_duplicate_tapped")
        case let .invoicesCount(count):
            set("invoices_count", with: count)
        }
    }
}
