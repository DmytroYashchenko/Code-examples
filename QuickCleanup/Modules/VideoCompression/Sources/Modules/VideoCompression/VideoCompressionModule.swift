import AVFoundation
import SwiftUIExt

struct VideoCompressionInput {

    let localIdentifier: String
    let sizeBytes: Int64
    let player: AVPlayer
}

struct VideoCompressionModule: Module {

    let router: HomeRouter
    let input: VideoCompressionInput

    func build() -> UIViewController {
        let viewModel = VideoCompressionViewModel(
            router: router,
            input: input
        )
        let view = VideoCompressionView(viewModel: viewModel)
        return HostingController(rootView: view)
    }
}
