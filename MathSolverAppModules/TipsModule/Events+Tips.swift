extension Events {

    enum Tips {
        struct ScreenShown: Event {
            let referrer: Analytics.Tips.Referrer
            let taskType: Analytics.TaskType?
            let stepNumber: Int
        }

        struct ScreenLeft: Event {
            let referrer: Analytics.Tips.Referrer
            let taskType: Analytics.TaskType?
            let stepNumber: Int
        }

        struct FlowFinished: Event {
            let referrer: Analytics.Tips.Referrer
            let taskType: Analytics.TaskType?
            let stepNumber: Int
        }

        struct ContinueClicked: Event {
            let referrer: Analytics.Tips.Referrer
            let taskType: Analytics.TaskType?
            let stepNumber: Int
        }
    }
}

// MARK: - UserAnalytics + Tips

extension UserAnalytics {

    func handle(tips event: Event) {
        switch event {
        case let event as Events.Tips.ScreenShown:
            process(
                name: "tips_screen_shown",
                params: [
                    "referrer": event.referrer.analyticName,
                    "task_type": event.taskType?.analyticName,
                    "screen": event.stepNumber
                ]
            )
        case let event as Events.Tips.ScreenLeft:
            process(
                name: "tips_left",
                params: [
                    "referrer": event.referrer.analyticName,
                    "task_type": event.taskType?.analyticName,
                    "screen": event.stepNumber
                ]
            )
        case let event as Events.Tips.FlowFinished:
            process(
                name: "tips_flow_finished",
                params: [
                    "referrer": event.referrer.analyticName,
                    "task_type": event.taskType?.analyticName,
                    "screen": event.stepNumber
                ]
            )
        case let event as Events.Tips.ContinueClicked:
            process(
                name: "tips_continue_clicked",
                params: [
                    "referrer": event.referrer.analyticName,
                    "task_type": event.taskType?.analyticName,
                    "screen": event.stepNumber
                ]
            )
        default:
            return
        }
    }
}
