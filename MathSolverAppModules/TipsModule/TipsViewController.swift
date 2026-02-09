class TipsViewController: BaseHostingViewController<TipsView> {

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
