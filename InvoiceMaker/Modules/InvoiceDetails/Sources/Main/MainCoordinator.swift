import XCoordinator

enum MainRoute: Route {
    case main
    case invoiceCreation
    case invoiceDetails(
        invoice: Invoice,
        invoiceDuplicationToastPresenter: InvoiceDuplicationToastPresenter
    )
    case paywall(closeHandler: () -> Void)
    case pop
}

class MainCoordinator: NavigationCoordinator<MainRoute> {

    private let tabBarRouter: TabBarRouter

    init(tabBarRouter: TabBarRouter) {
        self.tabBarRouter = tabBarRouter
        super.init(initialRoute: .main)

        let image = UIImage(systemName: "doc.text")?
            .withRenderingMode(.alwaysTemplate)
        rootViewController.tabBarItem = UITabBarItem(
            title: String(localized: "Invoices"),
            image: image,
            selectedImage: image
        )
    }

    override func prepareTransition(for route: MainRoute) -> NavigationTransition {
        switch route {

        case .main:
            let module = MainModule(router: self)
            return .set(module.build())

        case .invoiceCreation:
            return .none(CreateInvoiceCoordinator(rootViewController: rootViewController))

        case let .invoiceDetails(invoice, invoiceDuplicationToastPresenter):
            return .none(InvoiceDetailsCoordinator(
                rootViewController: rootViewController,
                invoice: invoice,
                invoiceDuplicationToastPresenter: invoiceDuplicationToastPresenter
            ))

        case let .paywall(closeHandler):
            return .none(PaywallCoordinator(
                rootViewController: rootViewController,
                referrer: .invoicesList,
                closeHandler: closeHandler
            ))

        case .pop:
            return .pop()
        }
    }
}

// MARK: - MainRouter

extension MainCoordinator: MainRouter {

    func openInvoiceDetails(
        invoice: Invoice,
        invoiceDuplicationToastPresenter: InvoiceDuplicationToastPresenter
    ) {
        trigger(.invoiceDetails(
            invoice: invoice,
            invoiceDuplicationToastPresenter: invoiceDuplicationToastPresenter
        ))
    }

    func openInvoiceCreation() {
        trigger(.invoiceCreation)
    }

    func openPaywall(closeHandler: @escaping () -> Void) {
        trigger(.paywall(closeHandler: closeHandler))
    }
}
