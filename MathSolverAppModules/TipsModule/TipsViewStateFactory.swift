import Depin
import UIKit

class TipsViewStateFactory {

    typealias ViewState = TipsView.ViewState

    @Injected private var i18n: I18n

    func make(
        referrer: Analytics.Tips.Referrer,
        solvingFlow: SolvingFlowType,
        steps: [TipType],
        currentStepIndex: Int,
        tipsStates: [TipType: TipState]
    ) -> ViewState {
        .init(
            title: i18n.str(.tips),
            ctaTitle: makeCtaTitle(
                steps: steps,
                currentStepIndex: currentStepIndex,
                tipsStates: tipsStates
            ),
            solvingFlow: solvingFlow,
            stepsViewStates: makeStepsViewStates(
                steps: steps,
                tipsStates: tipsStates
            ),
            currentStepIndex: currentStepIndex,
            isCloseButtonVisible: !referrer.isOne(of: .mainScreen)
        )
    }

    private func makeCtaTitle(
        steps: [TipType],
        currentStepIndex: Int,
        tipsStates: [TipType: TipState]
    ) -> String {
        guard let currentStep = steps[safe: currentStepIndex] else { return "" }

        return currentStepIndex == steps.indices.max()
        && tipsStates[currentStep] == .correct
        ? i18n.str(.startScanning)
        : i18n.str(.continue)
    }

    private func makeStepsViewStates(
        steps: [TipType],
        tipsStates: [TipType: TipState]
    ) -> [TipStepViewState] {
        steps.map { step in
            let tipState = tipsStates[step] ?? .incorrect

            var title: String {
                switch step {
                case .focus:
                    switch tipState {
                    case .incorrect:
                        i18n.str(.doNotCaptureExtraElements)
                    case .correct:
                        i18n.str(.focusOnTheProblem)
                    }
                case .visibility:
                    switch tipState {
                    case .incorrect:
                        i18n.str(.preventBlursAndShadows)
                    case .correct:
                        i18n.str(.useGoodLighting)
                    }
                case .crop:
                    switch tipState {
                    case .incorrect:
                        i18n.str(.doNotCutTheEquation)
                    case .correct:
                        i18n.str(.cropTheWholeProblem)
                    }
                }
            }

            return .init(
                tipType: step,
                tipState: tipState,
                title: title
            )
        }
    }
}
