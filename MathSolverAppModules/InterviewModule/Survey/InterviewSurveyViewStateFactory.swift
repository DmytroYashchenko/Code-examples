import Depin
import SwiftUI

class InterviewSurveyViewStateFactory {

    typealias ViewState = InterviewSurveyView.ViewState

    @Injected private var i18n: I18n

    func make(
        currentScreen: Int,
        questions: [SurveyQuestion],
        keyboardHeight: CGFloat
    ) -> ViewState {
        ViewState(
            navigationTitle: navigationTitle(currentScreen, questions.count),
            currentScreen: currentScreen,
            screens: choiceConfiguration(questions),
            isForwardSwipeAvailable: isForwardSwipeAvailable(currentScreen, questions),
            isBackwardSwipeAvailable: isBackwardSwipeAvailable(currentScreen, questions),
            ctaTitle: i18n.str(currentScreen == questions.indices.max() ? .finish : .continue),
            isCtaEnabled: questions[currentScreen].isAnswered,
            keyboardHeight: keyboardHeight
        )
    }

    private func navigationTitle(
        _ currentScreen: Int,
        _ screensCount: Int
    ) -> AttributedString {
        "\(currentScreen + 1)/\(screensCount)"
            .mutableAttributedString
            .setFont(.ds.headlineSemibold)
            .setTextColor(.black900)
            .setFont(.ds.headlineMedium, to: "/\(screensCount)")
            .setTextColor(.black400, to: "/\(screensCount)")
            .attributedString
    }

    private func choiceConfiguration(_ questions: [SurveyQuestion]) -> [any View] {
        questions.map { question in
            switch question.configurationType {
            case .singleChoice:
                SingleChoiceConfiguration(from: question)
            case .multiChoice:
                MultiChoiceFlowConfiguration(from: question)
            case .multipleChoiceCheckbox:
                MultipleChoiceCheckboxConfiguration(from: question)
            case .textInput:
                TextInputChoiceConfiguration(from: question)
            }
        }
    }

    private func isForwardSwipeAvailable(
        _ currentScreen: Int,
        _ questions: [SurveyQuestion]
    ) -> Bool {
        questions.indices.contains(currentScreen + 1)
        && questions[currentScreen].isAnswered
    }

    private func isBackwardSwipeAvailable(
        _ currentScreen: Int,
        _ questions: [SurveyQuestion]
    ) -> Bool {
        questions.indices.contains(currentScreen - 1)
    }
}
