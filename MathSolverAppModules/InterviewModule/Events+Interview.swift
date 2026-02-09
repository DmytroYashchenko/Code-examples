extension Events {

    enum Interview {
        struct BannerShown: Event {
            let placement: Analytics.Interview.Placement
            let shownCount: Int
            let userType: Analytics.Interview.UserType
        }

        struct BannerClicked: Event {
            let placement: Analytics.Interview.Placement
            let shownCount: Int
            let userType: Analytics.Interview.UserType
        }

        struct OnboardScreenShown: Event {
            let placement: Analytics.Interview.Placement
            let shownCount: Int
            let userType: Analytics.Interview.UserType
        }

        struct FlowStarted: Event {
            let placement: Analytics.Interview.Placement
            let shownCount: Int
            let userType: Analytics.Interview.UserType
        }

        struct QuestionShown: Event {
            let placement: Analytics.Interview.Placement
            let shownCount: Int
            let userType: Analytics.Interview.UserType
            let question: String
            let questionNumber: Int
        }

        struct QuestionAnswered: Event {
            let placement: Analytics.Interview.Placement
            let shownCount: Int
            let userType: Analytics.Interview.UserType
            let question: String
            let questionAnswers: [String]
            let questionNumber: Int
        }

        struct FlowLeft: Event {
            let placement: Analytics.Interview.Placement
            let shownCount: Int
            let userType: Analytics.Interview.UserType
        }

        struct FlowCompleted: Event {
            let placement: Analytics.Interview.Placement
            let shownCount: Int
            let userType: Analytics.Interview.UserType
        }

        struct UserAge: Event {
            let value: String
        }

        struct CompletedInterviewRegistration: Event { }
    }
}

// MARK: - UserAnalytics + Interview

extension UserAnalytics {

    func handle(interview event: Event) {
        switch event {
        case let event as Events.Interview.BannerShown:
            process(
                name: "user_interview_banner_shown",
                params: [
                    "placement": event.placement.analyticName,
                    "shown_count": event.shownCount,
                    "user_type": event.userType.analyticName
                ]
            )
        case let event as Events.Interview.BannerClicked:
            process(
                name: "user_interview_banner_clicked",
                params: [
                    "placement": event.placement.analyticName,
                    "shown_count": event.shownCount,
                    "user_type": event.userType.analyticName
                ]
            )
        case let event as Events.Interview.OnboardScreenShown:
            process(
                name: "user_interview_onboard_screen_shown",
                params: [
                    "placement": event.placement.analyticName,
                    "shown_count": event.shownCount,
                    "user_type": event.userType.analyticName
                ]
            )
        case let event as Events.Interview.FlowStarted:
            process(
                name: "user_interview_flow_started",
                params: [
                    "placement": event.placement.analyticName,
                    "shown_count": event.shownCount,
                    "user_type": event.userType.analyticName
                ]
            )
        case let event as Events.Interview.QuestionShown:
            process(
                name: "user_interview_question_shown",
                params: [
                    "placement": event.placement.analyticName,
                    "shown_count": event.shownCount,
                    "user_type": event.userType.analyticName,
                    "question": event.question,
                    "screen": String(event.questionNumber)
                ]
            )
        case let event as Events.Interview.QuestionAnswered:
            process(
                name: "user_interview_question_answered",
                params: [
                    "placement": event.placement.analyticName,
                    "shown_count": event.shownCount,
                    "user_type": event.userType.analyticName,
                    "question": event.question,
                    "answer": {
                        if event.questionAnswers.count == 1, let first = event.questionAnswers.first {
                            return first
                        } else {
                            return event.questionAnswers
                        }
                    }(),
                    "screen": String(event.questionNumber)
                ]
            )
        case let event as Events.Interview.FlowLeft:
            process(
                name: "user_interview_flow_left",
                params: [
                    "placement": event.placement.analyticName,
                    "shown_count": event.shownCount,
                    "user_type": event.userType.analyticName
                ]
            )
        case let event as Events.Interview.FlowCompleted:
            process(
                name: "user_interview_flow_completed",
                params: [
                    "placement": event.placement.analyticName,
                    "shown_count": event.shownCount,
                    "user_type": event.userType.analyticName
                ]
            )
        case let event as Events.Interview.UserAge:
            setProperty(name: "user_age", with: event.value)
        case _ as Events.Interview.CompletedInterviewRegistration:
            setProperty(name: "completed_interview_registration", with: 1)
        default:
            return
        }
    }
}
