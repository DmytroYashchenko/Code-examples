import CombinePlus
import Depin
import SDWebImage
import UIKit
import XCoordinator

class SimpleResultsViewModel {

    // MARK: - Injected properties

    @Injected private var factory: SimpleResultsViewStateFactory
    @Injected private var userInfoProvider: UserInfoProvider
    @Injected private var networkService: MathNetworkService
    @Injected private var freemiumProvider: FreemiumProvider
    @Injected private var shareService: ResultsShareService
    @Injected private var latexRenderingEventEmitter: LatexRenderingEventEmitter

    private unowned let view: SimpleResultsViewProtocol
    private let solution: Solution
    private let solvingFlow: SolvingFlowType
    private let originalImage: URL?
    private let onBackButtonTap: () -> Void

    // MARK: - Private properties

    private var bag = CancelBag()

    init(
        view: SimpleResultsViewProtocol,
        solution: Solution,
        solvingFlow: SolvingFlowType,
        originalImage: URL?,
        onBackButtonTap: @escaping () -> Void
    ) {
        self.view = view
        self.solution = solution
        self.solvingFlow = solvingFlow
        self.originalImage = originalImage
        self.onBackButtonTap = onBackButtonTap

        bind()
    }

    private func bind() {
        view.viewDidLoadPublisher
            .track { [unowned self] in
                let stepsCount = solution.stepsSolution?.steps.count ?? 0

                Events.SimpleResults.ResultsShown(
                    referrer: .history,
                    solvingStepsCount: stepsCount,
                    taskType: Analytics.TaskType(solvingFlow),
                    taskId: solution.history?.id,
                    responseLanguage: userInfoProvider.solvingLanguageId,
                    aiSolverName: solution.history?.aiSolverName
                )
                .send()
            }
            .sink { [unowned self] in
                bindOnLoad()
            }
            .store(in: &bag)

        latexRenderingEventEmitter.stream
            .sink { [unowned self] event in
                let taskType = Analytics.TaskType(solvingFlow)
                switch event {
                case let .latexClientRenderingFailed(latex):
                    Events.Latex.ClientRenderingFailed(
                        expression: latex,
                        taskType: taskType
                    )
                    .send()
                case let .latexToImageConversionRequested(latex):
                    Events.Latex.ToImageConversionRequested(
                        expression: latex,
                        taskType: taskType
                    )
                    .send()
                case let .latexToImageConversionSucceeded(latex):
                    Events.Latex.ToImageConversionSucceeded(
                        expression: latex,
                        taskType: taskType
                    )
                    .send()
                case let .latexToImageConversionFailed(latex):
                    Events.Latex.ToImageConversionFailed(
                        expression: latex,
                        taskType: taskType
                    )
                    .send()
                case let .latexConvertedImageFetchFailed(latex):
                    Events.Latex.ConvertedImageFetchFailed(
                        expression: latex,
                        taskType: taskType
                    )
                    .send()
                }
            }
            .store(in: &bag)
    }

    private func bindOnLoad() {
        Publishers.CombineLatest(
            userInfoProvider.hasAIPremiumPublisher,
            freemiumProvider.freemiumPublisher
        )
        .compactMap { [weak self] premium, freemium in
            self.map { slf in
                slf.factory.make(
                    with: slf.solution,
                    originalImage: slf.originalImage,
                    premiumEnabled: premium,
                    freemiumEnabled: freemium.isOne(of: .withPremium, .withoutPremium)
                )
            }
        }
        .nonNil()
        .sink { [weak self] viewState in
            self?.view.apply(viewState)
        }
        .store(in: &bag)

        view.backTapRelay
            .sink { [unowned self] in
                onBackButtonTap()
            }
            .store(in: &bag)

        view.shareTapRelay
            .track { [unowned self] in
                Events.SimpleResults.ShareResultsButtonClicked(
                    placement: .historyDetailsScreen,
                    taskType: Analytics.TaskType(solvingFlow)
                )
                .send()
            }
            .sink { [unowned self] in
                handleShare()
            }
            .store(in: &bag)
    }

    private func handleShare() {
        view.setLoading(true)
        SDWebImageManager.shared.loadImage(
            with: originalImage,
            options: .highPriority,
            progress: nil,
            completed: { [weak self] image, _, _, _, finished, _ in
                DispatchQueue.main.async {
                    guard
                        let self,
                        let image,
                        finished
                    else {
                        self?.view.setLoading(false)
                        return
                    }

                    self.view.setLoading(false)
                    self.shareService.share(
                        solution: self.solution,
                        originalImage: image,
                        solvingFlow: self.solvingFlow,
                        parent: self.view
                    )
                }
            }
        )
    }
}
