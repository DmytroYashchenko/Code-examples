import UIKit
import XCoordinator

enum InterviewRoute: Route {
    case engagement
    case interview
    case pop
    case dismiss(isInterviewCompleted: Bool)
}

class InterviewCoordinator: NavigationCoordinator<InterviewRoute> {

    private let placement: Analytics.Interview.Placement
    private let completionHandler: () -> Void

    init(
        placement: Analytics.Interview.Placement,
        completionHandler: @escaping () -> Void
    ) {
        self.placement = placement
        self.completionHandler = completionHandler

        super.init(
            rootViewController: UINavigationController(),
            initialRoute: nil
        )
        trigger(.engagement)
    }

    override func prepareTransition(for route: InterviewRoute) -> NavigationTransition {
        switch route {
        case .engagement:
            let viewController = moduleBuilder.build(.interviewEngagement(
                router: strongRouter,
                placement: placement
            ))
            rootViewController.viewControllers = [viewController]
            rootViewController.setNavigationBarHidden(true, animated: false)
            return .none()
        case .interview:
            let viewController = moduleBuilder.build(.interviewSurvey(
                router: strongRouter,
                placement: placement
            ))
            return .push(viewController)
        case .pop:
            return .pop()
        case .dismiss(let isInterviewCompleted):
            if isInterviewCompleted {
                completionHandler()
            }
            return .dismiss()
        }
    }
}
