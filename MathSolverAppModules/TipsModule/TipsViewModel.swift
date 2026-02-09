import CombinePlus
import Depin

protocol TipsRouterProtocol {

    func openCameraFromTips()
    func closeTips()
}

class TipsViewModel: ObservableObject {

    @Injected private var factory: TipsViewStateFactory
    @Injected private var userInfoProvider: UserInfoProvider
    @Injected private var tipsService: TipsService
    @Injected private var hapticsPlayer: HapticsPlayer

    private let router: TipsRouterProtocol
    private let referrer: Analytics.Tips.Referrer
    private let solvingFlow: SolvingFlowType

    @Published var viewState: TipsView.ViewState = .makeEmpty()
    @Published var currentStepIndex = 0

    @Published var tipsStates: [TipType: TipState] = TipType
        .allCases
        .reduce(into: [:]) { partialResult, tipType in
            // Initially contains all tip types with incorrect states.
            partialResult[tipType] = .incorrect
        }

    private var steps: [TipType] = TipType
        .allCases
        .map { $0 }

    private var taskType: Analytics.TaskType? {
        switch referrer {
        case .mainScreen, .aiFeaturesCamera:
            .init(solvingFlow)
        case .tutorsCamera:
            nil
        }
    }

    init(
        router: TipsRouterProtocol,
        referrer: Analytics.Tips.Referrer,
        solvingFlow: SolvingFlowType
    ) {
        self.router = router
        self.referrer = referrer
        self.solvingFlow = solvingFlow

        bind()
    }
}

// MARK: - Private interface

private extension TipsViewModel {

    func bind() {
        $currentStepIndex
            .perform { [unowned self] currentStepIndex in
                Events.Tips.ScreenShown(
                    referrer: referrer,
                    taskType: taskType,
                    stepNumber: currentStepIndex + 1
                )
                .send()
            }
            .combineLatest($tipsStates)
            .map { [unowned self] currentStepIndex, tipsStates in
                factory
                    .make(
                        referrer: referrer,
                        solvingFlow: solvingFlow,
                        steps: steps,
                        currentStepIndex: currentStepIndex,
                        tipsStates: tipsStates
                    )
            }
            .assign(to: &$viewState)
    }

    func moveToNextStep() {
        guard steps.indices.contains(currentStepIndex + 1) else { return }
        currentStepIndex += 1
    }
}

// MARK: - Public interface

extension TipsViewModel {

    func closeTapped() {
        Events.Tips.ScreenLeft(
            referrer: referrer,
            taskType: taskType,
            stepNumber: currentStepIndex + 1
        )
        .send()
        router.closeTips()
    }

    func continueTapped() {
        guard
            let currentStep = steps[safe: currentStepIndex],
            let currentStepState = tipsStates[currentStep]
        else {
            return
        }

        if currentStepIndex == steps.indices.max() {
            switch currentStepState {
            case .incorrect:
                tipsStates[currentStep] = .correct
            case .correct:
                tipsService.saveTipsWereShown(for: solvingFlow)

                Events.Tips.FlowFinished(
                    referrer: referrer,
                    taskType: taskType,
                    stepNumber: currentStepIndex + 1
                )
                .send()

                switch referrer {
                case .mainScreen:
                    router.openCameraFromTips()
                case .aiFeaturesCamera, .tutorsCamera:
                    router.closeTips()
                }
            }
        } else {
            switch currentStepState {
            case .incorrect:
                tipsStates[currentStep] = .correct
            case .correct:
                Events.Tips.ContinueClicked(
                    referrer: referrer,
                    taskType: taskType,
                    stepNumber: currentStepIndex + 1
                )
                .send()
                moveToNextStep()
            }
        }

        hapticsPlayer.play(systemHaptic: .impactFeedback(style: .soft))
    }
}
