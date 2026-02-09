import UIKit

struct TipsModule: BuildableModule {

    let router: TipsRouterProtocol
    let referrer: Analytics.Tips.Referrer
    let solvingFlow: SolvingFlowType

    func build() -> UIViewController {
        TipsViewController(
            rootView: TipsView(
                viewModel: TipsViewModel(
                    router: router,
                    referrer: referrer,
                    solvingFlow: solvingFlow
                )
            )
        )
    }
}

extension BuildableModule where Self == TipsModule {

    static func tips(
        router: TipsRouterProtocol,
        referrer: Analytics.Tips.Referrer,
        solvingFlow: SolvingFlowType
    ) -> Self {
        TipsModule(
            router: router,
            referrer: referrer,
            solvingFlow: solvingFlow
        )
    }
}
