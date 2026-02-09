import UIKit
import XCoordinator

struct InterviewEngagementModule: BuildableModule {

    let router: StrongRouter<InterviewRoute>
    let placement: Analytics.Interview.Placement

    func build() -> UIViewController {
        BaseHostingViewController(
            rootView: InterviewEngagementView(
                viewModel: InterviewEngagementViewModel(
                    router: router,
                    placement: placement
                )
            )
        )
    }
}

extension BuildableModule where Self == InterviewEngagementModule {

    static func interviewEngagement(
        router: StrongRouter<InterviewRoute>,
        placement: Analytics.Interview.Placement
    ) -> Self {
        InterviewEngagementModule(
            router: router,
            placement: placement
        )
    }
}
