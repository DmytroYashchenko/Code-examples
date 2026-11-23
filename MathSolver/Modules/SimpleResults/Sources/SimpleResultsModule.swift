import UIKit

struct SimpleResultsModule: BuildableModule {

    let solution: Solution
    let solvingFlow: SolvingFlowType
    let originalImage: URL?
    let onBackButtonTap: () -> Void

    func build() -> UIViewController {
        let viewController = SimpleResultsViewController()
        let viewModel = SimpleResultsViewModel(
            view: viewController,
            solution: solution,
            solvingFlow: solvingFlow,
            originalImage: originalImage,
            onBackButtonTap: onBackButtonTap
        )
        viewController.viewModel = viewModel
        return viewController
    }
}

extension BuildableModule where Self == SimpleResultsModule {

    static func simpleResults(
        solution: Solution,
        solvingFlow: SolvingFlowType,
        originalImage: URL?,
        onBackButtonTap: @escaping () -> Void
    ) -> SimpleResultsModule {
        SimpleResultsModule(
            solution: solution,
            solvingFlow: solvingFlow,
            originalImage: originalImage,
            onBackButtonTap: onBackButtonTap
        )
    }
}
