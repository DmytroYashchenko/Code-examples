import CombinePlus
import Depin
import SwiftUI
import XCoordinator

class InterviewSurveyViewModel: ObservableObject {

    @Injected private var factory: InterviewSurveyViewStateFactory
    @Injected private var keyboardAppearanceService: KeyboardAppearanceService
    @Injected private var networkService: MathNetworkService
    @Injected private var interviewService: InterviewService
    @Injected private var hapticsPlayer: HapticsPlayer

    private let router: StrongRouter<InterviewRoute>
    private let placement: Analytics.Interview.Placement
    private var shownPagesIndices = Set<Int>()

    @Published var currentPage = 0

    @Published var questions: [SurveyQuestion] = [
        InterviewHowOldAreYouQuestion(),
        InterviewYourGoalQuestion(),
        InterviewUsageFrequencyQuestion(),
        InterviewContactsQuestion()
    ]

    @Published var viewState = InterviewSurveyView.ViewState(
        navigationTitle: .init(),
        currentScreen: 0,
        screens: [],
        isForwardSwipeAvailable: false,
        isBackwardSwipeAvailable: false,
        ctaTitle: .init(),
        isCtaEnabled: false,
        keyboardHeight: 0
    )

    init(
        router: StrongRouter<InterviewRoute>,
        placement: Analytics.Interview.Placement
    ) {
        self.router = router
        self.placement = placement
        bind()
    }
}

// MARK: - Private interface

private extension InterviewSurveyViewModel {

    func bind() {
        Publishers.CombineLatest3(
                $currentPage
                    .perform { [unowned self] page in
                        shownPagesIndices.insert(page)
                    }
                    .eraseToAnyPublisher(),
                $questions,
                keyboardAppearanceService.$keyboardHeight
            )
            .map { [unowned self] screen, questions, keyboardHeight in
                factory.make(
                    currentScreen: screen,
                    questions: questions,
                    keyboardHeight: keyboardHeight
                )
        }
        .assign(to: &$viewState)
    }

    func sendAnswers() {
        let answeredQuestions = questions.filter({ $0.isAnswered })
        guard !answeredQuestions.isEmpty else { return }

        _ = self.networkService.interview(questions: self.questions).sink()
    }

    func sendQuestionsAnalytics() {
        shownPagesIndices.forEach { index in
            guard let question = questions[safe: index] else { return }
            interviewService.sendInterviewQuestionShownEvent(
                placement: placement,
                question: question.title,
                questionNumber: index + 1
            )
        }

        questions.enumerated().forEach { index, question in
            guard question.isAnswered else { return }
            interviewService.sendInterviewQuestionAnsweredEvent(
                placement: placement,
                question: question.title,
                questionAnswers: question.answersValues,
                questionNumber: index + 1
            )
            if question.id == InterviewHowOldAreYouQuestion().id, let age = question.answersValues.first {
                interviewService.setUserAgeProperty(age: age)
            }
        }
    }
}

// MARK: - Public interface

extension InterviewSurveyViewModel {

    func moveToNextPage() {
        guard questions.indices.contains(currentPage) else { return }
        currentPage += 1
        keyboardAppearanceService.hideKeyboard()
    }

    func moveToPreviousPage() {
        guard questions.indices.contains(currentPage) else { return }
        currentPage -= 1
        keyboardAppearanceService.hideKeyboard()
    }

    func closeTapped() {
        if currentPage == 0 {
            sendAnswers()
            sendQuestionsAnalytics()
            interviewService.sendInterviewFlowLeftEvent(placement: placement)
            router.trigger(.pop)
        } else {
            moveToPreviousPage()
        }
    }

    func continueTapped() {
        if currentPage == questions.indices.max() {
            sendAnswers()
            sendQuestionsAnalytics()
            interviewService.markCompleted()
            interviewService.sendInterviewFlowCompletedEvent(placement: placement)
            router.trigger(.dismiss(isInterviewCompleted: true))
        } else {
            moveToNextPage()
        }
        hapticsPlayer.play(systemHaptic: .impactFeedback(style: .soft))
    }

    func selectAnswer(
        questionId: String,
        answerId: String,
        text: String?
    ) {
        guard let questionIndex = questions.firstIndex(where: { $0.id == questionId }) else {
            return
        }
        questions[questionIndex].selectAnswer(withId: answerId, text: text)
    }
}
