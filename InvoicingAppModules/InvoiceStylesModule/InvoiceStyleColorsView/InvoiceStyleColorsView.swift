import SwiftUI

struct InvoiceStyleColorsView: View {

    @Environment(\.colorScheme) private var colorScheme

    private var borderColor: UIColor {
        theme.tableBorderColor
    }

    let theme: InvoiceColorizer
    let isSelected: Bool

    var body: some View {
        VStack(spacing: .zero) {
            Color(theme.textColor)
            Color(theme.tableBorderColor)
            Color(theme.headersFillColor)
        }
        .rotationEffect(Angle(degrees: 45))
        .clipShape(.circle)
        .padding(isSelected ? 5 : 0)
        .overlay {
            Circle()
                .stroke(
                    Color(borderColor),
                    lineWidth: 3
                )
                .opacity(isSelected ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
