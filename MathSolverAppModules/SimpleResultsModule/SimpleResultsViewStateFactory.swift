import Depin
import SwiftMath
import UIKit

class SimpleResultsViewStateFactory {

    typealias ViewState = SimpleResultsViewController.ViewState
    typealias StepViewState = SolutionStepView.ViewState
    typealias HeaderViewState = SolutionHeaderView.ViewState
    typealias StepPosition = SolutionStepView.StepPosition

    @Injected private var latexProcessor: LatexProcessor
    @Injected private var i18n: I18n
    @Injected private var latexRenderingEventEmitter: LatexRenderingEventEmitter

    func make(
        with solution: Solution,
        originalImage: URL?,
        premiumEnabled: Bool,
        freemiumEnabled: Bool
    ) -> ViewState? {
        if let stepsSolution = solution.stepsSolution {

            // Steps based solution
            let steps = stepsSolution.steps
            let solutionStepsViewState = steps.enumerated().map { offset, step in
                let position: StepPosition = if offset == 0 {
                    .first
                } else if offset == steps.count - 1 {
                    .last
                } else {
                    .middle
                }

                return StepViewState(
                    stepTitle: i18n.str(.stepNumber(step.stepNumber)),
                    description: step.description,
                    expression: step.latexExpression,
                    position: position
                )
            }

            let canRenderOriginalProblem = latexProcessor.validate(latex: solution.incomingData)
            let image: URL? = canRenderOriginalProblem ? nil : originalImage

            var headerViewState = [
                HeaderViewState(
                    title: i18n.str(.problem),
                    description: solution.incomingData,
                    originalImage: image.map { .urlPlaceholderImage(url: $0) },
                    headerIconBackgroundColor: .warning50,
                    headerIcon: .icProblem.withTintColor(
                        .warning500,
                        renderingMode: .alwaysOriginal
                    )
                ),
                HeaderViewState(
                    title: i18n.str(.solution),
                    description: stepsSolution.finalResult,
                    originalImage: nil,
                    headerIconBackgroundColor: .success50,
                    headerIcon: .icSolution.withTintColor(
                        .success500,
                        renderingMode: .alwaysOriginal
                    ),
                    action: .share(image: .icShare.withRenderingMode(.alwaysTemplate))
                )
            ]
            appendGraphHeaderIfNeeded(to: &headerViewState, from: solution)

            return ViewState(
                title: i18n.str(.calculations),
                headerTitle: i18n.str(.results),
                stepsTitle: i18n.str(.solvingSteps),
                solutionStepsViewState: solutionStepsViewState,
                headerViewState: headerViewState
            )

        } else if let textSolution = solution.textSolution {

            // Text based solution
            let (description, image) = problemHeaderInfo(
                incomingData: solution.incomingData,
                originalImage: originalImage
            )

            var headerViewState = [
                HeaderViewState(
                    title: i18n.str(.problem),
                    description: description,
                    originalImage: image.map { .urlPlaceholderImage(url: $0) },
                    headerIconBackgroundColor: .warning50,
                    headerIcon: .icProblem.withTintColor(
                        .warning500,
                        renderingMode: .alwaysOriginal
                    )
                ),
                HeaderViewState(
                    title: i18n.str(.solution),
                    description: textSolution.solution,
                    originalImage: nil,
                    headerIconBackgroundColor: .success50,
                    headerIcon: .icSolution.withTintColor(
                        .success500,
                        renderingMode: .alwaysOriginal
                    ),
                    action: .share(image: .icShare.withRenderingMode(.alwaysTemplate))
                )
            ]
            appendGraphHeaderIfNeeded(to: &headerViewState, from: solution)

            return ViewState(
                title: i18n.str(.calculations),
                headerTitle: i18n.str(.results),
                stepsTitle: i18n.str(.solvingSteps),
                solutionStepsViewState: nil,
                headerViewState: headerViewState
            )
        }
        return nil
    }
}

// MARK: - Private methods

private extension SimpleResultsViewStateFactory {

    func problemHeaderInfo(
        incomingData: String,
        originalImage: URL?
    ) -> (String, URL?) {
        // If no incoming data was received, just display an image
        // This case is actually implemented for geometry tasks, because they never have incoming data.
        if incomingData.isEmpty {
            return ("", originalImage)
        }

        return latexProcessor.validate(latex: incomingData)
        ? (incomingData, nil)
        : ("", originalImage)
    }

    func appendGraphHeaderIfNeeded(
        to currentHeaders: inout [HeaderViewState],
        from solution: Solution
    ) {
        guard
            let graph = solution.graph,
            graph.isNotEmptyNotOnlyWhitespaces
        else {
            return
        }
        currentHeaders.insert(
            HeaderViewState(
                title: i18n.str(.graph),
                description: "",
                graph: .init(
                    jsonString: graph,
                    taskId: solution.history?.id
                ),
                originalImage: nil,
                headerIconBackgroundColor: .primary50,
                headerIcon: .icCurveGraph.withTintColor(
                    .primary600,
                    renderingMode: .alwaysOriginal
                )
            ),
            at: 1
        )
    }
}
