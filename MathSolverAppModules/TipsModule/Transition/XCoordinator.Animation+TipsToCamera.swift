import UIKit
import XCoordinator

extension XCoordinator.Animation {
    static let tipsToCamera = Animation(
        presentation: InteractiveTransitionAnimation.tipsToCamera,
        dismissal: nil
    )
}

extension XCoordinator.InteractiveTransitionAnimation {

    private enum Constant {
        static let animationDuration: TimeInterval = 1
    }

    fileprivate static let tipsToCamera = InteractiveTransitionAnimation(
        duration: Constant.animationDuration
    ) { context in
        let containerView = context.containerView
        guard
            let toViewController = context.viewController(forKey: .to),
            let cameraViewController = toViewController as? CameraViewController,
            let cameraView = cameraViewController.view
        else {
            return context.completeTransition(false)
        }

        let circleSize: CGFloat = 10
        let circleView = UIView(
            frame: .init(
                x: .zero,
                y: .zero,
                width: circleSize,
                height: circleSize
            )
        )
        circleView.center = containerView.center
        circleView.layer.cornerRadius = circleSize / 2
        circleView.layer.cornerCurve = .continuous
        circleView.backgroundColor = .primary500
        containerView.addSubview(circleView)

        UIView.animate(
            withDuration: Constant.animationDuration / 2,
            delay: 0,
            options: .curveEaseIn
        ) {
            circleView.transform = .init(scaleX: 120, y: 120)
        } completion: { _ in
            containerView.insertSubview(cameraView, belowSubview: circleView)
            cameraView.frame = containerView.bounds
            cameraView.layoutIfNeeded()
            circleView.center = cameraViewController.tipsView.absoluteCenter

            UIView.animate(
                withDuration: Constant.animationDuration / 2,
                delay: 0,
                options: .curveEaseOut,
                animations: {
                    circleView.transform = .identity
                },
                completion: { _ in
                    circleView.isHidden = true
                    context.completeTransition(!context.transitionWasCancelled)
                }
            )
        }
    }
}

private extension UIView {

    var absoluteCenter: CGPoint {
        if let superview = superview {
            superview.convert(center, to: nil)
        } else {
            center
        }
    }
}
