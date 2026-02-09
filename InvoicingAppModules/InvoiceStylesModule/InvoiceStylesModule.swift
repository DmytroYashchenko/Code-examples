import SwiftUIExt

struct InvoiceStylesModule: Module {

    let router: InvoiceStylesRouter
    let input: InvoiceInput
    let onStyleSelected: (InvoiceStyle) -> Void

    func build() -> UIViewController {
        let viewModel = InvoiceStylesViewModel(
            router: router,
            input: input,
            onStyleSelected: onStyleSelected
        )
        let view = InvoiceStylesView(viewModel: viewModel)
        let viewController = HostingController(rootView: view)
        return viewController
    }
}
