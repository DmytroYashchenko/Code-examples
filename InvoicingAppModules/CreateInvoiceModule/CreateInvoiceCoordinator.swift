import XCoordinator

enum CreateInvoiceRoute: Route {

    case createInvoice
    case editInvoice(invoice: Invoice)
    case previewInvoice(input: InvoiceInput)
    case businessesList(selectionHandler: (Business) -> Void)
    case clientsList(selectionHandler: (Client) -> Void)
    case workItemsList(selectionHandler: (WorkItem) -> Void)
    case editWorkItem(item: WorkItem, onRemoveHandler: (WorkItem) -> Void)
    case paymentMethodsList(selectionHandler: (any PaymentMethod) -> Void)
    case editPaymentMethod(paymentMethod: any PaymentMethod)
    case setDiscount(discount: DiscountType?, selectionHandler: DiscountViewModel.SelectionHandler)
    case setTax(tax: TaxType?, selectionHandler: TaxViewModel.SelectionHandler)
    case setStyle(input: InvoiceInput, selectionHandler: (InvoiceStyle) -> Void)
    case setCurrency
    case dismiss
    case paywall(closeHandler: () -> Void)
}

class CreateInvoiceCoordinator: NavigationCoordinator<CreateInvoiceRoute> {

    init(
        rootViewController: UINavigationController,
        invoice: Invoice? = nil
    ) {
        super.init(rootViewController: rootViewController, initialRoute: nil)

        if let invoice {
            trigger(.editInvoice(invoice: invoice))
        } else {
            trigger(.createInvoice)
        }
    }

    override func prepareTransition(for route: CreateInvoiceRoute) -> NavigationTransition {
        switch route {
        case .createInvoice:
            let module = CreateInvoiceModule(router: self)
            return .present(module.build(), modalPresentationStyle: .fullScreen)

        case let .editInvoice(invoice):
            let module = EditInvoiceModule(
                router: self,
                invoice: invoice
            )
            return .present(module.build(), modalPresentationStyle: .fullScreen)

        case let .previewInvoice(input):
            return .none(
                PreviewCoordinator(
                    rootViewController: rootViewController,
                    input: input
                )
            )

        case let .businessesList(selectionHandler):
            return .none(BusinessesListCoordinator(
                rootViewController: rootViewController,
                onBusinessSelected: selectionHandler
            ))

        case let .clientsList(selectionHandler):
            return .none(ClientsListCoordinator(
                rootViewController: rootViewController,
                onClientSelected: selectionHandler
            ))

        case let .workItemsList(selectionHandler):
            return .none(WorkItemsListCoordinator(
                    rootViewController: rootViewController,
                    onWorkItemSelected: selectionHandler
                ))

        case let .editWorkItem(item, removeHandler):
            return .none(EditWorkItemCoordinator(
                rootViewController: rootViewController,
                workItem: item,
                onRemoveHandler: removeHandler
            ))

        case let .paymentMethodsList(selectionHandler):
            return .none(PaymentMethodsListCoordinator(
                rootViewController: rootViewController,
                onPaymentMethodSelected: selectionHandler
            ))

        case let .editPaymentMethod(paymentMethod):
            return .none(paymentMethod.editModule(rootViewController: rootViewController))

        case let .setDiscount(discount, selectionHandler):
            let module = DiscountModule(
                router: self,
                discount: discount,
                selectionHandler: selectionHandler
            )
            return .present(module.build(), modalPresentationStyle: .overFullScreen)

        case let .setTax(tax, selectionHandler):
            let module = TaxModule(
                router: self,
                tax: tax,
                selectionHandler: selectionHandler
            )
            return .present(module.build(), modalPresentationStyle: .overFullScreen)

        case let .setStyle(input, selectionHandler):
            let module = InvoiceStylesModule(
                router: self,
                input: input,
                onStyleSelected: selectionHandler
            )
            return .present(module.build(), modalPresentationStyle: .overFullScreen)

        case .setCurrency:
            return .none(CurrencyCoordinator(
                rootViewController: rootViewController
            ))

        case .dismiss:
            return .dismiss()

        case let .paywall(closeHandler):
            return .none(PaywallCoordinator(
                rootViewController: rootViewController,
                referrer: .invoicesCreation,
                closeHandler: closeHandler
            ))
        }
    }
}

extension CreateInvoiceCoordinator: CreateInvoiceRouter {

    func openPreview(input: InvoiceInput) {
        trigger(.previewInvoice(input: input))
    }

    func openBusinessesList(selectionHandler: @escaping (Business) -> Void) {
        trigger(.businessesList { [unowned self] in
            selectionHandler($0)
            trigger(.dismiss)
        })
    }

    func openClientsList(selectionHandler: @escaping (Client) -> Void) {
        trigger(.clientsList { [unowned self] in
            selectionHandler($0)
            trigger(.dismiss)
        })
    }

    func openWorkItemsList(selectionHandler: @escaping (WorkItem) -> Void) {
        trigger(.workItemsList { [unowned self] in
            selectionHandler($0)
            trigger(.dismiss)
        })
    }

    func openEditWorkItem(item: WorkItem, onRemoveHandler: @escaping (WorkItem) -> Void) {
        trigger(.editWorkItem(item: item, onRemoveHandler: onRemoveHandler))
    }

    func openPaymentMethodsList(selectionHandler: @escaping (any PaymentMethod) -> Void) {
        trigger(.paymentMethodsList { [unowned self] in
            selectionHandler($0)
            trigger(.dismiss)
        })
    }

    func openEditPaymentMethod(paymentMethod: any PaymentMethod) {
        trigger(.editPaymentMethod(paymentMethod: paymentMethod))
    }

    func openDiscount(
        _ currentDiscount: DiscountType?,
        selectionHandler: @escaping DiscountViewModel.SelectionHandler
    ) {
        trigger(.setDiscount(discount: currentDiscount, selectionHandler: selectionHandler))
    }

    func openTax(
        _ currentTax: TaxType?,
        selectionHandler: @escaping TaxViewModel.SelectionHandler
    ) {
        trigger(.setTax(tax: currentTax, selectionHandler: selectionHandler))
    }

    func openStyles(
        input: any InvoiceInput,
        selectionHandler: @escaping (InvoiceStyle) -> Void
    ) {
        trigger(.setStyle(input: input, selectionHandler: selectionHandler))
    }

    func openCurrencies() {
        trigger(.setCurrency)
    }

    func close() {
        trigger(.dismiss)
    }

    func openPaywall(closeHandler: @escaping () -> Void) {
        trigger(.paywall(closeHandler: closeHandler))
    }
}

extension CreateInvoiceCoordinator: DiscountRouter {

    func closeDiscount() {
        trigger(.dismiss)
    }
}

extension CreateInvoiceCoordinator: TaxRouter {

    func closeTax() {
        trigger(.dismiss)
    }
}

extension CreateInvoiceCoordinator: CurrencyRouter {

    func closeCurrency() {
        trigger(.dismiss)
    }
}

extension CreateInvoiceCoordinator: InvoiceStylesRouter {

    func closeInvoiceStyles() {
        trigger(.dismiss)
    }
}
