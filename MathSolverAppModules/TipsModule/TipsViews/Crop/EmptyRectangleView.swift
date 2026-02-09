import SwiftUI

struct EmptyRectangleView: View {

    let size: CGSize
    let padding: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .frame(
                width: size.width + padding,
                height: size.height + padding
            )
            .blendMode(.destinationOut)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black.opacity(0.4))
            .compositingGroup()
            .animation(.default, value: cornerRadius)
    }
}
