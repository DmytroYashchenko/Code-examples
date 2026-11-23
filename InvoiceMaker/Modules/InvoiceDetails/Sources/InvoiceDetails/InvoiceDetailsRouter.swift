@MainActor protocol InvoiceDetailsRouter {

    func openPreview(input: InvoiceInput)
    func openEditInvoice(invoice: Invoice)
    func openPaywall(referrer: PaywallEvent.Referrer, closeHandler: @escaping () -> Void)
    func closeInvoiceDetails()
    func closeInvoiceDetailsOnDuplication()
}
