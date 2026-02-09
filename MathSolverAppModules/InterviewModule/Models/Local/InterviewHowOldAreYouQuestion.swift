import Depin

struct InterviewHowOldAreYouQuestion: SurveyQuestion {

    @Injected private var i18n: I18n

    var id: String { "how_old_are_you_question" }
    var title: String { i18n.str(.howOldAreYou)}
    var subtitle: String { "" }

    var answers: [SurveyAnswer] = [
        AgeUnder18Answer(),
        Age19To24Answer(),
        Age25To35Answer(),
        Age35To54Answer(),
        Age55OrOlderAnswer()
    ]

    var configurationType: SurveyQuestionConfigurationType {
        .singleChoice
    }
}

// MARK: - Answers

extension InterviewHowOldAreYouQuestion {

    struct AgeUnder18Answer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "age_under_18_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.under18) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct ge19To24Answer: SurveyAnswer {

        var id: String { "age_19_to_24_answer" }
        var icon: ImageResource? { nil }
        var text: String { "19-24" }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct Age25To35Answer: SurveyAnswer {

        var id: String { "age_25_to_35_answer" }
        var icon: ImageResource? { nil }
        var text: String { "25-35" }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct Age35To54Answer: SurveyAnswer {

        var id: String { "age_35_to_54_answer" }
        var icon: ImageResource? { nil }
        var text: String { "35-54" }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }

    struct Age55OrOlderAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "age_55_or_older_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.fiftyFiveOrOlder) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }
    }
}
