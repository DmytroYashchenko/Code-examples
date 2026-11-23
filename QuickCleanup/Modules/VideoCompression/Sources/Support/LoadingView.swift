import SwiftUI

struct LoadingView: View {

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
        }
    }
}
