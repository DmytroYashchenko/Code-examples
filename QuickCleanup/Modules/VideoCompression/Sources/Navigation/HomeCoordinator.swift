// Excerpt: original compression and summary routes; unrelated Home routes omitted.
import Foundation
import XCoordinator

@MainActor
protocol HomeRouter: AnyObject {

    func openVideoCompression(input: VideoCompressionInput)
    func openCleaningSummary(input: CleaningSummaryFlowInput)
    func closeVideoCompression()
    func popToRoot()
    func closeCleaningSummaryAndPopToRoot()
}

enum HomeRoute: Route {

    case home
    case videoCompression(input: VideoCompressionInput)
    case cleaningSummary(input: CleaningSummaryFlowInput)
    case pop
    case popToRoot
    case dismissAndPopToRoot
}

final class HomeCoordinator: NavigationCoordinator<HomeRoute> {

    init() {
        super.init(initialRoute: .home)
    }

    override func prepareTransition(for route: HomeRoute) -> NavigationTransition {
        switch route {
        case .home:
            return .set(HomeModule(router: self).build())
        case let .videoCompression(input):
            let viewController = VideoCompressionModule(
                router: self,
                input: input
            )
            .build()
            viewController.hidesBottomBarWhenPushed = true
            return .push(viewController)
        case let .cleaningSummary(input):
            let viewController = CleaningSummaryModule(
                router: self,
                input: input
            )
            .build()
            return .present(
                viewController,
                modalPresentationStyle: .fullScreen
            )
        case .pop:
            return .pop()
        case .popToRoot:
            return .popToRoot()
        case .dismissAndPopToRoot:
            return .multiple(
                .dismiss(),
                .popToRoot()
            )
        }
    }
}

// MARK: - HomeRouter

extension HomeCoordinator: HomeRouter {

    func openVideoCompression(input: VideoCompressionInput) {
        trigger(.videoCompression(input: input))
    }

    func openCleaningSummary(input: CleaningSummaryFlowInput) {
        trigger(.cleaningSummary(input: input))
    }

    func closeVideoCompression() {
        trigger(.pop)
    }

    func popToRoot() {
        trigger(.popToRoot)
    }

    func closeCleaningSummaryAndPopToRoot() {
        trigger(.dismissAndPopToRoot)
    }
}
