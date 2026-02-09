import Depin

struct InterviewUsageFrequencyQuestion: SurveyQuestion {

    @Injected private var i18n: I18n

    var id: String { "how_often_do_you_use_our_math_solver_app_question" }
    var title: String { i18n.str(.howOftenDoYouUseApp)}
    var subtitle: String { "" }

    var answers: [SurveyAnswer] = [
        DailyAnswer(),
        WeeklyAnswer(),
        MonthlyAnswer(),
        OccasionallyAnswer()
    ]

    var configurationType: SurveyQuestionConfigurationType {
        .singleChoice
    }
}

// MARK: - Answers

extension InterviewUsageFrequencyQuestion {

    struct DailyAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "usage_frequency_daily_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.daily) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct WeeklyAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "usage_frequency_weekly_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.weekly) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct MonthlyAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "usage_frequency_monthly_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.monthly) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct OccasionallyAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "usage_frequency_occasionally_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.occasionally) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }
}
