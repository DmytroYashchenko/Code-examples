import SwiftUIExt

struct CleaningSummaryModule: Module {

    let router: HomeRouter
    let input: CleaningSummaryFlowInput

    func build() -> UIViewController {
        let viewModel = CleaningSummaryViewModel(
            router: router,
            input: input
        )
        let view = CleaningSummaryView(viewModel: viewModel)
        return HostingController(rootView: view)
    }
}
