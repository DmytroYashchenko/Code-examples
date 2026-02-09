import Depin
import SwiftUI
import XCoordinator

class InterviewEngagementViewModel: ObservableObject {

    @Injected private var interviewService: InterviewService
    @Injected private var hapticsPlayer: HapticsPlayer

    private let router: StrongRouter<InterviewRoute>
    private let placement: Analytics.Interview.Placement

    init(
        router: StrongRouter<InterviewRoute>,
        placement: Analytics.Interview.Placement
    ) {
        self.router = router
        self.placement = placement

        interviewService.sendInterviewOnboardScreenShownEvent(placement: placement)
    }

    func close() {
        router.trigger(.dismiss(isInterviewCompleted: false))
    }

    func startTapped() {
        interviewService.sendInterviewFlowStartedEvent(placement: placement)
        router.trigger(.interview)
        hapticsPlayer.play(systemHaptic: .impactFeedback(style: .soft))
    }

    func skipTapped() {
        router.trigger(.dismiss(isInterviewCompleted: false))
    }
}
