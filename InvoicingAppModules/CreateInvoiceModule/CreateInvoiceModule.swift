import SwiftUIExt

struct CreateInvoiceModule: Module {

    let router: CreateInvoiceRouter

    func build() -> UIViewController {
        let viewModel = CreateInvoiceViewModel(router: router)
        let view = CreateInvoiceView(viewModel: viewModel)
        let viewController = HostingController(rootView: view)
        return viewController
    }
}
