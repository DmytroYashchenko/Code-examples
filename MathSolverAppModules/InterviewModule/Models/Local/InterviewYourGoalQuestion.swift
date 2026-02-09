import Depin

struct InterviewYourGoalQuestion: SurveyQuestion {

    @Injected private var i18n: I18n

    var id: String { "what_was_your_goal_in_downloading_our_app_question" }
    var title: String { i18n.str(.whatWasYourGoalInDownloadingOurApp)}
    var subtitle: String { "" }

    var answers: [SurveyAnswer] = [
        QuickAndEaseSolutionsAnswer(),
        SolutionGuidancesAnswer(),
        PracticeAndImprovementAnswer(),
        HomeworkHelpAnswer(),
        TrackMyProgressAnswer()
    ]

    var configurationType: SurveyQuestionConfigurationType {
        .multipleChoiceCheckbox
    }
}

// MARK: - Answers

extension InterviewYourGoalQuestion {

    struct QuickAndEaseSolutionsAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "goal_get_quick_and_easy_solutions_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.getQuickAndEasySolutions) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct SolutionGuidancesAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "goal_get_step_by_step_solution_guidances_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.getStepByStepSolutionGuidances) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct PracticeAndImprovementAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "goal_practice_and_improvement_in_math_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.practiceAndImprovementInMath) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct HomeworkHelpAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "goal_homework help_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.homeworkHelp) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct TrackMyProgressAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "goal_track_my_progress_in_math_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.trackMyProgressInMath) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }
}
