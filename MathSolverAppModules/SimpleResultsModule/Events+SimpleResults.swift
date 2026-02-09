extension Events {

    enum SimpleResults {

        struct ResultsShown: Event {
            let referrer: Analytics.Results.Referrer
            let solvingStepsCount: Int
            let taskType: Analytics.TaskType
            let taskId: Int?
            let responseLanguage: String?
            let aiSolverName: String?
        }

        struct ShareResultsButtonClicked: Event {
            let placement: Analytics.Results.ShareResultsPlacement
            let taskType: Analytics.TaskType
        }
    }
}

// MARK: - UserAnalytics + SimpleResults

extension UserAnalytics {

    func handle(simpleResults event: Event) {
        switch event {
        case let event as Events.SimpleResults.ShareResultsButtonClicked:
            process(
                name: "math_solving_share_results_button_clicked",
                params: [
                    "placement": event.placement.analyticName,
                    "task_type": event.taskType.analyticName
                ]
            )
        case let event as Events.SimpleResults.ResultsShown:
            process(
                name: "math_solving_results_shown",
                params: [
                    "referrer": event.referrer.analyticName,
                    "solving_steps_amount_shown": event.solvingStepsCount,
                    "task_type": event.taskType.analyticName
                ]
                    .addIfPresent(event.taskId, for: "problem_id")
                    .addIfPresent(event.responseLanguage, for: "ai_response_lang")
                    .addIfPresent(event.aiSolverName, for: "reply_from_ai")
            )

        default:
            return
        }
    }
}
