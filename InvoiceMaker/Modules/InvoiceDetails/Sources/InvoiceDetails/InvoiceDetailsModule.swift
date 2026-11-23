import SwiftUIExt

struct InvoiceDetailsModule: Module {

    let router: InvoiceDetailsRouter
    let invoice: Invoice

    func build() -> UIViewController {
        let viewModel = InvoiceDetailsViewModel(
            router: router,
            invoice: invoice
        )
        let view = InvoiceDetailsView(viewModel: viewModel)
        let viewController = HostingController(rootView: view)
        return viewController
    }
}
