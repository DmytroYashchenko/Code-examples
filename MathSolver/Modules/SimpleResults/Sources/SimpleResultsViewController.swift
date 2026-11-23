import CombinePlus
import FoundationPlus
import SwiftMath
import UIKit

protocol SimpleResultsViewProtocol: BaseViewController {
    var backTapRelay: AnyVoidRelay { get }
    var shareTapRelay: AnyVoidRelay { get }

    func apply(_ viewState: SimpleResultsViewController.ViewState)
    func setLoading(_ isLoading: Bool)
}

class SimpleResultsViewController: BaseViewController {

    struct ViewState {
        let title: String
        let headerTitle: String
        let stepsTitle: String
        let solutionStepsViewState: [SolutionStepView.ViewState]?
        let headerViewState: [SolutionHeaderView.ViewState]
    }

    var viewModel: SimpleResultsViewModel!

    // MARK: - IBOutlets

    @IBOutlet private var solutionsStepsContainer: UIView!
    @IBOutlet private var stepsStackView: UIStackView!
    @IBOutlet private var headerStackView: UIStackView!

    @IBOutlet private var titleLabel: UILabel! {
        didSet {
            titleLabel.font = .ds.title3Semibold
            titleLabel.textColor = .black900
        }
    }

    @IBOutlet private var topViewTopConstraint: NSLayoutConstraint! {
        didSet {
            // Hack to alight custom nav bar position with previous swiftUI screen
            topViewTopConstraint.constant = (UIApplication.keyWindow?.safeAreaInsets.top ?? 0) > 0 ? -5 : 0
        }
    }

    @IBOutlet private var backButton: UIButton! {
        didSet {
            backButton.setImage(
                UIImage(resource: .chevronLeft).withRenderingMode(.alwaysTemplate),
                for: .normal
            )
        }
    }

    @IBOutlet private var headerTitleLabel: UILabel! {
        didSet {
            headerTitleLabel.font = .ds.title2Bold
            headerTitleLabel.textColor = .black900
        }
    }

    @IBOutlet private var stepsTitleLabel: UILabel! {
        didSet {
            stepsTitleLabel.font = .ds.title2Bold
            stepsTitleLabel.textColor = .black900
        }
    }

    @IBOutlet private var scrollView: UIScrollView!

    // MARK: - Private properties

    private var shareTapSubject = PassthroughRelay<Void>()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

// MARK: - SimpleResultsViewProtocol

extension SimpleResultsViewController: SimpleResultsViewProtocol {
    var backTapRelay: AnyVoidRelay {
        backButton.tapPublisher
    }

    var shareTapRelay: AnyVoidRelay {
        shareTapSubject.eraseToAnyPublisher()
    }

    func apply(_ viewState: ViewState) {
        titleLabel.text = viewState.title
        headerTitleLabel.text = viewState.headerTitle
        stepsTitleLabel.text = viewState.stepsTitle

        fillHeaderContainer(with: viewState.headerViewState) as Void
        fillStepsContainer(with: viewState.solutionStepsViewState)
            .replaceError(with: ())
            .sink()
            .store(in: &bag)
    }

    func setLoading(_ loading: Bool) {
        self.isLoading = loading
    }

    private func fillHeaderContainer(
        with viewStates: [SolutionHeaderView.ViewState]
    ) {
        guard headerStackView.arrangedSubviews.isEmpty else { return }
        let views = viewStates.map { viewState in
            let headerView = SolutionHeaderView().configured(with: viewState)
            if let action = viewState.action {
                switch action {
                case .share:
                    headerView.actionButtonTapRelay
                        .redirect(
                            to: shareTapSubject,
                            storeIn: &bag
                        )
                }
            }
            return headerView
        }
        headerStackView.addArrangedSubviews(views)
    }

    private func fillHeaderContainer(
        with viewStates: [SolutionHeaderView.ViewState]
    ) -> AnyVoidRelay {
        Future { [self] promise in
            headerStackView.removeAllArrangedSubviews()
            let views = viewStates.map { viewState in
                let headerView = SolutionHeaderView().configured(with: viewState)
                if let action = viewState.action {
                    switch action {
                    case .share:
                        headerView.actionButtonTapRelay
                            .redirect(
                                to: shareTapSubject,
                                storeIn: &bag
                            )
                    }
                }
                return headerView
            }
            headerStackView.addArrangedSubviewsWithAnimation(views) {
                promise(.success())
            }
        }
        .eraseToAnyPublisher()
    }

    private func fillStepsContainer(
        with viewStates: [SolutionStepView.ViewState]?
    ) -> AnyPublisher<Void, ApplicationError> {
        Future { [self] promise in
            stepsStackView.removeAllArrangedSubviews()
            solutionsStepsContainer.applyIfPresent(viewStates) { viewStates in
                let stepViews: [SolutionStepView] = viewStates.map { viewState in
                    SolutionStepView().configured(with: viewState)
                }
                stepsStackView.addArrangedSubviewsWithAnimation(stepViews) {
                    promise(.success())
                }
            } else: {
                promise(.success())
            }
        }
        .eraseToAnyPublisher()
    }
}
