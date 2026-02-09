import Depin

struct InterviewContactsQuestion: SurveyQuestion {

    @Injected private var i18n: I18n

    var id: String { "to_get_in_touch_we_kindly_request_your_details_question" }
    var title: String { i18n.str(.toGetInTouchWeKindlyRequestYourDetails) }
    var subtitle: String { "" }

    var answers: [SurveyAnswer] = [
        NameAnswer(),
        EmailAnswer()
    ]

    var configurationType: SurveyQuestionConfigurationType {
        .textInput
    }
}

// MARK: - Answers

extension InterviewContactsQuestion {

    struct NameAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "contacts_name_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.name) }
        var isSelected = false
        var inputData = SurveyAnswerInputData()

        var analyticName: String {
            id
        }

        init() {
            inputData.placeholderText = i18n.str(.enterYourName)
        }
    }

    struct EmailAnswer: SurveyAnswer {

        @Injected private var i18n: I18n

        var id: String { "contacts_email_answer" }
        var icon: ImageResource? { nil }
        var text: String { i18n.str(.email) + "*" }
        var isSelected = false
        var inputData = SurveyAnswerInputData(validationType: .email)

        var analyticName: String {
            id
        }

        init() {
            inputData.placeholderText = i18n.str(.enterYourEmail)
        }
    }
}
