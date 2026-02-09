@MainActor protocol CreateInvoiceRouter {

    func openPreview(input: InvoiceInput)
    func openBusinessesList(selectionHandler: @escaping (Business) -> Void)
    func openClientsList(selectionHandler: @escaping (Client) -> Void)
    func openWorkItemsList(selectionHandler: @escaping (WorkItem) -> Void)
    func openEditWorkItem(item: WorkItem, onRemoveHandler: @escaping (WorkItem) -> Void)
    func openPaymentMethodsList(selectionHandler: @escaping (any PaymentMethod) -> Void)
    func openEditPaymentMethod(paymentMethod: any PaymentMethod)
    func openDiscount(
        _ currentDiscount: DiscountType?,
        selectionHandler: @escaping DiscountViewModel.SelectionHandler
    )
    func openTax(
        _ currentTax: TaxType?,
        selectionHandler: @escaping TaxViewModel.SelectionHandler
    )
    func openStyles(
        input: InvoiceInput,
        selectionHandler: @escaping (InvoiceStyle) -> Void
    )
    func openCurrencies()
    func close()
    func openPaywall(closeHandler: @escaping () -> Void)
}
