import EventKit

enum MainEvent: Event {
    case screenShown
    case invoiceDetailsTapped
    case createInvoiceTapped
    case duplicateTapped
    case markAsPaidTapped
    case markUsUnpaidTapped
    case deleteTapped
    case pickerChanged(value: PickerValue)
    case crownTapped

    enum PickerValue: String {
        case all
        case paid
        case unpaid
    }
}

class MainEventProcessor: EventProcessor {

    func process(_ event: MainEvent) {
        switch event {

        case .screenShown:
            send("main_screen_shown")

        case .invoiceDetailsTapped:
            send("main_screen_invoice_details_tapped")

        case .createInvoiceTapped:
            send("main_screen_create_invoice_tapped")

        case .duplicateTapped:
            send("main_screen_duplicate_tapped")

        case .markAsPaidTapped:
            send("main_screen_mark_as_paid_tapped")

        case .markUsUnpaidTapped:
            send("main_screen_mark_as_unpaid_tapped")

        case .deleteTapped:
            send("main_screen_delete_tapped")

        case let .pickerChanged(value):
            send("main_screen_picker_changed", with: [
                "value": value.rawValue
            ])

        case .crownTapped:
            send("main_screen_crown_tapped")
        }
    }
}
