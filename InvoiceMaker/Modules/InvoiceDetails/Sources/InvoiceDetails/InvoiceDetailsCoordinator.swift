import XCoordinator

enum InvoiceDetailsRoute: Route {

    case invoiceDetails(invoice: Invoice)
    case previewInvoice(input: InvoiceInput)
    case editInvoice(invoice: Invoice)
    case paywall(
        referrer: PaywallEvent.Referrer,
        closeHandler: () -> Void
    )
    case pop
    case dismiss
}

class InvoiceDetailsCoordinator: NavigationCoordinator<InvoiceDetailsRoute> {

    private weak var invoiceDuplicationToastPresenter: InvoiceDuplicationToastPresenter?

    init(
        rootViewController: UINavigationController,
        invoice: Invoice,
        invoiceDuplicationToastPresenter: InvoiceDuplicationToastPresenter
    ) {
        self.invoiceDuplicationToastPresenter = invoiceDuplicationToastPresenter
        super.init(rootViewController: rootViewController, initialRoute: nil)
        trigger(.invoiceDetails(invoice: invoice))
    }

    override func prepareTransition(for route: InvoiceDetailsRoute) -> NavigationTransition {
        switch route {
        case let .invoiceDetails(invoice):
            let module = InvoiceDetailsModule(
                router: self,
                invoice: invoice
            )
            let viewController = module.build()
            viewController.hidesBottomBarWhenPushed = true
            return .push(viewController)

        case let .previewInvoice(input):
            return .none(
                PreviewCoordinator(
                    rootViewController: rootViewController,
                    input: input
                )
            )

        case let .editInvoice(invoice):
            return .none(CreateInvoiceCoordinator(
                rootViewController: rootViewController,
                invoice: invoice
            ))

        case let .paywall(referrer, closeHandler):
            return .none(PaywallCoordinator(
                rootViewController: rootViewController,
                referrer: referrer,
                closeHandler: closeHandler
            ))

        case .pop:
            return .pop()

        case .dismiss:
            return .dismiss()
        }
    }
}

extension InvoiceDetailsCoordinator: InvoiceDetailsRouter {

    func openPreview(input: InvoiceInput) {
        trigger(.previewInvoice(input: input))
    }

    func openEditInvoice(invoice: Invoice) {
        trigger(.editInvoice(invoice: invoice))
    }

    func openPaywall(referrer: PaywallEvent.Referrer, closeHandler: @escaping () -> Void) {
        trigger(.paywall(referrer: referrer, closeHandler: closeHandler))
    }

    func closeInvoiceDetails() {
        trigger(.pop)
    }

    func closeInvoiceDetailsOnDuplication() {
        trigger(.pop) { [weak self] in
            self?.invoiceDuplicationToastPresenter?.presentEventDuplicatedToast()
        }
    }
}
