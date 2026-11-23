@MainActor protocol MainRouter {

    func openInvoiceDetails(
        invoice: Invoice,
        invoiceDuplicationToastPresenter: InvoiceDuplicationToastPresenter
    )
    func openInvoiceCreation()
    func openPaywall(closeHandler: @escaping () -> Void)
}
