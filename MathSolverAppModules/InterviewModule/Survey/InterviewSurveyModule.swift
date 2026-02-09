import UIKit
import XCoordinator

struct InterviewSurveyModule: BuildableModule {

    let router: StrongRouter<InterviewRoute>
    let placement: Analytics.Interview.Placement

    func build() -> UIViewController {
        BaseHostingViewController(
            rootView: InterviewSurveyView(
                viewModel: InterviewSurveyViewModel(
                    router: router,
                    placement: placement
                )
            )
        )
    }
}

extension BuildableModule where Self == InterviewSurveyModule {

    static func interviewSurvey(
        router: StrongRouter<InterviewRoute>,
        placement: Analytics.Interview.Placement
    ) -> Self {
        InterviewSurveyModule(
            router: router,
            placement: placement
        )
    }
}
